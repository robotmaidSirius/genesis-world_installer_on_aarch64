#!/bin/bash
INSTALL_VER=v2022.0.0
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
        INSTALL_ROOT=${1#*=}
        shift;;
    -p|--root)
        shift
        INSTALL_ROOT=$1
        shift;;
    *) echo "Unknown parameter passed: $1"; shift;;
  esac
done
INSTALL_URL=https://github.com/oneapi-src/oneTBB.git
INSTALL_DIR=${INSTALL_ROOT}/oneTBB
RESULT=0
# ========================================

mkdir -p ${INSTALL_ROOT}
pushd "${INSTALL_ROOT}" >/dev/null 2>&1
    if [ ! -d ${INSTALL_DIR} ]; then
        git clone --recurse-submodules ${INSTALL_URL} ${INSTALL_DIR}
    fi

    pushd "${INSTALL_DIR}" >/dev/null 2>&1
        git checkout ${INSTALL_VER}
        mkdir -p ${INSTALL_DIR}/build
        pushd "${INSTALL_DIR}/build" >/dev/null 2>&1
            cmake .. -DCMAKE_BUILD_TYPE=Release
            RESULT=$?
            if [ ${RESULT} -eq 0 ]; then
                make -j $(nproc)
                RESULT=$?
            fi
            if [ ${RESULT} -eq 0 ]; then
                sudo make install
                RESULT=$?
            fi
        popd >/dev/null 2>&1
    popd >/dev/null 2>&1
popd >/dev/null 2>&1

exit ${RESULT}
