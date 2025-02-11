#!/bin/bash
## TODO: --tar オプションが未検証
INSTALL_VER=3.31.5
INSTALL_ROOT=~/genesis
INSTALL_TYPE_TAR=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
        echo "Usage: $0 -v|--ver [version] -p|--root [path] --tar"
        exit 0;;
    --tar)
        INSTALL_TYPE_TAR=1
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
RESULT=0
# ========================================

if [ ${INSTALL_TYPE_TAR} -eq 1 ]; then
    mkdir -p ${INSTALL_ROOT}
    pushd "${INSTALL_ROOT}" >/dev/null 2>&1
        INSTALL_DIR=${INSTALL_ROOT}/cmake-${INSTALL_VER}
        if [ ! -d ${INSTALL_DIR} ]; then
            wget https://github.com/Kitware/CMake/releases/download/v${INSTALL_VER}/cmake-${INSTALL_VER}.tar.gz
            tar zxf cmake-${INSTALL_VER}.tar.gz
            rm cmake-${INSTALL_VER}.tar.gz
        fi
        pushd "${INSTALL_DIR}" >/dev/null 2>&1
            ./bootstrap
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
else
    sudo apt install curl gnupg lsb-release

    # Add Kitware repository
    echo 'deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ '$(lsb_release -cs)' main' | sudo tee /etc/apt/sources.list.d/kitware.list >/dev/null
    # Register Kitware GPG key
    wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | sudo tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null

    # Update and check the package information
    sudo apt update

    # インストールとバージョン確認
    sudo apt install -y cmake
    RESULT=$?
fi

#cmake --version

exit ${RESULT}
