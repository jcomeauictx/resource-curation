SHELL := /bin/bash
INSTALLED := .installed
BIND := /etc/bind
NAMED_LOCAL := $(BIND)/named.conf.local
CURATION_DOMAIN := resources.internal
INCLUDE := include "/etc/bind/$(CURATION_DOMAIN).conf";

bind_install: $(INSTALLED)/$(CURATION_DOMAIN).conf
$(INSTALLED)/nsupdate: | $(INSTALLED)
	sudo apt install bind9-dnsutils
	touch $@
$(INSTALLED):
	mkdir --parents $@
$(BIND): | $(INSTALLED)/bind9
$(BIND)/local: $(BIND)
	sudo mkdir $@
$(INSTALLED)/bind9: | $(INSTALLED)
	sudo apt install bind9 bind9-dnsutils
	touch $@
$(BIND)/dnslink.key: | $(BIND)
	tsig-keygen $(@F) | sudo tee $@
$(BIND)/%: %
	sudo cp -f $< $@
$(BIND)/local/%: % | $(BIND)/local
	sudo cp -f $< $@
$(INSTALLED)/%.conf: $(BIND)/%.conf $(BIND)/local/%.db
	# the prerequisites ensure %=$(CURATION_DOMAIN)
	if ! grep -q '^$(INCLUDE)$$' $(NAMED_LOCAL); then \
		echo '$(INCLUDE)' | sudo tee -a $(NAMED_LOCAL); \
	fi
	touch $@
.PRECIOUS: $(BIND)/% $(BIND)/local/%
