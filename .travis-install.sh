#!/bin/bash
# Install additional build dependencies for packages
# mysql: makefs
if [ $TRAVIS_OS_NAME == "linux" ] ; then
sudo apt-get update
sudo apt-get install makefs genisoimage jq
if [ $TRAVIS_ARCH == "aarch64" ] ; then
    sudo dpkg --add-architecture armhf
    sudo apt-get update
    sudo apt-get install libc6:armhf crossbuild-essential-armhf
fi
fi

if [ $TRAVIS_OS_NAME == "osx" ] ; then
HOMEBREW_NO_AUTO_UPDATE=1 brew install e2fsprogs ccache gnu-sed jq
ln -sf /usr/local/opt/e2fsprogs/sbin/mkfs.ext2 /usr/local/bin/
ln -sf /usr/local/bin/gsed /usr/local/bin/sed
fi

# XXX: take too long..
#sudo apt-get install openjdk-7-jdk


if [ $TRAVIS_ARCH == "amd64" ] ; then
    export RUMPRUN_TOOLCHAIN_TUPLE=x86_64-rumprun-linux
    export ARCH=amd64
elif [ $TRAVIS_ARCH == "aarch64" ] ; then
    export RUMPRUN_TOOLCHAIN_TUPLE=${RUMPRUN_TOOLCHAIN_TUPLE:-aarch64-rumprun-${RUMPKERNEL}}
    export ARCH=${ARCH:-arm64}
fi


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
URL="https://github.com/ukontainer/frankenlibc/releases/download/dev/frankenlibc-$ARCH-$TRAVIS_OS_NAME.tar.gz"
TINY_URL="https://github.com/ukontainer/frankenlibc/releases/download/dev/frankenlibc-tiny-$ARCH-$TRAVIS_OS_NAME.tar.gz"

curl -L $URL -o /tmp/frankenlibc.tar.gz
sudo mkdir -p /opt/rump && sudo chown $USER /opt/rump
tar xfz /tmp/frankenlibc.tar.gz -C /

curl -L $TINY_URL -o /tmp/frankenlibc-tiny.tar.gz
sudo mkdir -p /opt/rump-tiny && sudo chown $USER /opt/rump-tiny
tar xfz /tmp/frankenlibc-tiny.tar.gz -C /
