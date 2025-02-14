#!/bin/bash
## BUILD TYPE: python bdist_wheel
##               append cmake_args: TAICHI_CMAKE_ARGS
INSTALL_VER=v1.7.3
INSTALL_ROOT=~/genesis
INSTALL_APPLY_PATCH=0
DIST_DIR=$(cd $(dirname $(realpath "${BASH_SOURCE:-0}")); pwd)/dist
SCRIPT_DIR=$(cd $(dirname $(realpath "${BASH_SOURCE:-0}")); pwd)/script
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
    -ap|--apply_patch)
        echo "[MESS] Apply patch"
        INSTALL_APPLY_PATCH=1
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
    CURRENT_VER=$(pip show taichi | grep Version)
    if [[ "${CURRENT_VER}" =~ "${INSTALL_VER#v}" ]]; then
        echo "[SKIP] taichi ${CURRENT_VER} is already installed"
        exit 0
    fi
fi

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
        rm -rf ./dist
        if [ ${INSTALL_APPLY_PATCH} -eq 1 ]; then
            git checkout .
        fi
        git checkout ${INSTALL_VER}
        # Patch
        if [ ${INSTALL_APPLY_PATCH} -eq 1 ]; then
            patch -p 1 < ${SCRIPT_DIR}/misc/taichi_build_ARM.patch
        fi
        RESULT=$?
        if [ ${RESULT} -eq 0 ]; then
            # ./build.py
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

exit ${RESULT}
