#!/bin/bash
# build additional packages to be deployed

deploy() {
git clone -q https://github.com/thehajime/runu-base.git
(
       local OS=$1

       cd runu-base
       mkdir -p bin imgs sbin
       # copy binaries
       curl -u $BINTRAY_USER:$BINTRAY_APIKEY https://dl.bintray.com/libos-nuse/runu-rumprun-packages/$OS/nginx -o bin/nginx
       curl -u $BINTRAY_USER:$BINTRAY_APIKEY https://dl.bintray.com/libos-nuse/runu-rumprun-packages/$OS/python -o bin/python
       curl -u $BINTRAY_USER:$BINTRAY_APIKEY https://dl.bintray.com/libos-nuse/runu-rumprun-packages/$OS/netperf -o bin/netperf
       curl -u $BINTRAY_USER:$BINTRAY_APIKEY https://dl.bintray.com/libos-nuse/runu-rumprun-packages/$OS/netserver -o bin/netserver
       # copy rootfs images
       curl -u $BINTRAY_USER:$BINTRAY_APIKEY https://dl.bintray.com/libos-nuse/runu-rumprun-packages/$OS/data.iso -o imgs/data.iso
       curl -u $BINTRAY_USER:$BINTRAY_APIKEY https://dl.bintray.com/libos-nuse/runu-rumprun-packages/linux/python.img -o imgs/python.img
       curl -u $BINTRAY_USER:$BINTRAY_APIKEY https://dl.bintray.com/libos-nuse/runu-rumprun-packages/$OS/python.iso -o imgs/python.iso

       curl -u $BINTRAY_USER:$BINTRAY_APIKEY https://dl.bintray.com/libos-nuse/x86_64-rumprun-linux/$OS/frankenlibc.tar.gz -o /tmp/frankenlibc.tar.gz
       tar xfz /tmp/frankenlibc.tar.gz -C /tmp/
       cp -f /tmp/rump/bin/hello bin
       cp -f /tmp/rump/bin/ping bin
       cp -f /tmp/rump/bin/rexec sbin
       chmod +x sbin/* bin/*

       ls -lR .
       # push an image to docker hub
       echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
       docker build -t $DOCKER_USERNAME/runu-base:$OS .
       docker images
       docker push $DOCKER_USERNAME/runu-base:$OS
)
}

deploy linux
rm -rf runu-base
deploy osx

