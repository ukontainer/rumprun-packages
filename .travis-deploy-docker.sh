#!/bin/bash
# build additional packages to be deployed

VERSION=0.2

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
	    https://dl.bintray.com/ukontainer/ukontainer/$OS/$ARCH/sqlite-bench -o bin/sqlite-bench

       # copy rootfs images
       curl -L -u $BINTRAY_USER:$BINTRAY_APIKEY \
	    https://dl.bintray.com/ukontainer/ukontainer/$OS/$ARCH/data.iso -o imgs/data.iso
       curl -L -u $BINTRAY_USER:$BINTRAY_APIKEY \
	    https://dl.bintray.com/ukontainer/ukontainer/linux/amd64/python.img -o imgs/python.img
       curl -L -u $BINTRAY_USER:$BINTRAY_APIKEY \
	    https://dl.bintray.com/ukontainer/ukontainer/$OS/$ARCH/python.iso -o imgs/python.iso

       curl -L https://dl.bintray.com/ukontainer/ukontainer/$OS/$ARCH/frankenlibc.tar.gz \
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
       docker build -t $DOCKER_USERNAME/runu-base:$VERSION-$OS-$ARCH .
       docker images
       docker push $DOCKER_USERNAME/runu-base:$VERSION-$OS-$ARCH

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

       cd runu-base
       mkdir -p bin imgs sbin

       curl -L -u $BINTRAY_USER:$BINTRAY_APIKEY \
	    https://dl.bintray.com/ukontainer/ukontainer/$OS/$ARCH/$NAME -o bin/$NAME

       if [ "$NAME" = "python" ] ; then
	   curl -L -u $BINTRAY_USER:$BINTRAY_APIKEY \
		https://dl.bintray.com/ukontainer/ukontainer/linux/amd64/python.img -o imgs/python.img
       elif [ "$NAME" = "nginx" ] ; then
	   curl -L -u $BINTRAY_USER:$BINTRAY_APIKEY \
		https://dl.bintray.com/ukontainer/ukontainer/$OS/$ARCH/data.iso -o imgs/data.iso
       elif [ "$NAME" = "netperf" ] ; then
	   curl -L -u $BINTRAY_USER:$BINTRAY_APIKEY \
		https://dl.bintray.com/ukontainer/ukontainer/$OS/$ARCH/netserver -o bin/netserver
       fi

       chmod +x bin/*

       ls -lR .
       # push an image to docker hub
       echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
       docker build -t $DOCKER_USERNAME/runu-$NAME:$VERSION-$OS-$ARCH .
       docker images
       docker push $DOCKER_USERNAME/runu-$NAME:$VERSION-$OS-$ARCH

       cd ..
       rm -rf runu-base
)
}


create_multi_arch_image() {
       local name=$1

       /tmp/docker/docker -D manifest create $DOCKER_USERNAME/$name:$VERSION \
			  $DOCKER_USERNAME/$name:$VERSION-osx-amd64 \
			  $DOCKER_USERNAME/$name:$VERSION-linux-amd64 \
			  $DOCKER_USERNAME/$name:$VERSION-linux-arm

       /tmp/docker/docker -D manifest annotate $DOCKER_USERNAME/$name:$VERSION \
			  $DOCKER_USERNAME/$name:$VERSION-osx-amd64 \
			  --os darwin --arch amd64
       /tmp/docker/docker -D manifest annotate $DOCKER_USERNAME/$name:$VERSION \
			  $DOCKER_USERNAME/$name:$VERSION-linux-amd64 \
			  --os linux --arch amd64
       /tmp/docker/docker -D manifest annotate $DOCKER_USERNAME/$name:$VERSION \
			  $DOCKER_USERNAME/$name:$VERSION-linux-arm \
			  --os linux --arch arm
       /tmp/docker/docker -D manifest push $DOCKER_USERNAME/$name:$VERSION

       /tmp/docker/docker -D manifest inspect $DOCKER_USERNAME/$name:$VERSION \
			  >> $HOME/docker-manifest.log
       /tmp/docker/docker -D manifest inspect -v $DOCKER_USERNAME/$name:$VERSION \
			  >> $HOME/docker-manifest.log
}


# obtain newer docker command
curl -fsSL  curl -O https://download.docker.com/linux/static/stable/x86_64/docker-18.06.1-ce.tgz \
     -o /tmp/docker-18.06.1-ce.tgz
tar xfz /tmp/docker-18.06.1-ce.tgz -C /tmp/
chmod +x /tmp/docker/docker

# create images
OS_ARCH_MTX=("linux amd64" "linux arm" "osx amd64")
PKGS="node python netperf nginx sqlite_bench"

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
done
