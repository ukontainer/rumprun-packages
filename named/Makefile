include ../Makefile.inc
UPSTREAM=https://downloads.isc.org/isc/bind9/9.11.17/bind-9.11.17.tar.gz
TARBALL=$(notdir $(UPSTREAM))

ifeq ($(shell uname),Linux)
ifeq ($(shell arch),x86_64)
# linux/amd64
all: images/named.img
else
# linux/arm64
all: bin/named
endif
else
# darwin
all: bin/named
# XXX: -g option of clang/darwin makes .dSYM generation, but the
# dsymutil command crashes on xcode <= 10.2, thus disable it.
NAMED_CONF_OPTS += CFLAGS=""
endif

NAMED_CONF_OPTS += \
	--disable-option-checking \
	--disable-tcp-fastopen \
	--disable-chroot \
	--disable-linux-caps \
	--disable-rpz-nsip \
	--disable-rpz-nsdname \
	--disable-threads \
	--disable-ipv6 \
	--disable-backtrace \
	--disable-symtable \
	--enable-full-report \
	--disable-static \
	--disable-shared \
	--without-python \
	--without-openssl \
	--without-libjson \
	--without-zlib \
	--without-gssapi \
	--without-libxml2 \
	--with-dlopen=no \
	--prefix=$(RUMPRUN_PKGS_DIR)

dl/$(TARBALL):
	mkdir -p dl
	../scripts/fetch.sh ${UPSTREAM} dl/$(TARBALL)

#
# 1. Extract mysql distribution tarball
#
BUILD_DIR=$(abspath build/bind9)
build/bind9_extract_stamp: dl/$(TARBALL)
	mkdir -p $(BUILD_DIR)
	tar -C $(BUILD_DIR) --strip=1 -xzf $<
	touch $@

#
# 2. Patches:
#
build/bind9_patch_stamp: patches/* build/bind9_extract_stamp
	( cd $(BUILD_DIR) && ../../../scripts/apply-patches.sh ./  ../../patches/*)
	touch $@

#
# 3. configure
#
build/bind9/Makefile: build/bind9_patch_stamp
	(cd $(BUILD_DIR); CC=$(RUMPRUN_CC) LDFLAGS=-static \
	 ./configure --build=$(shell uname -m)-unknown-linux $(NAMED_CONF_OPTS))

#
# 4. build libs
#
#
LIBS := isc isccc isccfg bind9 lwres irs dns
ARCHIVES := $(foreach var, ${LIBS}, $(subst LIB,${var}, build/bind9/lib/LIB/libLIB.a))
$(filter-out %libdns.a, ${ARCHIVES}): build/bind9/lib/dns/libdns.a
${ARCHIVES}: build/bind9/Makefile
	$(MAKE) -C $$(dirname $@)

#
# 5. build named binary
#
build/bind9/bin/named/named: ${ARCHIVES}
	$(MAKE) -C build/bind9/bin/named

bin/named: build/bind9/bin/named/named
	mkdir -p bin/
	cp $< $@

images/named.img: bin/named *.zone named.conf
	mkdir -p images
	mkdir -p mnt
	dd if=/dev/zero of=images/named.img bs=1M count=16
	mkfs.ext4 images/named.img
	sudo umount mnt || :
	sudo mount images/named.img mnt
	sudo chmod 777 mnt
	mkdir -p mnt/etc/named/
	cp named.conf *.zone mnt/etc/named/
	sudo umount mnt

.PHONY: clean
clean: build/bind9
	-$(MAKE) -C build/bind9 clean

.PHONY: distclean
distclean:
	rm -rf build bin dl mnt images

