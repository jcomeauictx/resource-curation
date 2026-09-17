SHELL := /bin/bash
INSTALLED := .installed

$(INSTALLED)/nsupdate: $(INSTALLED)
	sudo apt install bind9-dnsutils
	touch $@
$(INSTALLED):
	mkdir --parents $@
