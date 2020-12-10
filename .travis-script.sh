#!/bin/bash

BINARY=(
    "nginx nginx"
    "python3 python"
    "netperf netperf"
    "sqlite-bench sqlite-bench"
    "nodejs node"
    "named named"
)

# upload built binaries to bintray
upload_binary_to_bintray() {
	local PUB_SUFFIX=$1

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

	# fixup arch name
	if [ $TRAVIS_ARCH == "amd64" ] ; then
		export ARCH=amd64
	elif [ $TRAVIS_ARCH == "aarch64" ] ; then
		export ARCH=${ARCH:-arm64}
	fi

	if [ -n "$PUB_SUFFIX" ] ; then
		strip bin/$bin -o bin/$bin$PUB_SUFFIX
	fi

	echo "==== copying $bin ===="

	curl -T bin/$bin$PUB_SUFFIX -u$BINTRAY_USER:$BINTRAY_APIKEY \
	       "https://api.bintray.com/content/ukontainer/ukontainer/rumprun-packages/dev/$TRAVIS_OS_NAME/$ARCH/$bin$PUB_SUFFIX;override=1&publish=1"


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
		 "https://api.bintray.com/content/ukontainer/ukontainer/rumprun-packages/dev/$TRAVIS_OS_NAME/$ARCH/netserver$PUB_SUFFIX;override=1&publish=1"
	fi

	if [ "${PACKAGE}" == "named" ]; then
		if [ "$TRAVIS_OS_NAME" == "linux" ] && [ "$TRAVIS_ARCH" == "amd64" ]; then
			curl -T images/named.img -u$BINTRAY_USER:$BINTRAY_APIKEY \
				"https://api.bintray.com/content/ukontainer/ukontainer/rumprun-packages/dev/$TRAVIS_OS_NAME/$ARCH/named.img;override=1&publish=1"
		fi
	fi

	# publish !
#	curl -X POST -u$BINTRAY_USER:$BINTRAY_APIKEY \
#	     https://api.bintray.com/content/ukontainer/ukontainer/rumprun-packages/dev/publish
}


# Builds one specific package, specified by $PACKAGE
if [ -z "${PACKAGE}" ]; then
	echo "PACKAGE is not set"
	exit 1
fi

cd ${PACKAGE}
# Openjdk make should not be used with option -j
if [ "${PACKAGE}" == "openjdk8" ]; then
	MKARG=""
# redis conflicts with ARCH env variable
elif [ "${PACKAGE}" == "redis" ]; then
	MKARG="ARCH= -j2"
else
	MKARG="-j2"
fi

make distclean || true
make clean || true
make $MKARG
upload_binary_to_bintray
# create slim image
make clean || true
PATH=/opt/rump-tiny/bin:$PATH make $MKARG
upload_binary_to_bintray "-slim"
