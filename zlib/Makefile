include ../Makefile.inc
UPSTREAM=https://www.zlib.net/zlib-1.2.11.tar.gz
TARBALL=$(notdir $(UPSTREAM))

all: build/libz.a

build/libz.a: build/Makefile
	$(MAKE) -C build
	$(MAKE) install -C build

ZLIB_CONF_OPTS += \
	--prefix=$(RUMPRUN_PKGS_DIR) \
	--static

build/Makefile: build/configure
	(cd build; \
	CC=$(RUMPRUN_CC) ./configure $(ZLIB_CONF_OPTS);)

dl/$(TARBALL):
	mkdir -p dl
	../scripts/fetch.sh ${UPSTREAM} dl/$(TARBALL)

build/configure: | dl/$(TARBALL)
	mkdir -p build
	(cd build && tar -zx --strip-components 1 -f ../dl/$(TARBALL))

.PHONY: clean
clean:
	-$(MAKE) -C build clean

.PHONY: distclean
distclean: clean
	rm -rf build
	rm -rf .deps

