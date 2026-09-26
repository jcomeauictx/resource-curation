SHELL := /bin/bash
INSTALLED := .installed
BIND := /etc/bind
NAMED_LOCAL := $(BIND)/named.conf.local
CURATION_DOMAIN := resources.internal
INCLUDE := include "/etc/bind/$(CURATION_DOMAIN).conf";
# serial number for DNS zone; may need to support other suffixes than 00
# someday, but this should work for now
SERIAL := $(shell date +%Y%m%d)00
RESOLVE := /etc/systemd/resolved.conf.d

ifeq ($(SHOWENV),)
export CURATION_DOMAIN SERIAL
else
export
endif

all: resolver_install bind_install ipfs_install
bind_install: $(INSTALLED)/$(CURATION_DOMAIN).conf
resolver_install: $(INSTALLED)/internal.conf
ipfs_install: $(INSTALLED)/ipfs
	$(MAKE) -f kubo.mk /usr/bin/ipfs clean-kubo
	ipfs init --profile=server
	touch $@
$(INSTALLED)/internal.conf: $(BIND)/local/$(CURATION_DOMAIN).conf
	touch $@
$(RESOLVE)/%: % Makefile
	sudo cp $< $@
	sudo systemctl restart systemd-resolved
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
env:
ifeq ($(SHOWENV),)
	$(MAKE) SHOWENV=1 $@
else
	$@
endif
.PRECIOUS: $(BIND)/% $(BIND)/local/%
.PHONY: restart status
