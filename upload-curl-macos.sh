#!/usr/bin/env bash
# ----------------------------------------------------------------------------------------------------------------------
# The MIT License (MIT)
#
# Copyright (c) 2019 Ralph-Gordon Paul, Simon Lang. All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
# documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit
# persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
# Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# ----------------------------------------------------------------------------------------------------------------------

set -e

if [ "$1" == "--help" ]; then
    echo "Usage: $0 [-f|--force]"
    exit 0
fi

FORCE_FLAG=$1
if [ "$FORCE_FLAG" == "-f" ] || [ "$FORCE_FLAG" == "--force" ]; then
    FORCE_FLAG="--force"
else
    FORCE_FLAG=""
fi

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

    conan export-pkg . ${FORCE_FLAG} ${LIBRARY_NAME}/${LIBRARY_VERSION}@${CONAN_USER}/${CONAN_CHANNEL} -s os=Macos \
        -s os.version=${MACOS_SDK_VERSION} -s compiler=apple-clang -s compiler.libcxx=libc++ -s build_type=${BUILD_TYPE} \
        -s arch=${ARCH}
}

#=======================================================================================================================

function uploadConanPackages()
{
    conan upload ${FORCE_FLAG} ${LIBRARY_NAME}/${LIBRARY_VERSION}@appcom/stable -r appcom-oss --all
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
