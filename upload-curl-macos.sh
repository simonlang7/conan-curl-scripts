#!/usr/bin/env bash

set -e

#=======================================================================================================================
# settings

declare LIBRARY_NAME=curl
declare LIBRARY_VERSION=7.60.0

declare CONAN_USER=appcom
declare CONAN_CHANNEL=stable

#=======================================================================================================================
# globals

declare ABSOLUTE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
declare MACOS_SDK_VERSION=$(xcodebuild -showsdks | grep macosx | awk '{print $4}' | sed 's/[^0-9,\.]*//g')

#=======================================================================================================================

function createDirectoryStructure()
{
    ARCH=$1
    BUILD_TYPE=$2

    rm -Rf "${ABSOLUTE_DIR}/conan/" || true
    mkdir -p "${ABSOLUTE_DIR}/conan/"
    cp -R "${ABSOLUTE_DIR}/build/macOS/${ARCH}/${BUILD_TYPE}/include" "${ABSOLUTE_DIR}/build/macOS/${ARCH}/${BUILD_TYPE}/lib" "${ABSOLUTE_DIR}/conan/"
}

#=======================================================================================================================

function createConanPackage()
{
    ARCH=$1
    BUILD_TYPE=$2

    conan export-pkg . -f ${LIBRARY_NAME}/${LIBRARY_VERSION}@${CONAN_USER}/${CONAN_CHANNEL} -s os=Macos \
        -s os.version=${MACOS_SDK_VERSION} -s compiler=apple-clang -s compiler.libcxx=libc++ -s build_type=${BUILD_TYPE} \
        -s arch=${ARCH}
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

createDirectoryStructure x86_64 Release
createConanPackage x86_64 Release
cleanup

uploadConanPackages
