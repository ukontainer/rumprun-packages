#!/bin/bash

BINARY=(
    "nginx nginx"
    "python3 python"
    "netperf netperf"
    "sqlite-bench sqlite-bench"
    "nodejs node"
    "named named"
)

# upload built binaries to github releases
upload_a_file_to_github() {
    FILE=$1
    DEST_FILE=$2
    TAG=dev
    ACCEPT_HEADER="Accept: application/vnd.github.jean-grey-preview+json"
    TOKEN_HEADER="Authorization: token $GITHUB_TOKEN"
    ENDPOINT="https://api.github.com/repos/$TRAVIS_REPO_SLUG/releases"


    echo "Creating new release as version ${TAG}..."
    REPLY=$(curl -s -H "${ACCEPT_HEADER}" -H "${TOKEN_HEADER}" -d "{\"tag_name\": \"${TAG}\", \"name\": \"${TAG}\"}" "${ENDPOINT}")

    # Check error
    RELEASE_ID=$(echo "${REPLY}" | jq .id)

    # retry for pre-existing tag case
    if [ "${RELEASE_ID}" = "null" ] || [ "${RELEASE_ID}" = "" ] ; then
	RELEASE_ID=$(curl -H "${TOKEN_HEADER}" ${ENDPOINT} | jq -r ".[] | select(.tag_name == \"$TAG\") | .id")
    fi

    if [ "${RELEASE_ID}" = "null" ]; then
	echo "Failed to create release. Please check your configuration. Github replies:"
	echo "${REPLY}"
	exit 1
    fi

    echo "Github release created as ID: ${RELEASE_ID}"
    RELEASE_URL="https://uploads.github.com/repos/$TRAVIS_REPO_SLUG/releases/${RELEASE_ID}/assets"


    # Uploads artifacts
    MIME=$(file -b --mime-type "${FILE}")

    # delete previous asset
    ASSET_ID=$(curl -s -H "${TOKEN_HEADER}" ${ENDPOINT} | jq -r ".[] | select(.tag_name == \"$TAG\") | .assets | .[] | select(.name == \"$DEST_FILE\") | .id")
    echo "Deleting previous assets ${DEST_FILE} if any..."

    curl  \
	-X DELETE \
	-H "${TOKEN_HEADER}" \
	-H "Accept: application/vnd.github.v3+json" \
	"${ENDPOINT}/assets/"$ASSET_ID || true

    echo "Uploading assets ${DEST_FILE} as ${MIME}..."
    curl -v \
	 -H "${ACCEPT_HEADER}" \
	 -H "${TOKEN_HEADER}" \
	 -H "Content-Type: ${MIME}" \
	 --data-binary "@${FILE}" \
	 "${RELEASE_URL}?name=${DEST_FILE}"

    echo "Finished."
}

upload_binary_to_github() {
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
	upload_a_file_to_github "bin/$bin$PUB_SUFFIX" "$bin-$TRAVIS_OS_NAME-$ARCH$PUB_SUFFIX"


	# additional installation
	if [ "${PACKAGE}" == "nginx" ]; then
	    upload_a_file_to_github "images/data.iso" "data-$TRAVIS_OS_NAME-$ARCH.iso"
	fi

	if [ "${PACKAGE}" == "python3" ]; then
		if [ "$TRAVIS_OS_NAME" == "linux" ] && [ "$TRAVIS_ARCH" == "amd64" ]; then
			upload_a_file_to_github "images/python.img" "python-$TRAVIS_OS_NAME-$ARCH.img"
		fi

		upload_a_file_to_github "images/python.iso" "python-$TRAVIS_OS_NAME-$ARCH.iso"
	fi

	if [ "${PACKAGE}" == "netperf" ]; then
	    upload_a_file_to_github "build/src/netserver" "netserver-$TRAVIS_OS_NAME-$ARCH$PUB_SUFFIX"
	fi

	if [ "${PACKAGE}" == "named" ]; then
		if [ "$TRAVIS_OS_NAME" == "linux" ] && [ "$TRAVIS_ARCH" == "amd64" ]; then
			upload_a_file_to_github "images/named.img" "named-$TRAVIS_OS_NAME-$ARCH.img"
		fi
	fi
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
make $MKARG > $HOME/make.log
upload_binary_to_github
# create slim image
make clean || true
PATH=/opt/rump-tiny/bin:$PATH make $MKARG > $HOME/make-tiny.log
upload_binary_to_github "-slim"
