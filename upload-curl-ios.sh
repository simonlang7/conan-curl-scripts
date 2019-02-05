#!/usr/bin/env bash

set -e

#=======================================================================================================================
# settings

declare LIBRARY_NAME=curl
declare LIBRARY_VERSION=7.60.0

#=======================================================================================================================
# globals

declare ABSOLUTE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
declare IOS_SDK_VERSION=$(xcodebuild -showsdks | grep iphoneos | awk '{print $4}' | sed 's/[^0-9,\.]*//g')

#=======================================================================================================================

function createDirectoryStructure()
{
    ARCH=$1
    BUILD_TYPE=$2

    rm -Rf "${ABSOLUTE_DIR}/conan/" || true
    mkdir -p "${ABSOLUTE_DIR}/conan/"
    cp -R "${ABSOLUTE_DIR}/build/iOS/${ARCH}/${BUILD_TYPE}/include" "${ABSOLUTE_DIR}/build/iOS/${ARCH}/${BUILD_TYPE}/lib" "${ABSOLUTE_DIR}/conan/"
}


#=======================================================================================================================

function createThinFiles()
{
    ARCH=$1

    cd "${ABSOLUTE_DIR}/conan/lib"

    for file in *.a; do
        echo "lipo -extract $1 $file -output $file"
        lipo -extract $1 $file -output $file
    done

    cd "${ABSOLUTE_DIR}"
}

#=======================================================================================================================

function createConanPackage()
{
    ARCH=$1
    BUILD_TYPE=$2

    conan export-pkg . -f ${LIBRARY_NAME}/${LIBRARY_VERSION}@appcom/stable -s os=iOS -s os.version=${IOS_SDK_VERSION} \
          -s compiler=apple-clang -s compiler.libcxx=libc++ -s build_type=${BUILD_TYPE} -s arch=${ARCH} -s os_build=Macos \
          -s arch_build=x86_64
}

#=======================================================================================================================

function uploadConanPackages()
{
    conan upload ${LIBRARY_NAME}/${LIBRARY_VERSION}@appcom/stable -r appcom-oss --all
}

#=======================================================================================================================

function cleanup()
{
    rm -Rf "${ABSOLUTE_DIR}/conan" || true
}

createDirectoryStructure x86_64 Debug
createConanPackage x86_64 Debug
cleanup

createDirectoryStructure armv7 Debug
createConanPackage armv7 Debug
cleanup

createDirectoryStructure armv7s Debug
createConanPackage armv7s Debug
cleanup

createDirectoryStructure armv8 Debug
createConanPackage armv8 Debug
cleanup

createDirectoryStructure x86_64 Release
createConanPackage x86_64 Release
cleanup

createDirectoryStructure armv7 Release
createConanPackage armv7 Release
cleanup

createDirectoryStructure armv7s Release
createConanPackage armv7s Release
cleanup

createDirectoryStructure armv8 Release
createConanPackage armv8 Release
cleanup

uploadConanPackages
