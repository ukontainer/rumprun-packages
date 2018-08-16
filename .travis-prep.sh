#!/bin/bash

git clone -q https://github.com/libos-nuse/frankenlibc -b lkl-musl-macho /tmp/frankenlibc
(
	cd /tmp/frankenlibc
	git submodule update --init
	./build.sh -q -k linux

	mkdir -p docker
	mv rump docker/
	cp rumpobj/tests/ping docker/rump/bin
	cp rumpobj/tests/hello docker/rump/bin
	cd docker
	cat << EOF > Dockerfile
FROM ubuntu:16.04
COPY ./rump /rump
EOF

	# push rumprun-cc to a temporary docker image
	echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
	docker build -t $DOCKER_USERNAME/travis-build-frankenlibc .
	docker images
	docker push $DOCKER_USERNAME/travis-build-frankenlibc
)
