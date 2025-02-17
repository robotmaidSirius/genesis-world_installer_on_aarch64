#!/bin/bash
## TODO: インストールできるか未検証
# Reference:
## https://docs.nvidia.com/deeplearning/frameworks/install-pytorch-jetson-platform/index.html

# export TORCH_INSTALL=https://developer.download.nvidia.com/compute/redist/jp/v511/pytorch/torch-2.0.0a0+fe05266f.nv23.04-cp38-cp38-linux_aarch64.whl
# python3 -m pip install --upgrade pip; python3 -m pip install numpy; python3 -m pip install --no-cache $TORCH_INSTALL;echo ${TORCH_INSTALL}
# export TORCH_INSTALL=https://developer.download.nvidia.com/compute/redist/jp/v511/tensorflow/tensorflow-2.12.0+nv23.05-cp38-cp38-linux_aarch64.whl
# python3 -m pip install --upgrade pip; python3 -m pip install numpy; python3 -m pip install --no-cache $TORCH_INSTALL;echo ${TORCH_INSTALL}


PERSONAL_VENV_NAME=genesis
INSTALL_VER=12.1
INSTALL_ROOT=~/genesis

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
        echo "Usage: $0 -vn|--venv_name [venv_name] -v|--ver [version] -p|--root [root]"
        exit 0;;
    -vn=*|--venv_name=*)
        PERSONAL_VENV_NAME=${1#*=}
        shift;;
    -vn|--venv_name)
        shift
        PERSONAL_VENV_NAME=$1
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
    *) echo "[WARNING] Unknown parameter passed: $1" >&2; shift;;
  esac
done
# ========================================

# https://docs.nvidia.com/deeplearning/frameworks/install-pytorch-jetson-platform-release-notes/pytorch-jetson-rel.html#pytorch-jetson-rel
JP_VERSION=61
PYT_VERSION=torch-2.5.0a0+872d972e41.nv24.08.17622132-cp310-cp310-linux_aarch64

## Change venv
mkdir -p ${INSTALL_ROOT}
if [ ! -d "${INSTALL_ROOT}/${PERSONAL_VENV_NAME}" ]; then
    python -m venv ${INSTALL_ROOT}/${PERSONAL_VENV_NAME}
fi
source ${PERSONAL_VENV_NAME}/bin/activate

# Install PyTorch
pushd "${INSTALL_ROOT}" >/dev/null 2>&1
    INSTALL_DIR=${INSTALL_ROOT}/jetson/pytorch
    mkdir -p ${INSTALL_DIR}
pushd "${INSTALL_DIR}" >/dev/null 2>&1
    # Prerequisites and Installation
    ## Install system packages required by PyTorch
    sudo apt-get -y update
    sudo apt-get install -y python-pip libopenblas-dev
    # sudo apt-get install -y libopenblas-base libopenmpi-dev libomp-dev

    wget raw.githubusercontent.com/pytorch/pytorch/5c6af2b583709f6176898c017424dc9981023c28/.ci/docker/common/install_cusparselt.sh
    export CUDA_VERSION=${INSTALL_VER}
    bash ./install_cusparselt.sh

    ## install PyTorch
    export TORCH_URL=https://developer.download.nvidia.com/compute/redist/jp/v$JP_VERSION/pytorch/$PYT_VERSION.whl
    wget ${TORCH_URL} -O $PYT_VERSION.whl
    python -m pip install --upgrade pip
    python -m pip install numpy==’1.26.1’
    python -m pip install --no-cache ./$PYT_VERSION.whl



    pip3 install Cython
    pip3 install numpy torch-${INSTALL_VER}-cp36-cp36m-linux_aarch64.whl


popd >/dev/null 2>&1
popd >/dev/null 2>&1

# Deactivate venv
deactivate
exit ${RESULT}
