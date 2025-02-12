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
CURRENT_VER=$(pip show vtk | grep Version)
if [[ "${CURRENT_VER}" =~ "${INSTALL_VER#v}" ]]; then
    echo "[SKIP] vtk ${CURRENT_VER} is already installed"
    exit 0
fi

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
            cmake .. \
                -DCMAKE_BUILD_TYPE=Release \
                -DVTK_WHEEL_BUILD=ON \
                -DVTK_WRAP_PYTHON=ON \
                -DVTK_PYTHON_VERSION=3 \
                -DVTK_GROUP_ENABLE_Rendering=YES \
                -DVTK_GROUP_ENABLE_Imaging=YES \
                -DVTK_GROUP_ENABLE_MPI=NO \
                -DPYTHON_EXECUTABLE=$(which python)
            RESULT=$?
            if [ ${RESULT} -eq 0 ]; then
                make -j $(nproc)
                RESULT=$?
            fi
            if [ ${RESULT} -eq 0 ]; then
                pip install .
                RESULT=$?
            fi
        popd >/dev/null 2>&1
    popd >/dev/null 2>&1
popd >/dev/null 2>&1

exit ${RESULT}
