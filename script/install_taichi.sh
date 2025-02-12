#!/bin/bash
# TODO: 重複のためが発生したため[python setup.py install]をコメントアウトしたが、ただしか？
INSTALL_VER=v1.7.3
INSTALL_ROOT=~/genesis

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
        echo "Usage: $0 -v|--ver [version] -p|--root [path]"
        exit 0;;
    -v=*|--ver=*)
        INSTALL_VER=${1#*=}
        shift;;
    -v|--ver)
        shift
        INSTALL_VER=$1
        shift;;
    -p=*|--root=*)
        if [ "" != "${1#*=}" ];then
            INSTALL_ROOT=${1#*=}
        fi
        shift;;
    -p|--root)
        shift
        if [ "" != "$1" ];then
            INSTALL_ROOT=$1
        fi
        shift;;
    *) echo "Unknown parameter passed: $1"; shift;;
  esac
done
if [ "" == "${INSTALL_VER}" ];then
    echo "[WARNING] Since no version was specified, the installation was skipped."
    exit 0
fi
SCRIPT_DIR=$(cd $(dirname $0); pwd)
INSTALL_URL=https://github.com/taichi-dev/taichi.git
INSTALL_DIR=${INSTALL_ROOT}/taichi
RESULT=0
# ========================================

export CC=$(which clang)
export CXX=$(which clang++)
export TAICHI_CMAKE_ARGS="-DTI_BUILD_EXAMPLES:BOOL=OFF -DTI_WITH_CUDA_TOOLKIT:BOOL=OFF -DTI_WITH_VULKAN:BOOL=ON -DTI_WITH_CUDA:BOOL=ON -DTI_WITH_LLVM:BOOL=ON"

mkdir -p ${INSTALL_ROOT}
pushd "${INSTALL_ROOT}" >/dev/null 2>&1
    if [ ! -d ${INSTALL_DIR} ]; then
        git clone --recurse-submodules ${INSTALL_URL} ${INSTALL_DIR}
    fi

    pushd "${INSTALL_DIR}" >/dev/null 2>&1
        git checkout .
        git checkout ${INSTALL_VER}
        # Patch
        patch -p 1 < ${SCRIPT_DIR}/misc/taichi_build_ARM.patch
        # ./build.py
        RESULT=$?
        if [ ${RESULT} -eq 0 ]; then
            python setup.py develop
            RESULT=$?
            #if [ ${RESULT} -eq 0 ]; then
            #    python setup.py install
            #    RESULT=$?
            #fi
        fi
    popd >/dev/null 2>&1
popd >/dev/null 2>&1

exit ${RESULT}
