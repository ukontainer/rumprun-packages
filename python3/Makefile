include ../Makefile.inc

UPSTREAM=https://www.python.org/ftp/python/3.5.2/Python-3.5.2.tar.xz
TARBALL=$(notdir $(UPSTREAM))
ARCH=$(shell $(HOST_CC) -dumpmachine)

ifeq ($(shell uname),Linux)
ifeq ($(shell arch),aarch64)
all: libssl $(RUMPRUN_PKGS_DIR)/lib/libsqlite.a images/python.iso
else
all: libssl $(RUMPRUN_PKGS_DIR)/lib/libsqlite.a images/python.iso images/python.img
endif
else
all: $(RUMPRUN_PKGS_DIR)/lib/libsqlite.a images/python.iso
endif

ifeq ($(shell uname),Darwin)
PYTHON_CONF_OPTS += --with-suffix=.exe
EXESUFFIX = .exe
endif

.NOTPARALLEL: $(RUMPRUN_PKGS_DIR)/lib/libsqlite.a
$(RUMPRUN_PKGS_DIR)/lib/libsqlite.a:
	$(MAKE) -C ../sqlite

build/python$(EXESUFFIX): build/Makefile
	$(MAKE) -C build
	$(MAKE) -C build install

PYTHON_CONF_ENV += \
	LDFLAGS="-static -static-libgcc -L${RUMPRUN_PKGS_DIR}/lib" \
	CPPFLAGS="$(CPPFLAGS) -static -I${RUMPRUN_PKGS_DIR}/include" \
	CFLAGS="$(CFLAGS) -static" \
	CC=$(RUMPRUN_CC) \
	PYTHON_FOR_BUILD=$(shell pwd)/build/hostdist/bin/python3 \
	CONFIG_SITE=config.site

PYTHON_CONF_OPTS += \
	--prefix=$(shell pwd)/build/pythondist \
	--disable-shared \
	--host=$(RUMPRUN_TOOLCHAIN_TUPLE) \
	--build $(ARCH) \
	--enable-ipv6 \
	--without-ensurepip

ifeq ($(shell uname),Linux)
PYTHON_CONF_OPTS += --with-openssl=${RUMPRUN_PKGS_DIR}
endif

dl/$(TARBALL):
	mkdir -p dl
	../scripts/fetch.sh ${UPSTREAM} dl/$(TARBALL)

build/hostpython: | dl/$(TARBALL)
	mkdir -p build
	(cd build && tar -x --strip-components 1 -f ../dl/$(TARBALL))
	(cd build; ./configure --prefix=$(shell pwd)/build/hostdist; make python Parser/pgen && make install)
	mv build/python$(EXESUFFIX) build/hostpython

build/Parser/hostpgen: build/hostpython
	cp build/Parser/pgen build/Parser/hostpgen

build/Programs/host_freeze_importlib: build/Parser/hostpgen
	cp build/Programs/_freeze_importlib build/Programs/host_freeze_importlib

build/configure: build/Programs/host_freeze_importlib
	(cd build; make distclean)

build/stamp_patch: build/configure patches/*
	cp config.site build/
	(cd build && ../../scripts/apply-patches.sh ./ ../patches/*)
	cp -R files/* build/Modules/
	# FIXME: (Darwin)
ifeq ($(shell uname),Darwin)
	sed "s/import ssl/\#import ssl/" examples/main.py > /tmp/a
	mv /tmp/a examples/main.py
	rm -f /tmp/a

	sed "s/_ssl/\#_ssl/" build/Modules/Setup.dist \
	      | sed "s/-DUSE_SSL/\#-DUSE_SSL/" \
	      | sed 's/-L\$$(SSL/\#-L\$$(SSL/' \
	      > /tmp/a
	mv /tmp/a build/Modules/Setup.dist
	rm -f /tmp/a
endif
	touch $@

build/Makefile: build/stamp_patch
	(cd build; $(PYTHON_CONF_ENV) ./configure $(PYTHON_CONF_OPTS))

images/python.iso: build/python$(EXESUFFIX)
	mkdir -p images
	$(RUMPRUN_GENISOIMAGE) -o images/python.iso build/pythondist/lib/python3.5

images/python.img: build/python$(EXESUFFIX)
	mkdir -p images
	mkdir -p mnt
	dd if=/dev/zero of=images/python.img bs=1M count=70
	mkfs.ext4 -F images/python.img
	sudo mount -o loop images/python.img mnt
	sudo mkdir -p mnt/python/lib
	sudo cp -rpf build/pythondist/lib/python3.5 mnt/python/lib/
	sudo cp examples/main.py mnt/
	sudo umount mnt
	rmdir mnt

.PHONY: clean
clean:
	-$(MAKE) -C build clean
	rm -f bin/*
	rm -f images/python.iso
	rm -f images/python.img
	rm -f examples/hw.c examples/hw.bin examples/hw

.PHONY: distclean
distclean: clean
	rm -rf build

include ../Makefile.deps
