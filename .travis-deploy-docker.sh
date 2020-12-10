#!/bin/bash
# build additional packages to be deployed

VERSION=0.4

deploy() {
git clone -q https://github.com/thehajime/runu-base.git
(
       local OS=$1
       local ARCH=$2

       cd runu-base
       mkdir -p bin imgs sbin
       # copy binaries
       curl -L -u $BINTRAY_USER:$BINTRAY_APIKEY \
	    https://dl.bintray.com/ukontainer/ukontainer/$OS/$ARCH/nginx -o bin/nginx
       curl -L -u $BINTRAY_USER:$BINTRAY_APIKEY \
	    https://dl.bintray.com/ukontainer/ukontainer/$OS/$ARCH/python -o bin/python
       curl -L -u $BINTRAY_USER:$BINTRAY_APIKEY \
	    https://dl.bintray.com/ukontainer/ukontainer/$OS/$ARCH/netperf -o bin/netperf
       curl -L -u $BINTRAY_USER:$BINTRAY_APIKEY \
	    https://dl.bintray.com/ukontainer/ukontainer/$OS/$ARCH/netserver -o bin/netserver
       curl -L -u $BINTRAY_USER:$BINTRAY_APIKEY \
	    https://dl.bintray.com/ukontainer/ukontainer/$OS/$ARCH/named -o bin/named
       curl -L -u $BINTRAY_USER:$BINTRAY_APIKEY \
	    https://dl.bintray.com/ukontainer/ukontainer/$OS/$ARCH/sqlite-bench -o bin/sqlite-bench

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
       cp -f /tmp/opt/rump/bin/hello bin
       cp -f /tmp/opt/rump/bin/ping bin
       cp -f /tmp/opt/rump/bin/ping6 bin
       cp -f /tmp/opt/rump/bin/rexec sbin
       chmod +x sbin/* bin/*

       #ls -lR .
       # push an image to docker hub
       echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
       docker build -t ukontainer/runu-base:$VERSION-$OS-$ARCH .
       docker images
       docker push ukontainer/runu-base:$VERSION-$OS-$ARCH

       cd ..
       rm -rf runu-base
)
}

deploy_slim() {
git clone -q https://github.com/thehajime/runu-base.git
(
       local OS=$1
       local ARCH=$2
       local NAME=$3
       local SLIM=$4

       cd runu-base
       mkdir -p bin imgs sbin

       curl -L -u $BINTRAY_USER:$BINTRAY_APIKEY \
	    https://dl.bintray.com/ukontainer/ukontainer/$OS/$ARCH/$NAME$SLIM -o bin/$NAME

       if [ "$NAME" = "python" ] ; then
	   curl -L -u $BINTRAY_USER:$BINTRAY_APIKEY \
		https://dl.bintray.com/ukontainer/ukontainer/$OS/$ARCH/python.iso -o /tmp/python.iso
	   mkdir -p usr/lib/
	   7z x -ousr/lib /tmp/python.iso
	   find ./usr/lib -name __pycache__ | xargs rm -rf
	   cp $TRAVIS_BUILD_DIR/python3/Dockerfile ./
       elif [ "$NAME" = "nginx" ] ; then
	   curl -L -u $BINTRAY_USER:$BINTRAY_APIKEY \
		https://dl.bintray.com/ukontainer/ukontainer/$OS/$ARCH/data.iso -o imgs/data.iso
       elif [ "$NAME" = "netperf" ] ; then
	   curl -L -u $BINTRAY_USER:$BINTRAY_APIKEY \
		https://dl.bintray.com/ukontainer/ukontainer/$OS/$ARCH/netserver$SLIM -o bin/netserver
       elif [ "$NAME" = "named" ] ; then
	   mkdir -p ./etc/bind/
	   cp $TRAVIS_BUILD_DIR/named/Dockerfile ./
	   cp $TRAVIS_BUILD_DIR/named/named.conf ./etc/bind/
	   cp $TRAVIS_BUILD_DIR/named/*.zone ./etc/bind/
       fi

       chmod +x bin/*

       #ls -lR .
       # push an image to docker hub
       echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

       # strip binaries
       if [ -n "$SLIM" ] ; then
           strip bin/* || true
       fi

       docker build -f Dockerfile -t ukontainer/runu-$NAME:$VERSION$SLIM-$OS-$ARCH .
       docker images
       docker push ukontainer/runu-$NAME:$VERSION$SLIM-$OS-$ARCH

       cd ..
       rm -rf runu-base
)
}


create_multi_arch_image() {
       local name=$1
       local SLIM=$2

       /tmp/docker/docker -D manifest create ukontainer/$name:$VERSION$SLIM \
			  ukontainer/$name:$VERSION$SLIM-osx-amd64 \
			  ukontainer/$name:$VERSION$SLIM-linux-amd64 \
			  ukontainer/$name:$VERSION$SLIM-linux-arm64  \
			  ukontainer/$name:$VERSION$SLIM-linux-arm

       /tmp/docker/docker -D manifest annotate ukontainer/$name:$VERSION$SLIM \
			  ukontainer/$name:$VERSION$SLIM-osx-amd64 \
			  --os darwin --arch amd64
       /tmp/docker/docker -D manifest annotate ukontainer/$name:$VERSION$SLIM \
			  ukontainer/$name:$VERSION$SLIM-linux-amd64 \
			  --os linux --arch amd64
       /tmp/docker/docker -D manifest annotate ukontainer/$name:$VERSION$SLIM \
			  ukontainer/$name:$VERSION$SLIM-linux-arm64 \
			  --os linux --arch arm64
       /tmp/docker/docker -D manifest annotate ukontainer/$name:$VERSION$SLIM \
			  ukontainer/$name:$VERSION$SLIM-linux-arm \
			  --os linux --arch arm
       /tmp/docker/docker -D manifest push ukontainer/$name:$VERSION$SLIM

       /tmp/docker/docker -D manifest inspect ukontainer/$name:$VERSION$SLIM \
			  >> $HOME/docker-manifest.log
       /tmp/docker/docker -D manifest inspect -v ukontainer/$name:$VERSION$SLIM \
			  >> $HOME/docker-manifest.log
}

# pre-deploy
sudo apt-get update
sudo apt-get install p7zip-full jq

# obtain newer docker command
curl -fsSL  curl -O https://download.docker.com/linux/static/stable/x86_64/docker-18.06.1-ce.tgz \
     -o /tmp/docker-18.06.1-ce.tgz
tar xfz /tmp/docker-18.06.1-ce.tgz -C /tmp/
chmod +x /tmp/docker/docker

# create images
OS_ARCH_MTX=("linux amd64" "linux arm" "linux arm64" "osx amd64")
PKGS="node python netperf nginx sqlite-bench named"

for i in "${OS_ARCH_MTX[@]}"
do
    os_arch=(${i[@]})
    os=${os_arch[0]}
    arch=${os_arch[1]}

    # 1: deploy all binaries in runu-base
    deploy ${os_arch[@]}

    # 2x: deploy slimmed image with a few binaries
    for pkg in $PKGS
    do
	deploy_slim ${os_arch[@]} $pkg
	deploy_slim ${os_arch[@]} $pkg "-slim"
    done
done

# enable experimental features
cat  ~/.docker/config.json | jq '. += {"experimental": "enabled"}' > /tmp/1
mv /tmp/1 ~/.docker/config.json

# create multi-arch image
create_multi_arch_image runu-base
for pkg in $PKGS
do
    create_multi_arch_image runu-$pkg
    create_multi_arch_image runu-$pkg "-slim"
done
