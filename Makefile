SHELL := /bin/bash
INSTALLED := .installed
BIND := /etc/bind
CURATION_DOMAIN := resources.internal

$(INSTALLED)/nsupdate: | $(INSTALLED)
	sudo apt install bind9-dnsutils
	touch $@
$(INSTALLED):
	mkdir --parents $@
$(BIND): | $(INSTALLED)/bind9
$(INSTALLED)/bind9: | $(INSTALLED)
	sudo apt install bind9 bind9-dnsutils
	touch $@
$(BIND)/dnslink.key: | $(BIND)
	tsig-keygen $(@F) | sudo tee $@
