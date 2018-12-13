include ../Makefile.inc
UPSTREAM=https://github.com/ukontainer/sqlite-bench.git

CC=$(RUMPRUN_CC)
export CC

#All - start here
all: bin/sqlite-bench

SQLITE_BENCH_CONF_OPTS +=

# sqlite-bench
bin/sqlite-bench: build/sqlite-bench
	mkdir -p bin/
	cp -f $^ $@

build/sqlite-bench: build/Makefile
	$(MAKE) -C build/

build/Makefile:
	mkdir -p build
	(cd build && git clone $(UPSTREAM) .)

.PHONY: clean
clean:
	-$(MAKE) -C build clean
	-rm -f bin/sqlite-bench

.PHONY: distclean
distclean: clean
	rm -rf build
	rm -rf .deps

