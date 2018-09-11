#!/bin/bash

git clone -q https://github.com/libos-nuse/frankenlibc -b lkl-musl-macho /tmp/frankenlibc
(
	cd /tmp/frankenlibc
	git submodule update --init --depth=50
	if [ $TRAVIS_OS_NAME == "osx" ] ; then
	  cp linux/tools/lkl/bin/x86_64-apple-darwin17.4.0-objcopy ~/.local/bin/objcopy
	fi
	./build.sh -q -k linux

	# XXX for python3 osx build
	if [ $TRAVIS_OS_NAME == "osx" ] ; then
	  cd rump/lib && ln -sf libc.a libm.a && cd ../..
        fi 

	mkdir -p deploy 
	mv rump deploy/
	cp rumpobj/tests/ping deploy/rump/bin
	cp rumpobj/tests/hello deploy/rump/bin
	cd deploy/

	# deploy to bintray
	tar cfz /tmp/frankenlibc.tar.gz rump/
	curl -T /tmp/frankenlibc.tar.gz -u$BINTRAY_USER:$BINTRAY_APIKEY  https://api.bintray.com/content/libos-nuse/x86_64-rumprun-linux/frankenlibc/dev/$TRAVIS_OS_NAME/frankenlibc.tar.gz
)
