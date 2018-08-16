#!/bin/bash
# build additional packages to be deployed

PACKAGES="nginx netperf python3"

for pkg in $PACKAGES
do
	make -j2 -C $pkg
done

# prepare Dockerfile
git clone -q https://github.com/thehajime/runu-base.git
(
       cd runu-base
       mkdir -p bin imgs sbin
       # copy binaries
       cp -f ../nginx/bin/nginx bin
       cp -f ../python3/build/python bin
       cp -f ../netperf/build/src/netperf bin
       cp -f ../netperf/build/src/netserver bin
       cp -f /tmp/frankenlibc/rump/bin/hello bin
       cp -f /tmp/frankenlibc/rump/bin/ping bin
       # copy rootfs images
       cp -f ../nginx/images/data.iso imgs
       cp -f ../python3/images/python.img imgs
       # copy sbin
       cp -f /tmp/frankenlibc/rump/bin/rexec sbin

       # push an image to docker hub
       echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
       docker build -t $DOCKER_USERNAME/runu-base .
       docker images
       docker push $DOCKER_USERNAME/runu-base
)
