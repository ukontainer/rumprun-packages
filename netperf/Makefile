include ../Makefile.inc
UPSTREAM=https://github.com/libos-nuse/netperf2.git

CC=$(RUMPRUN_CC)
export CC

#All - start here
all: bin/netperf

NETPERF_CONF_OPTS +=

# netperf
bin/netperf: build/src/netperf
	mkdir -p bin/
	cp -f $^ $@
	cp -f build/src/netserver bin/netserver

build/src/netperf: build/Makefile
	$(MAKE) -C build/

build/Makefile: build/configure build/stamp_patch
	(cd build/ && \
		./configure --host=$(RUMPRUN_TOOLCHAIN_TUPLE) $(NETPERF_CONF_OPTS);)

build/configure:
	mkdir -p build
	(cd build && git clone $(UPSTREAM) . && sh autogen.sh)

build/stamp_patch: build/configure patches/*
	../scripts/apply-patches.sh build/ patches/*
	touch $@

.PHONY: clean
clean:
	-$(MAKE) -C build clean

.PHONY: distclean
distclean: clean
	rm -rf build
	rm -rf .deps

