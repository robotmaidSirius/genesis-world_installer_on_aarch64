#!/bin/bash
## TODO: インストールできるか未検証
# Reference:
## https://docs.nvidia.com/deeplearning/frameworks/install-pytorch-jetson-platform/index.html
## https://forums.developer.nvidia.com/t/pytorch-for-jetson/72048
### 'Build from Source'

INSTALL_VER=v2.1.0
INSTALL_NVP_MODEL=0
INSTALL_ROOT=~/genesis

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
        echo "Usage: $0 -vn|--venv_name [venv_name] -v|--ver [version] -p|--root [root]"
        exit 0;;
    --max_power)
        # on Xavier NX, use -m 2 instead (15W 6-core mode)
        INSTALL_NVP_MODEL=2
        shift;;
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
CURRENT_VER=$(pip show torch | grep Version)
if [[ "${CURRENT_VER}" =~ "${INSTALL_VER#v}" ]]; then
    echo "[SKIP] pytorch ${CURRENT_VER} is already installed"
    exit 0
fi

INSTALL_URL=http://github.com/pytorch/pytorch
INSTALL_DIR=${INSTALL_ROOT}/pytorch
RESULT=0
# ========================================

mkdir -p ${INSTALL_ROOT}
pushd "${INSTALL_ROOT}" >/dev/null 2>&1
    if [ ! -d ${INSTALL_DIR} ]; then
        git clone --recurse-submodules ${INSTALL_URL} ${INSTALL_DIR}
    fi

    pushd "${INSTALL_DIR}" >/dev/null 2>&1
        git checkout ${INSTALL_VER}
        git submodule update --init --recursive
        # ========================================
        # Setup environment variables
        # ========================================
        export USE_NCCL=0
        # skip setting this if you want to enable OpenMPI backend
        export USE_DISTRIBUTED=0
        export USE_QNNPACK=0
        export USE_PYTORCH_QNNPACK=0
        # "7.2;8.7" for JetPack 5 wheels for Xavier/Orin
        export TORCH_CUDA_ARCH_LIST="7.2;8.7"
        export PYTORCH_BUILD_VERSION=${INSTALL_VER#v}
        export PYTORCH_BUILD_NUMBER=1

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
        # ========================================
        # Build PyTorch
        # ========================================
        python setup.py bdist_wheel

        RESULT=$?
    popd >/dev/null 2>&1
popd >/dev/null 2>&1

exit ${RESULT}
