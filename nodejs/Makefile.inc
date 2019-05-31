NODE_VERSION=6.17.1
PKGSRC=nodejs4
BUILD_DIR=build-$(NODE_VERSION)
NODE_BIN=$(BUILD_DIR)/out/Release/node-$(shell basename `readlink $(dir $(realpath $(lastword $(MAKEFILE_LIST))))/rumpmain.js` .js)
