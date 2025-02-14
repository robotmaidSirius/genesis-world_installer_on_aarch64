#!/bin/bash
## BUILD TYPE: cmake, python bdist_wheel
INSTALL_VER=9.4.1
INSTALL_ROOT=~/genesis
DIST_DIR=$(cd $(dirname $(realpath "${BASH_SOURCE:-0}")); pwd)/dist
FORCE_REINSTALL=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
        echo "Usage: $0 -v|--ver [version] -p|--root [path]"
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
    -d=*|--dist=*)
        if [ "" != "${1#*=}" ];then
            DIST_DIR=${1#*=}
        fi
        shift;;
    -d|--dist)
        shift
        if [ "" != "$1" ];then
            DIST_DIR=$1
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
    CURRENT_VER=$(pip show vtk | grep Version)
    if [[ "${CURRENT_VER}" =~ "${INSTALL_VER#v}" ]]; then
        echo "[SKIP] vtk ${CURRENT_VER} is already installed"
        exit 0
    fi
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
            rm -rf ./dist
            # BUILD LLVM
            cmake .. \
                -D CMAKE_BUILD_TYPE=Release \
                -D VTK_WHEEL_BUILD=ON \
                -D VTK_WRAP_PYTHON=ON \
                -D VTK_PYTHON_VERSION=3 \
                -D VTK_GROUP_ENABLE_Rendering=YES \
                -D VTK_GROUP_ENABLE_Imaging=YES \
                -D VTK_GROUP_ENABLE_MPI=NO \
                -D PYTHON_EXECUTABLE=$(which python)
            RESULT=$?
            if [ ${RESULT} -eq 0 ]; then
                make -j $(nproc)
                RESULT=$?
            fi
            if [ ${RESULT} -eq 0 ]; then
                python setup.py bdist_wheel
                RESULT=$?
                if [ ${RESULT} -eq 0 ]; then
                    mkdir -p ${DIST_DIR}
                    cp -f ./dist/* ${DIST_DIR}
                    files=(`ls -1 dist/*.whl`)
                    for file_name in "${files[@]}"; do
                        echo ${file_name}
                        pip install --no-cache ${file_name}
                        RESULT=$?
                        if [ ${RESULT} -ne 0 ]; then
                            break
                        fi
                    done
                fi
            fi
        popd >/dev/null 2>&1
    popd >/dev/null 2>&1
popd >/dev/null 2>&1

exit ${RESULT}
