KUBO_VERSION := 0.41.0
KUBO_ARCH := amd64
KUBO_WEBSITE := https://dist.ipfs.tech/kubo/v$(KUBO_VERSION)
KUBO_URL := $(KUBO_WEBSITE)/kubo_v$(KUBO_VERSION)_linux-$(KUBO_ARCH).tar.gz
KUBO_DEB := kubo_$(KUBO_VERSION)_$(KUBO_ARCH).deb

/usr/bin/ipfs: $(KUBO_DEB)
	sudo dpkg -i $

$(KUBO_DEB): kubo/ipfs
	mkdir -p kubo-deb/DEBIAN kubo-deb/usr/bin kubo-deb/usr/share/doc/kubo
	cp kubo/ipfs kubo-deb/usr/bin/
	printf 'Package: kubo\nVersion: $(KUBO_VERSION)\nArchitecture: $(KUBO_ARCH)\nMaintainer: local\nDescription: IPFS Kubo\n' \
		> kubo-deb/DEBIAN/control
	dpkg-deb --build kubo-deb $@
	rm -rf kubo-deb

kubo/ipfs: kubo_v$(KUBO_VERSION)_linux-$(KUBO_ARCH).tar.gz
	tar -xzf $

kubo_v$(KUBO_VERSION)_linux-$(KUBO_ARCH).tar.gz:
	wget $(KUBO_URL)

.PHONY: clean-kubo
clean-kubo:
	rm -rf kubo kubo-deb kubo_v*.tar.gz $(KUBO_DEB)
