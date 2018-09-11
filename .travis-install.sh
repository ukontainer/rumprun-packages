#!/bin/bash
# Install additional build dependencies for packages
# mysql: makefs
if [ $TRAVIS_OS_NAME == "linux" ] ; then
sudo apt-get update
sudo apt-get install makefs genisoimage
fi
# XXX: take too long..
#sudo apt-get install openjdk-7-jdk

# Build and install rumprun toolchain from source
RUMPKERNEL=${RUMPKERNEL:-netbsd}
RUMPRUN_PLATFORM=${RUMPRUN_PLATFORM:-hw}
RUMPRUN_TOOLCHAIN_TUPLE=${RUMPRUN_TOOLCHAIN_TUPLE:-x86_64-rumprun-${RUMPKERNEL}}

#git clone -q https://github.com/libos-nuse/rumprun /tmp/rumprun
#(
#	cd /tmp/rumprun
#	git submodule update --init
#	./build-rr.sh -d /usr/local -r ${RUMPKERNEL} -o ./obj -qq ${RUMPRUN_PLATFORM} build
#	sudo ./build-rr.sh -d /usr/local -o ./obj ${RUMPRUN_PLATFORM} install
#)

echo RUMPRUN_TOOLCHAIN_TUPLE=${RUMPRUN_TOOLCHAIN_TUPLE} >config.mk

# copy pre-build rumprun toolchain
mkdir -p /tmp/frankenlibc
curl -u $BINTRAY_USER:$BINTRAY_APIKEY https://dl.bintray.com/libos-nuse/x86_64-rumprun-linux/$TRAVIS_OS_NAME/frankenlibc.tar.gz -o /tmp/frankenlibc.tar.gz
tar xfz /tmp/frankenlibc.tar.gz -C /tmp/frankenlibc/

if [ $TRAVIS_OS_NAME == "osx" ] ; then
	# *-cc is recognized as *-CC in case-insensitive filesystem
	cd /tmp/frankenlibc/rump/bin && ln -fs x86_64-rumprun-linux-clang x86_64-rumprun-linux-gcc && rm -f x86_64-rumprun-linux-cc
fi
