#!/bin/bash
# Builds one specific package, specified by $PACKAGE
if [ -z "${PACKAGE}" ]; then
	echo "PACKAGE is not set"
	exit 1
fi
cd ${PACKAGE}
# Openjdk make should not be used with option -j
if [ "${PACKAGE}" == "openjdk8" ]; then
	make
else
	make -j2
fi

if [ "${PACKAGE}" == "nginx" ]; then
	curl -T bin/nginx -u$BINTRAY_USER:$BINTRAY_APIKEY \
	       https://api.bintray.com/content/libos-nuse/runu-rumprun-packages/all/dev/$TRAVIS_OS_NAME/nginx
	curl -T images/data.iso -u$BINTRAY_USER:$BINTRAY_APIKEY \
	      https://api.bintray.com/content/libos-nuse/runu-rumprun-packages/all/dev/$TRAVIS_OS_NAME/data.iso
fi

if [ "$TRAVIS_OS_NAME" == "osx" ]; then
	EXESUFFIX=.exe
fi
if [ "${PACKAGE}" == "python3" ]; then
	curl -T build/python$EXESUFFIX -u$BINTRAY_USER:$BINTRAY_APIKEY \
	       https://api.bintray.com/content/libos-nuse/runu-rumprun-packages/all/dev/$TRAVIS_OS_NAME/python
	if [ "$TRAVIS_OS_NAME" == "linux" ]; then
	  curl -T images/python.img -u$BINTRAY_USER:$BINTRAY_APIKEY \
	      https://api.bintray.com/content/libos-nuse/runu-rumprun-packages/all/dev/$TRAVIS_OS_NAME/python.img
	fi
 
	curl -T images/python.iso -u$BINTRAY_USER:$BINTRAY_APIKEY \
	      https://api.bintray.com/content/libos-nuse/runu-rumprun-packages/all/dev/$TRAVIS_OS_NAME/python.iso
fi

if [ "${PACKAGE}" == "netperf" ]; then
	curl -T build/src/netperf -u$BINTRAY_USER:$BINTRAY_APIKEY \
	       https://api.bintray.com/content/libos-nuse/runu-rumprun-packages/all/dev/$TRAVIS_OS_NAME/netperf
	curl -T build/src/netserver -u$BINTRAY_USER:$BINTRAY_APIKEY \
	      https://api.bintray.com/content/libos-nuse/runu-rumprun-packages/all/dev/$TRAVIS_OS_NAME/netserver
fi

