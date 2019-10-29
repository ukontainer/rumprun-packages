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
	       "https://api.bintray.com/content/ukontainer/ukontainer/rumprun-packages/dev/$TRAVIS_OS_NAME/$ARCH/nginx;override=1&publish=1"
	curl -T images/data.iso -u$BINTRAY_USER:$BINTRAY_APIKEY \
	      "https://api.bintray.com/content/ukontainer/ukontainer/rumprun-packages/dev/$TRAVIS_OS_NAME/$ARCH/data.iso;override=1&publish=1"
fi

if [ "${PACKAGE}" == "python3" ]; then
	if [ "$TRAVIS_OS_NAME" == "osx" ]; then
		EXESUFFIX=.exe
	fi

	curl -T build/python$EXESUFFIX -u$BINTRAY_USER:$BINTRAY_APIKEY \
	       "https://api.bintray.com/content/ukontainer/ukontainer/rumprun-packages/dev/$TRAVIS_OS_NAME/$ARCH/python;override=1&publish=1"
	if [ "$TRAVIS_OS_NAME" == "linux" ] && [ "$TRAVIS_ARCH" == "amd64" ]; then
	  curl -T images/python.img -u$BINTRAY_USER:$BINTRAY_APIKEY \
	      "https://api.bintray.com/content/ukontainer/ukontainer/rumprun-packages/dev/$TRAVIS_OS_NAME/$ARCH/python.img;override=1&publish=1"
	fi
 
	curl -T images/python.iso -u$BINTRAY_USER:$BINTRAY_APIKEY \
	      "https://api.bintray.com/content/ukontainer/ukontainer/rumprun-packages/dev/$TRAVIS_OS_NAME/$ARCH/python.iso;override=1&publish=1"
fi

if [ "${PACKAGE}" == "netperf" ]; then
	curl -T build/src/netperf -u$BINTRAY_USER:$BINTRAY_APIKEY \
	       "https://api.bintray.com/content/ukontainer/ukontainer/rumprun-packages/dev/$TRAVIS_OS_NAME/$ARCH/netperf;override=1&publish=1"
	curl -T build/src/netserver -u$BINTRAY_USER:$BINTRAY_APIKEY \
	      "https://api.bintray.com/content/ukontainer/ukontainer/rumprun-packages/dev/$TRAVIS_OS_NAME/$ARCH/netserver;override=1&publish=1"
fi

if [ "${PACKAGE}" == "sqlite-bench" ]; then
	curl -T bin/sqlite-bench -u$BINTRAY_USER:$BINTRAY_APIKEY \
	       "https://api.bintray.com/content/ukontainer/ukontainer/rumprun-packages/dev/$TRAVIS_OS_NAME/$ARCH/sqlite-bench;override=1&publish=1"
fi

if [ "${PACKAGE}" == "nodejs" ]; then
	curl -T bin/node -u$BINTRAY_USER:$BINTRAY_APIKEY \
	       "https://api.bintray.com/content/ukontainer/ukontainer/rumprun-packages/dev/$TRAVIS_OS_NAME/$ARCH/node;override=1&publish=1"
fi
