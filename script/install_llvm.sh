#!/bin/bash
INSTALL_VER=15.0.5
INSTALL_ROOT=~/genesis
INSTALL_TYPE_TAR=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
        echo "Usage: $0 --tar -v|--ver [version] -p|--root [path]"
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
RESULT=0
# ========================================

mkdir -p ${INSTALL_ROOT}
pushd "${INSTALL_ROOT}" >/dev/null 2>&1
    if [ ${INSTALL_TYPE_TAR} -eq 1 ]; then
        INSTALL_DIR="${INSTALL_ROOT}/llvm-project-llvmorg-${INSTALL_VER}"
        if [ ! -d ${INSTALL_DIR} ]; then
            wget https://github.com/llvm/llvm-project/archive/refs/tags/llvmorg-${INSTALL_VER}.tar.gz
            tar zxf llvmorg-${INSTALL_VER}.tar.gz
            rm llvmorg-${INSTALL_VER}.tar.gz
        fi
    else
        INSTALL_DIR="${INSTALL_ROOT}/llvm-project"
        if [ ! -d ${INSTALL_DIR} ]; then
            git clone --recurse-submodules ${INSTALL_URL} ${INSTALL_DIR}
        fi
        git checkout llvmorg-${INSTALL_VER}
    fi
    mkdir -p ${INSTALL_DIR}/llvm/build
    pushd "${INSTALL_DIR}/llvm/build" >/dev/null 2>&1
        # BUILD LLVM
        cmake .. -DBUILD_SHARED_LIBS:BOOL=OFF \
                -DCMAKE_BUILD_TYPE=Release \
                -DLLVM_TARGETS_TO_BUILD='AArch64;ARM;NVPTX' \
                -DLLVM_ENABLE_ASSERTIONS=ON \
                -DLLVM_ENABLE_RTTI=ON \
                -DLLVM_ENABLE_TERMINFO=OFF \
                -DLLVM_ENABLE_PROJECTS='clang;clang-tools-extra;lld;lldb;' \
                -DCMAKE_INSTALL_PREFIX='/usr/local'
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

if [ ${RESULT} -eq 0 ]; then
    # Check your LLVM installation
    ## You should get 15.0.5
    llvm-config --version
    clang --version
    clang++ --version

    # ビルドターゲットを確認する
    clang --print-targets
fi

exit ${RESULT}
