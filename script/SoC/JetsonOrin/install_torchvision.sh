#!/bin/bash
## TODO: インストールできるか未検証
INSTALL_VER=v0.21.0
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
# ========================================

mkdir -p ${INSTALL_ROOT}
pushd "${INSTALL_ROOT}" >/dev/null 2>&1
    # https://forums.developer.nvidia.com/t/pytorch-for-jetson/72048

    sudo apt-get install libjpeg-dev zlib1g-dev libpython3-dev libopenblas-dev libavcodec-dev libavformat-dev libswscale-dev
    git clone --branch ${INSTALL_VER} https://github.com/pytorch/vision torchvision
    cd torchvision
    export BUILD_VERSION=${INSTALL_VER}
    python setup.py install
    #cd ../
    #pip install 'pillow<7'
popd >/dev/null 2>&1

exit ${RESULT}
