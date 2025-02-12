#!/bin/bash
INSTALL_VER=2.4.1
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
CURRENT_VER=$(pip show libigl | grep Version)
if [[ "${CURRENT_VER}" =~ "${INSTALL_VER#v}" ]]; then
    echo "[SKIP] libigl ${CURRENT_VER} is already installed"
    exit 0
fi

INSTALL_URL=https://github.com/libigl/libigl-python-bindings.git
INSTALL_DIR=${INSTALL_ROOT}/libigl-python-bindings
RESULT=0
# ========================================

mkdir -p ${INSTALL_ROOT}
pushd "${INSTALL_ROOT}" >/dev/null 2>&1
    if [ ! -d ${INSTALL_DIR} ]; then
        git clone --recurse-submodules ${INSTALL_URL} ${INSTALL_DIR}
    fi

    pushd "${INSTALL_DIR}" >/dev/null 2>&1
        git checkout ${INSTALL_VER}
        pip install ./
        RESULT=$?
    popd >/dev/null 2>&1
popd >/dev/null 2>&1

exit ${RESULT}
