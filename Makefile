SHELL := /bin/bash
INSTALLED := .installed

$(INSTALLED)/nsupdate: $(INSTALLED)
	sudo apt install bind9-dnsutils
$(INSTALLED):
	mkdir --parents $@
