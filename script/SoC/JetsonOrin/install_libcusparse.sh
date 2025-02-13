#!/bin/bash
set -ex

# cuSPARSELt license: https://docs.nvidia.com/cuda/cusparselt/license.html
mkdir -p tmp_cusparselt
pushd "tmp_cusparselt" >/dev/null 2>&1
    arch_path=${TARGET_ARCH:-$(uname -m)}
    CUSPARSELT_NAME="libcusparse_lt-linux-${arch_path}-0.7.0.0-archive"
    curl --retry 3 -OLs https://developer.download.nvidia.com/compute/cusparselt/redist/libcusparse_lt/linux-${arch_path}/${CUSPARSELT_NAME}.tar.xz

    tar xf ${CUSPARSELT_NAME}.tar.xz
    cp -a ${CUSPARSELT_NAME}/include/* /usr/local/cuda/include/
    cp -a ${CUSPARSELT_NAME}/lib/* /usr/local/cuda/lib64/
    echo "Installed cuSPARSELt: ${CUSPARSELT_NAME}"
popd >/dev/null 2>&1
rm -rf tmp_cusparselt
ldconfig
