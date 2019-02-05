#!/bin/bash

realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

XCODE="/Applications/Xcode.app/Contents/Developer"
if [ ! -d "$XCODE" ]; then
	echo "You have to install Xcode and the command line tools first"
	exit 1
fi

if [ "$#" -ne 2 ]; then
	echo "Usage: $0 <arch> <build type>"
	echo ""
	echo "Available archs: armv7, armv7s, armv8, i386, x86_64"
	echo "Available build types: Debug, Release"
	echo ""
	echo "Exiting."
	exit 1
fi

ARCH=$1
BUILD_ARCH=$ARCH
HOST=$1
if [ "$ARCH" == "armv8" ]; then
    BUILD_ARCH="arm64"
    HOST="arm"
fi

PLATFORM="iPhoneOS"
SDK="iPhoneOS"
if [ "$ARCH" == "i386" ] || [ "$ARCH" == "x86_64" ]; then
	PLATFORM="iPhoneSimulator"
	SDK="iPhoneSimulator"
fi

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

git apply ../patches/patch_curl_fixes1172.diff

export CC="$XCODE/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
DESTDIR="$SCRIPTPATH/build/iOS"

export IPHONEOS_DEPLOYMENT_TARGET="9"


# Build for specified arch, host, platform and sdk
export CFLAGS="-arch ${BUILD_ARCH} -pipe -Os -gdwarf-2 -isysroot $XCODE/Platforms/${PLATFORM}.platform/Developer/SDKs/${SDK}.sdk -miphoneos-version-min=${IPHONEOS_DEPLOYMENT_TARGET} -fembed-bitcode -Werror=partial-availability"
export LDFLAGS="-arch ${BUILD_ARCH} -isysroot $XCODE/Platforms/${PLATFORM}.platform/Developer/SDKs/${SDK}.sdk"
if [ "${PLATFORM}" = "iPhoneSimulator" ]; then
	export CPPFLAGS="-D__IPHONE_OS_VERSION_MIN_REQUIRED=${IPHONEOS_DEPLOYMENT_TARGET%%.*}0000"
fi
cd "$CURLPATH"
./configure	--host="${HOST}-apple-darwin" \
		${DEBUG_OPTION} \
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
rm -f "${FULL_DESTDIR}/include/curl/.gitignore"

cd "$PWD"
