#!/bin/bash
## TODO: Installation is unverified
## BUILD TYPE: python bdist_wheel
# Reference:
## https://docs.nvidia.com/deeplearning/frameworks/install-pytorch-jetson-platform/index.html
## https://forums.developer.nvidia.com/t/pytorch-for-jetson/72048
### 'Build from Source'

INSTALL_VER=v2.1.2
INSTALL_NVP_MODEL=0
INSTALL_ROOT=~/genesis
DIST_DIR=$(cd $(dirname $(realpath "${BASH_SOURCE:-0}")); pwd)/dist
FORCE_REINSTALL=0
INSTALL_CUSPARSELT_VERSION=0.7.0.0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
        echo "Usage: $0 [-v|--ver VERSION] [-p|--root INSTALL_ROOT] [-d|--dist DIST_DIR] [--force-reinstall] [--nvp_model]"
        echo "  -v, --ver VERSION       : Specify the version to install"
        echo "  -p, --root INSTALL_ROOT : Specify the root directory to install"
        echo "  -d, --dist DIST_DIR     : Specify the directory to store the wheel file"
        echo "  --force-reinstall       : Force reinstallation"
        echo "  --nvp_model             : Set NVP model. default: 0"
        exit 0;;
    --nvp_model)
        # on Xavier NX, use -m 2 instead (15W 6-core mode)
        INSTALL_NVP_MODEL=2
        shift;;
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
    -vc=*|--cusparselt-ver=*)
        INSTALL_CUSPARSELT_VERSION=${1#*=}
        shift;;
    -vc|--cusparselt-ver)
        shift
        INSTALL_CUSPARSELT_VERSION=$1
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
if [ "" == "${INSTALL_CUSPARSELT_VERSION}" ];then
    echo "[WARNING] Since no version was specified, the installation was skipped." >&2
    exit 0
fi
if [[ ${FORCE_REINSTALL} -ne 1 ]]; then
    CURRENT_VER=$(pip show torch | grep Version)
    if [[ "${CURRENT_VER}" =~ "${INSTALL_VER#v}" ]]; then
        echo "[SKIP] pytorch ${CURRENT_VER} is already installed"
        exit 0
    fi
fi

INSTALL_URL=http://github.com/pytorch/pytorch
INSTALL_DIR=${INSTALL_ROOT}/pytorch
RESULT=0
# ========================================
# Setup environment variables
# ========================================
export USE_NCCL=0
export USE_ROCM=OFF
export USE_OPENCV=ON
# skip setting this if you want to enable OpenMPI backend
export USE_DISTRIBUTED=0
export USE_QNNPACK=0
export USE_PYTORCH_QNNPACK=0
# "7.2;8.7" for JetPack 5 wheels for Xavier/Orin
export TORCH_CUDA_ARCH_LIST="7.2;8.7"
export PYTORCH_BUILD_VERSION=${INSTALL_VER#v}
export PYTORCH_BUILD_NUMBER=1
export _GLIBCXX_USE_CXX11_ABI=1
# ========================================
function copy_cuSPARSELt() {
    # cuSPARSELt license: https://docs.nvidia.com/cuda/cusparselt/license.html
    local INSTALL_CUSPARSELT_VERSION=${1:-0.7.0.0}
    local INSTALL_CUSPARSELT_TARGET_DIR=tmp_cusparselt
    local ARCH_PATH=${TARGET_ARCH:-$(uname -m)}
    local CUSPARSELT_NAME="libcusparse_lt-linux-${ARCH_PATH}-${INSTALL_CUSPARSELT_VERSION}-archive"

    rm -rf ${INSTALL_CUSPARSELT_TARGET_DIR}
    mkdir -p ${INSTALL_CUSPARSELT_TARGET_DIR}
    pushd "${INSTALL_CUSPARSELT_TARGET_DIR}" >/dev/null 2>&1

        curl --retry 3 -OLs https://developer.download.nvidia.com/compute/cusparselt/redist/libcusparse_lt/linux-${ARCH_PATH}/${CUSPARSELT_NAME}.tar.xz
        tar xf ${CUSPARSELT_NAME}.tar.xz
        echo ${CUSPARSELT_NAME}
        sudo cp -a ${CUSPARSELT_NAME}/include/* /usr/local/cuda/include/
        sudo cp -a ${CUSPARSELT_NAME}/lib/* /usr/local/cuda/lib64/
        echo "Installed cuSPARSELt: ${CUSPARSELT_NAME}"

    popd >/dev/null 2>&1
    rm -rf ${INSTALL_CUSPARSELT_TARGET_DIR}
    sudo ldconfig
}

mkdir -p ${INSTALL_ROOT}
pushd "${INSTALL_ROOT}" >/dev/null 2>&1
    copy_cuSPARSELt
    # ========================================
    # Change jetson_clocks and nvpmodel
    # ========================================
    if [ ${INSTALL_NVP_MODEL} -eq 0 ]; then
        echo "Skip setting NVP model"
    else
        echo "Set NVP model to ${INSTALL_NVP_MODEL}"
        sudo nvpmodel -m ${INSTALL_NVP_MODEL}
    fi
    sudo jetson_clocks

    if [ ! -d ${INSTALL_DIR} ]; then
        git clone --recurse-submodules ${INSTALL_URL} ${INSTALL_DIR}
    fi

    pushd "${INSTALL_DIR}" >/dev/null 2>&1
        rm -rf ./dist
        # ========================================
        # Checkout
        # ========================================
        git checkout .
        git checkout ${INSTALL_VER}
        git submodule sync
        git submodule update --init --recursive

        # ========================================
        # Patch
        # ========================================
        sed -i 's/CUSPARSE_COMPUTE_TF32/CUSPARSE_COMPUTE_32F/g' aten/src/ATen/native/sparse/cuda/cuSPARSELtOps.cpp
        sed -i "s/raise ValueError('unknown license')/return('unknown license')/g" third_party/build_bundled.py
        pip install -r requirements.txt
        # ========================================
        # Build PyTorch
        # ========================================
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
    popd >/dev/null 2>&1
popd >/dev/null 2>&1

exit ${RESULT}
