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
	# XXX: redis uses ${ARCH} in Makefile
	ARCH="" make -j2
fi

if [ $TRAVIS_ARCH == "amd64" ] ; then
    export ARCH=amd64
elif [ $TRAVIS_ARCH == "aarch64" ] ; then
    export ARCH=${ARCH:-arm64}
fi



BINARY=(
    "nginx nginx"
    "python3 python"
    "netperf netperf"
    "sqlite-bench sqlite-bench"
    "nodejs node"
)
upload_to_bintray(){
	local bin=""
	for i in "${BINARY[@]}"
	do
		pkg_bin=(${i[@]})
		pkg=${pkg_bin[0]}
		if [ "$pkg" == "${PACKAGE}" ] ; then
			bin=${pkg_bin[1]}
			break
		fi
	done
	if [ -z "$bin" ] ; then
		return
	fi
	echo "==== copying $bin ===="

	curl -T bin/$bin -u$BINTRAY_USER:$BINTRAY_APIKEY \
	       "https://api.bintray.com/content/ukontainer/ukontainer/rumprun-packages/dev/$TRAVIS_OS_NAME/$ARCH/$bin;override=1&publish=1"

	# additional installation
	if [ "${PACKAGE}" == "nginx" ]; then
	    curl -T images/data.iso -u$BINTRAY_USER:$BINTRAY_APIKEY \
		 "https://api.bintray.com/content/ukontainer/ukontainer/rumprun-packages/dev/$TRAVIS_OS_NAME/$ARCH/data.iso;override=1&publish=1"
	fi

	if [ "${PACKAGE}" == "python3" ]; then
		if [ "$TRAVIS_OS_NAME" == "linux" ] && [ "$TRAVIS_ARCH" == "amd64" ]; then
			curl -T images/python.img -u$BINTRAY_USER:$BINTRAY_APIKEY \
			     "https://api.bintray.com/content/ukontainer/ukontainer/rumprun-packages/dev/$TRAVIS_OS_NAME/$ARCH/python.img;override=1&publish=1"
		fi

		curl -T images/python.iso -u$BINTRAY_USER:$BINTRAY_APIKEY \
		     "https://api.bintray.com/content/ukontainer/ukontainer/rumprun-packages/dev/$TRAVIS_OS_NAME/$ARCH/python.iso;override=1&publish=1"
	fi

	if [ "${PACKAGE}" == "netperf" ]; then
	    curl -T build/src/netserver -u$BINTRAY_USER:$BINTRAY_APIKEY \
		 "https://api.bintray.com/content/ukontainer/ukontainer/rumprun-packages/dev/$TRAVIS_OS_NAME/$ARCH/netserver;override=1&publish=1"
	fi
}

upload_to_bintray
