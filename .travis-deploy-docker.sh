#!/bin/bash
# build additional packages to be deployed

VERSION=0.5

prepare_pkg_image() {
mkdir -p rootfs
(
       local OS=$1
       local ARCH=$2
       local NAME=$3
       local SLIM=$4

       cd rootfs
       local TARGET_PLATFORM="linux/amd64"

       # create arch dir
       if [ "$OS" == "linux" ] ; then
	   if [ "$ARCH" == "amd64" ] ; then
	       TARGET_PLATFORM="linux/amd64"
	   elif [ "$ARCH" == "arm" ] ; then
	       TARGET_PLATFORM="linux/arm/v7"
	   elif [ "$ARCH" == "arm64" ] ; then
	       TARGET_PLATFORM="linux/arm64"
	   fi
       elif [ "$OS" == "osx" ] ; then
	   TARGET_PLATFORM="darwin/amd64"
       fi

       mkdir -p imgs $TARGET_PLATFORM/bin $TARGET_PLATFORM/sbin

       if [ "$NAME" != "base" ] ; then
	   curl -L -u $BINTRAY_USER:$BINTRAY_APIKEY \
		https://dl.bintray.com/ukontainer/ukontainer/$OS/$ARCH/$NAME$SLIM -o $TARGET_PLATFORM/bin/$NAME
       fi

       if [ "$NAME" = "python" ] ; then
	   curl -L -u $BINTRAY_USER:$BINTRAY_APIKEY \
		https://dl.bintray.com/ukontainer/ukontainer/$OS/$ARCH/python.iso -o /tmp/python.iso

	   mkdir -p $TARGET_PLATFORM/usr/lib/
	   7z x -o$TARGET_PLATFORM/usr/lib /tmp/python.iso
	   find ./$TARGET_PLATFORM/usr/lib -name __pycache__ | xargs rm -rf
       elif [ "$NAME" = "nginx" ] ; then
	   curl -L -u $BINTRAY_USER:$BINTRAY_APIKEY \
		https://dl.bintray.com/ukontainer/ukontainer/$OS/$ARCH/data.iso -o imgs/data.iso
       elif [ "$NAME" = "netperf" ] ; then
	   curl -L -u $BINTRAY_USER:$BINTRAY_APIKEY \
		https://dl.bintray.com/ukontainer/ukontainer/$OS/$ARCH/netserver$SLIM -o $TARGET_PLATFORM/bin/netserver
       elif [ "$NAME" = "named" ] ; then
	   mkdir -p ./etc/bind/
	   cp $TRAVIS_BUILD_DIR/named/named.conf ./etc/bind/
	   cp $TRAVIS_BUILD_DIR/named/*.zone ./etc/bind/
       elif [ "$NAME" = "base" ] ; then
	   # copy binaries
	   curl -L -u $BINTRAY_USER:$BINTRAY_APIKEY \
		https://dl.bintray.com/ukontainer/ukontainer/$OS/$ARCH/nginx -o $TARGET_PLATFORM/bin/nginx
	   curl -L -u $BINTRAY_USER:$BINTRAY_APIKEY \
		https://dl.bintray.com/ukontainer/ukontainer/$OS/$ARCH/python -o $TARGET_PLATFORM/bin/python
	   curl -L -u $BINTRAY_USER:$BINTRAY_APIKEY \
		https://dl.bintray.com/ukontainer/ukontainer/$OS/$ARCH/netperf -o $TARGET_PLATFORM/bin/netperf
	   curl -L -u $BINTRAY_USER:$BINTRAY_APIKEY \
		https://dl.bintray.com/ukontainer/ukontainer/$OS/$ARCH/netserver -o $TARGET_PLATFORM/bin/netserver
	   curl -L -u $BINTRAY_USER:$BINTRAY_APIKEY \
		https://dl.bintray.com/ukontainer/ukontainer/$OS/$ARCH/named -o $TARGET_PLATFORM/bin/named
	   curl -L -u $BINTRAY_USER:$BINTRAY_APIKEY \
		https://dl.bintray.com/ukontainer/ukontainer/$OS/$ARCH/sqlite-bench -o $TARGET_PLATFORM/bin/sqlite-bench

	   # copy rootfs images
	   curl -L -u $BINTRAY_USER:$BINTRAY_APIKEY \
		https://dl.bintray.com/ukontainer/ukontainer/$OS/$ARCH/data.iso -o imgs/data.iso
	   curl -L -u $BINTRAY_USER:$BINTRAY_APIKEY \
		https://dl.bintray.com/ukontainer/ukontainer/linux/amd64/python.img -o imgs/python.img
	   curl -L -u $BINTRAY_USER:$BINTRAY_APIKEY \
		https://dl.bintray.com/ukontainer/ukontainer/$OS/$ARCH/python.iso -o imgs/python.iso
	   curl -L -u $BINTRAY_USER:$BINTRAY_APIKEY \
		https://dl.bintray.com/ukontainer/ukontainer/linux/amd64/named.img -o imgs/named.img

	   curl -L https://dl.bintray.com/ukontainer/ukontainer/$OS/$ARCH/frankenlibc.tar.gz \
		-o /tmp/frankenlibc.tar.gz
	   tar xfz /tmp/frankenlibc.tar.gz -C /tmp/
	   cp -f /tmp/opt/rump/bin/hello $TARGET_PLATFORM/bin
	   cp -f /tmp/opt/rump/bin/ping $TARGET_PLATFORM/bin
	   cp -f /tmp/opt/rump/bin/ping6 $TARGET_PLATFORM/bin
	   cp -f /tmp/opt/rump/bin/rexec $TARGET_PLATFORM/sbin
	   chmod +x $TARGET_PLATFORM/sbin/* $TARGET_PLATFORM/bin/*
       fi

       chmod +x $TARGET_PLATFORM/bin/*

       #ls -lR .
       cd ..
)
}

bootstrap_buildx() {
    travis_fold start "buildx.prep"
    docker version
    docker buildx create --name mybuild
    docker buildx use mybuild
    docker buildx inspect --bootstrap
    docker buildx ls
    travis_fold end "buildx.prep"
}

create_multi_arch_image() {
       local NAME=$1
       local SLIM=$2

       cd rootfs

       cp $TRAVIS_BUILD_DIR/utils/* ./

       if [ "$NAME" = "python" ] ; then
	   cp $TRAVIS_BUILD_DIR/python3/Dockerfile ./
	   cp $TRAVIS_BUILD_DIR/python3/.dockerignore ./
       elif [ "$NAME" = "named" ] ; then
	   cp $TRAVIS_BUILD_DIR/named/Dockerfile ./
       fi

       # push an image to docker hub
       echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
       docker buildx build --platform linux/arm/v7,linux/arm64/v8,linux/amd64,darwin/amd64 \
	      --push --progress=plain -t ukontainer/runu-$NAME:$VERSION$SLIM .

       cd ..
       rm -rf rootfs
}


# main body
bootstrap_buildx

# create images
OS_ARCH_MTX=("linux amd64" "linux arm" "linux arm64" "osx amd64")
PKGS="base node python netperf nginx sqlite-bench named"


for pkg in $PKGS
do

    travis_fold start "image.$pkg"
    travis_time_start
    echo "===== creating $pkg image ====="
    for i in "${OS_ARCH_MTX[@]}"
    do
	os_arch=(${i[@]})
	os=${os_arch[0]}
	arch=${os_arch[1]}

	# 2x: deploy slimmed image with a few binaries
	prepare_pkg_image ${os_arch[@]} $pkg
    done
    create_multi_arch_image $pkg
    travis_time_finish
    travis_fold end "image.$pkg"

    if [ "$pkg" = "base" ] ; then
	continue
    fi

    travis_fold start "image.$pkg-slim"
    travis_time_start
    echo "===== creating $pkg-slim image ====="
    for i in "${OS_ARCH_MTX[@]}"
    do
	os_arch=(${i[@]})
	os=${os_arch[0]}
	arch=${os_arch[1]}

	# 2x: deploy slimmed image with a few binaries
	prepare_pkg_image ${os_arch[@]} $pkg "-slim"
    done
    create_multi_arch_image $pkg "-slim"
    travis_time_finish
    travis_fold end "image.$pkg-slim"

done
