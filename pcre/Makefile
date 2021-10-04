include ../Makefile.inc
#UPSTREAM=ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.40.tar.gz
UPSTREAM=https://ftp.pcre.org/pub/pcre/pcre-8.40.tar.gz
TARBALL=$(notdir $(UPSTREAM))

all: bin/pcre

bin/pcre: build/libpcre.la

build/libpcre.la: build/Makefile
	$(MAKE) -C build
	$(MAKE) install -C build

PCRE_CONF_OPTS += \
	--prefix=$(RUMPRUN_PKGS_DIR) \
	--disable-cpp \
	--disable-shared

# after macos 10.14(?), -O2 flag make unresolved symbol '__DefaultRuneLocale',
# ___memmove_chk, etc, thus disable it by -O1 (-O0 doesn't work).
ifeq ($(shell uname),Darwin)
PCRE_CONF_OPTS += "CFLAGS=-O1 -fno-stack-check"
endif

build/Makefile: build/configure
	(cd build; \
	./configure --host=$(RUMPRUN_TOOLCHAIN_TUPLE) $(PCRE_CONF_OPTS);)

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

