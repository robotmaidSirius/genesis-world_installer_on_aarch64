#!/bin/bash
INSTALL_VER=9.4.1
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
INSTALL_URL=https://www.vtk.org/files/release/${INSTALL_VER%.*}/VTK-${INSTALL_VER}.tar.gz
INSTALL_DIR=${INSTALL_ROOT}/VTK-${INSTALL_VER}
RESULT=0
# ========================================

mkdir -p ${INSTALL_ROOT}
pushd "${INSTALL_ROOT}" >/dev/null 2>&1
    if [ ! -d ${INSTALL_DIR} ]; then
        wget ${INSTALL_URL}
        tar zxf VTK-${INSTALL_VER}.tar.gz
        rm VTK-${INSTALL_VER}.tar.gz
    fi

    pushd "${INSTALL_DIR}" >/dev/null 2>&1
        mkdir -p ${INSTALL_DIR}/build
        pushd "${INSTALL_DIR}/build" >/dev/null 2>&1
            # BUILD LLVM
            cmake ..
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
