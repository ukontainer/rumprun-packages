#!/bin/bash
# build additional packages to be deployed

VERSION=0.1

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
       curl -u $BINTRAY_USER:$BINTRAY_APIKEY https://dl.bintray.com/libos-nuse/runu-rumprun-packages/$OS/sqlite-bench -o bin/sqlite-bench

       # copy rootfs images
       curl -u $BINTRAY_USER:$BINTRAY_APIKEY https://dl.bintray.com/libos-nuse/runu-rumprun-packages/$OS/data.iso -o imgs/data.iso
       curl -u $BINTRAY_USER:$BINTRAY_APIKEY https://dl.bintray.com/libos-nuse/runu-rumprun-packages/linux/python.img -o imgs/python.img
       curl -u $BINTRAY_USER:$BINTRAY_APIKEY https://dl.bintray.com/libos-nuse/runu-rumprun-packages/$OS/python.iso -o imgs/python.iso

       curl -L https://dl.bintray.com/libos-nuse/x86_64-rumprun-linux/$OS/frankenlibc.tar.gz \
	    -o /tmp/frankenlibc.tar.gz
       tar xfz /tmp/frankenlibc.tar.gz -C /tmp/
       cp -f /tmp/opt/rump/bin/hello bin
       cp -f /tmp/opt/rump/bin/ping bin
       cp -f /tmp/opt/rump/bin/ping6 bin
       cp -f /tmp/opt/rump/bin/rexec sbin
       chmod +x sbin/* bin/*

       ls -lR .
       # push an image to docker hub
       echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
       docker build -t $DOCKER_USERNAME/runu-base:$VERSION-$OS .
       docker images
       docker push $DOCKER_USERNAME/runu-base:$VERSION-$OS

       cd ..
       rm -rf runu-base
)
}

deploy_nodejs() {
git clone -q https://github.com/thehajime/runu-base.git
(
       local OS=$1

       cd runu-base
       mkdir -p bin imgs sbin

       curl -u $BINTRAY_USER:$BINTRAY_APIKEY \
	    https://dl.bintray.com/libos-nuse/runu-rumprun-packages/$OS/node -o bin/node

       chmod +x bin/*

       ls -lR .
       # push an image to docker hub
       echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
       docker build -t $DOCKER_USERNAME/runu-node:$VERSION-$OS .
       docker images
       docker push $DOCKER_USERNAME/runu-node:$VERSION-$OS

       cd ..
       rm -rf runu-base
)
}

create_multi_arch_image() {
       local name=$1

       /tmp/docker/docker -D manifest create $DOCKER_USERNAME/$name:$VERSION \
			  $DOCKER_USERNAME/$name:$VERSION-osx \
			  $DOCKER_USERNAME/$name:$VERSION-linux

       /tmp/docker/docker -D manifest annotate $DOCKER_USERNAME/$name:$VERSION \
			  $DOCKER_USERNAME/$name:$VERSION-osx \
			  --os darwin --arch amd64
       /tmp/docker/docker -D manifest annotate $DOCKER_USERNAME/$name:$VERSION \
			  $DOCKER_USERNAME/$name:$VERSION-linux \
			  --os linux --arch amd64
       /tmp/docker/docker -D manifest push $DOCKER_USERNAME/$name:$VERSION

       /tmp/docker/docker -D manifest inspect $DOCKER_USERNAME/$name:0.1
       /tmp/docker/docker -D manifest inspect -v $DOCKER_USERNAME/$name:0.1
}


# obtain newer docker command
curl -fsSL  curl -O https://download.docker.com/linux/static/stable/x86_64/docker-18.06.1-ce.tgz \
     -o /tmp/docker-18.06.1-ce.tgz
tar xfz /tmp/docker-18.06.1-ce.tgz -C /tmp/
chmod +x /tmp/docker/docker

# create images
deploy linux
deploy osx
deploy_nodejs linux
deploy_nodejs osx

# enable experimental features
cat  ~/.docker/config.json | jq '. += {"experimental": "enabled"}' > /tmp/1
mv /tmp/1 ~/.docker/config.json

# create multi-arch image
create_multi_arch_image runu-base
create_multi_arch_image runu-node
