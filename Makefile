SHELL := /bin/bash
INSTALLED := .installed
BIND := /etc/bind
NAMED_LOCAL := $(BIND)/named.conf.local
NAMED_OPTIONS := $(BIND)/named.conf.options
CURATION_DOMAIN := resources.internal
CURATION_CONF := $(BIND)/$(CURATION_DOMAIN).conf
INCLUDE := include "$(CURATION_CONF)";
# serial number for DNS zone; may need to support other suffixes than 00
# someday, but this should work for now
SERIAL := $(shell date +%Y%m%d)00
RESOLVE := /etc/systemd/resolved.conf.d
RESOLV_CONF := /etc/resolv.conf
NS_LOCALHOST := nameserver 127.0.0.1
IPFS := /usr/bin/ipfs
SYSTEMD_USER := $(HOME)/.config/systemd/user
IPFS_SERVICE := ipfs.service
NM := NetworkManager
NM_CONF := /etc/$(NM)/$(NM).conf

ifeq ($(SHOWENV),)
export CURATION_DOMAIN SERIAL
else
export
endif

all: $(BIND) $(CURATION_CONF) $(RESOLV_CONF) $(INSTALLED)/ipfs \
 $(NAMED_OPTIONS) $(NM_CONF)
$(INSTALLED)/ipfs: $(IPFS) $(SYSTEMD_USER)/$(IPFS_SERVICE)
	touch $@
$(IPFS):
	$(MAKE) -f kubo.mk $(IPFS) clean-kubo
$(SYSTEMD_USER)/$(IPFS_SERVICE): $(IPFS_SERVICE) .FORCE | $(SYSTEMD_USER)
	cp -i $< $@
	# init fails on 2nd attempt because keys already created, ignore it
	-ipfs init --profile=server
	systemctl --user daemon-reload
	systemctl --user stop $<
	systemctl --user enable --now $<
$(SYSTEMD_USER):
	mkdir --parents $@
$(INSTALLED)/nsupdate: | $(INSTALLED)
	sudo apt install bind9-dnsutils
	touch $@
$(INSTALLED):
	mkdir --parents $@
$(BIND): | $(INSTALLED)/bind9
$(BIND)/local: | $(BIND)
	sudo mkdir --parents $@
$(INSTALLED)/bind9: | $(INSTALLED)
	sudo apt install bind9 bind9-dnsutils
	touch $@
$(BIND)/dnslink.key: | $(BIND)
	tsig-keygen $(@F) | sudo tee $@
$(BIND)/%.conf: curation_zone.conf Makefile
	envsubst < $< | sudo tee $@
$(BIND)/local/%.db: curation_zone.db Makefile | $(BIND)/local
	sudo cp $< $@
$(INSTALLED)/%.conf: $(BIND)/%.conf $(BIND)/local/%.db $(BIND)/dnslink.key
	# the prerequisites ensure %=$(CURATION_DOMAIN)
	if ! grep -q '^$(INCLUDE)$$' $(NAMED_LOCAL); then \
		echo '$(INCLUDE)' | sudo tee -a $(NAMED_LOCAL); \
	fi
	sudo systemctl restart named
	touch $@
restart status:
	sudo systemctl $@ named
# configure NetworkManager to leave resolv.conf alone
$(NM_CONF): Makefile
	if grep -qF 'dns=none' $@; then \
	 echo $(NM) already configured to leave $(RESOLV_CONF) alone >&2; \
	else \
	 sudo sed -i '/^\[main\]/a dns=none' $@; \
	fi
$(RESOLV_CONF): Makefile
	if grep -qF '$(NS_LOCALHOST)' $@; then \
	 echo $@ already set up for local bind9 resolution >&2; \
	else \
	 echo '$(NS_LOCALHOST)' | sudo tee $@; \
	fi
$(NAMED_OPTIONS): Makefile
	recursion=$$(awk '$$1 == "recursion" {print $$2}' $@); \
	if [ "$$recursion" = "yes;" ]; then \
	 echo bind9 is already enabled for recursion >&2; \
	elif [ "$$recursion" = "" ]; then \
	 sudo sed -i '/^};$$/i\\trecursion yes;' $@; \
	 sudo sed -i '/^};$$/i\\tallow-recursion { localhost; };' $@; \
	 echo bind9 now set for recursive lookups >&2; \
	else \
	 echo bind9 recursion already set to $$recursion; false; \
	fi
	sudo systemctl restart named
env:
ifeq ($(SHOWENV),)
	$(MAKE) SHOWENV=1 $@
else
	$@
endif
.PRECIOUS: $(BIND)/% $(BIND)/local/%
.PHONY: restart status
.FORCE:
