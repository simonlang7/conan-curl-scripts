#!/bin/bash

realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

if [ "$#" -ne 2 ]; then
	echo "Usage: $0 <arch> <build type>"
	echo ""
	echo "Available archs: x86_64"
	echo "Available build types: Debug, Release"
	echo ""
	echo "Exiting."
	exit 1
fi

# TODO: use provided arch once more than one is supported
ARCH="x86_64"
HOST=$1
BUILD_ARCH=${ARCH}
BUILD_TYPE=$2

if [ "$BUILD_TYPE" == "Debug" ]; then
	DEBUG_OPTION="--enable-debug"
else
	DEBUG_OPTION="--disable-debug"
fi

REL_SCRIPT_PATH="$(dirname $0)"
SCRIPTPATH=$(realpath "$REL_SCRIPT_PATH")
CURLPATH="$SCRIPTPATH/curl-android-ios/curl"

PWD=$(pwd)
cd "$CURLPATH"

if [ ! -x "$CURLPATH/configure" ]; then
	echo "Curl needs external tools to be compiled"
	echo "Make sure you have autoconf, automake and libtool installed"

	./buildconf

	EXITCODE=$?
	if [ $EXITCODE -ne 0 ]; then
		echo "Error running the buildconf program"
		cd "$PWD"
		exit $EXITCODE
	fi
fi

DESTDIR="$SCRIPTPATH/build/macOS"

# Build for x86(_64)
cd "$CURLPATH"
./configure	${DEBUG_OPTION} \
		--with-darwinssl \
		--enable-static \
		--disable-shared \
		--enable-threaded-resolver \
		--disable-verbose \
		--enable-ipv6
EXITCODE=$?
if [ $EXITCODE -ne 0 ]; then
	echo "Error running the cURL configure program"
	cd "$PWD"
	exit $EXITCODE
fi

make -j $(sysctl -n hw.logicalcpu_max)
EXITCODE=$?
if [ $EXITCODE -ne 0 ]; then
	echo "Error running the make program"
	cd "$PWD"
	exit $EXITCODE
fi

FULL_DESTDIR="${DESTDIR}/$ARCH/${BUILD_TYPE}"
mkdir -p "${FULL_DESTDIR}/lib"
cp "$CURLPATH/lib/.libs/libcurl.a" "${FULL_DESTDIR}/lib/"
make clean

git checkout $CURLPATH
# Copy cURL headers
if [ -d "${FULL_DESTDIR}/include" ]; then
	echo "Cleaning headers"
	rm -rf "${FULL_DESTDIR}/include"
fi
cp -R "$CURLPATH/include" "${FULL_DESTDIR}/"
rm "${FULL_DESTDIR}/include/curl/.gitignore"

cd "$PWD"
