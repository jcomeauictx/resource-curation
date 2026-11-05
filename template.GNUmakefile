#!/usr/bin/make -f
PUBLIC_NAMESERVER := myvps.example.com
PUBLIC_SHORTNAME := myvps
MAKEFILE := $(firstword $(notdir $(MAKEFILE_LIST)))
ifneq ($(MAKEFILE),GNUmakefile)
CURATE ?= $(MAKEFILE)
SILENT ?= @
endif
export

default:
	$(MAKE) -f Makefile $(CURATE)  # if CURATE empty, will build default
%:
	@echo makefile name: $(MAKEFILE)
	if [ -e $(MAKEFILE).sh ]; then \
	 $(MAKE) -f Makefile env; \
	 bash $(MAKEFILE).sh; \
	else \
	 $(MAKE) -f Makefile $*; \
	fi
