SHELL := /bin/bash
INSTALLED := .installed
BIND := /etc/bind
APPNAME := $(notdir $(CURDIR))
NAMED_LOCAL := $(BIND)/named.conf.local
NAMED_OPTIONS := $(BIND)/named.conf.options
# serial number for DNS zone; may need to support other suffixes than 00
# someday, but this should work for now
SERIAL := $(shell date +%Y%m%d)00
RESOLVE := /etc/systemd/resolved.conf.d
RESOLV_CONF := /etc/resolv.conf
NS_LOCALHOST := nameserver 127.0.0.1
IPFS_DIR := $(HOME)/.ipfs
IPFS := /usr/bin/ipfs
SYSTEMD_USER := $(HOME)/.config/systemd/user
IPFS_SERVICE := ipfs.service
NM := NetworkManager
NM_CONF := /etc/$(NM)/$(NM).conf
REPOSITORY := $(HOME)/.$(APPNAME)
BINDIR ?= $(HOME)/.local/bin
include $(REPOSITORY)/config.env
PUBLIC_SHORTNAME ?= $(shell echo $${PUBLIC_NAMESERVER%%.*})
CURATION_CONF := $(PRIVATE_DOMAIN).conf
INCLUDE := include "$(BIND)/$(CURATION_CONF)";
EXPORT := PUBLIC_TLD PUBLIC_DOMAIN PUBLIC_SHORTNAME PUBLIC_NAMESERVER \
 PRIVATE_DOMAIN SERIAL
SHELL_FORMAT := $(addprefix $$, $(EXPORT))

ifeq ($(SHOWENV),)
export $(EXPORT)
else
export
endif

install: check_env $(INSTALLED)/$(CURATION_CONF) \
 $(RESOLV_CONF) $(INSTALLED)/ipfs \
 $(NAMED_OPTIONS) $(NM_CONF) $(BIND)/dot.key test
check_env: $(REPOSITORY)/config.env
	if [ -z "$(PUBLIC_TLD)" ] || [ "$(PUBLIC_TLD)" = "unset" ]; then \
	 echo You need to edit $< with valid values >&2; \
	 false; \
	else \
	 echo Config looks valid >&2; \
	fi
$(REPOSITORY)/config.env: config.env | $(REPOSITORY)
	cp $< $@
%: template.%
	envsubst '$(SHELL_FORMAT)' < $< > $@
$(INSTALLED)/ipfs: $(IPFS) $(SYSTEMD_USER)/$(IPFS_SERVICE) $(IPFS_DIR)
	touch $@
$(IPFS):
	$(MAKE) -f kubo.mk $(IPFS) clean-kubo
$(IPFS_DIR):
	ipfs init --profile=server
$(SYSTEMD_USER)/$(IPFS_SERVICE): $(IPFS_SERVICE) | $(SYSTEMD_USER)
	cp -i $< $@
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
$(BIND)/%.conf: template.curation_zone.conf $(BIND)/local/%.db
	@echo Rebuilding $@
	envsubst '$(SHELL_FORMAT)' < $< | sudo tee $@
	sudo systemctl restart named
$(BIND)/local/%.db: template.curation_zone.db | $(BIND)/local
	@echo Rebuilding $@
	envsubst '$(SHELL_FORMAT)' < $< | sudo tee $@
$(INSTALLED)/%.conf: $(BIND)/%.conf $(BIND)/local/%.db $(BIND)/dnslink.key
	if ! grep -q '^$(INCLUDE)$$' $(NAMED_LOCAL); then \
		echo '$(INCLUDE)' | sudo tee -a $(NAMED_LOCAL); \
	fi
	sudo systemctl restart named
	touch $@
restart status:
	sudo systemctl $@ named
# configure NetworkManager to leave resolv.conf alone
$(NM_CONF):
	if grep -qF 'dns=none' $@; then \
	 echo $(NM) already configured to leave $(RESOLV_CONF) alone >&2; \
	else \
	 sudo sed -i '/^\[main\]/a dns=none' $@; \
	fi
$(RESOLV_CONF):
	if grep -qF '$(NS_LOCALHOST)' $@; then \
	 echo $@ already set up for local bind9 resolution >&2; \
	else \
	 echo '$(NS_LOCALHOST)' | sudo tee $@; \
	fi
$(NAMED_OPTIONS):
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
$(BIND)/dot.key:
	sudo openssl req -x509 -newkey rsa:4096 -keyout $@ \
  	 -out $(@:.key=.crt) -days 3650 -nodes \
  	 -subj "/CN=$(PUBLIC_NAMESERVER)"
curate: curate.sh
	chmod +x $<
	ln -sf $< $@
test: $(BINDIR)/curate
	$< local testfile.txt this.is.a.test.txt
$(HOME)/%:
	mkdir --parents $@
$(BINDIR)/%: %
	ln -s $(CURDIR)/$< $@
diff:
	git diff
	diff config.env $(REPOSITORY)
env:
ifeq ($(SHOWENV),)
	$(MAKE) SHOWENV=1 $@
else
	$@
endif
.PRECIOUS: $(BIND)/%.conf $(BIND)/local/%.db
.PHONY: restart status
.FORCE:
