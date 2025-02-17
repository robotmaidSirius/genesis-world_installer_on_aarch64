#!/bin/bash
## BUILD TYPE: make
INSTALL_VER=v2022.0.0
INSTALL_ROOT=~/genesis

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
        echo "Usage: $0 [-v|--ver VERSION] [-p|--root INSTALL_ROOT]"
        echo "  -v, --ver VERSION       : Specify the version to install"
        echo "  -p, --root INSTALL_ROOT : Specify the root directory to install"
        exit 0;;
    --force-reinstall)
        echo "[MESS] force reinstall"
        FORCE_REINSTALL=1
        shift;;
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
    *) echo "[WARNING] Unknown parameter passed: $1" >&2; shift;;
  esac
done
if [ "" == "${INSTALL_VER}" ];then
    echo "[WARNING] Since no version was specified, the installation was skipped." >&2
    exit 0
fi
if [[ ${FORCE_REINSTALL} -ne 1 ]]; then
    CURRENT_VER=$(pkg-config --modversion tbb)
    if [[ "${CURRENT_VER}" =~ "${INSTALL_VER#v}" ]]; then
        echo "[SKIP] oneTBB ${CURRENT_VER} is already installed"
        exit 0
    fi
fi

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
