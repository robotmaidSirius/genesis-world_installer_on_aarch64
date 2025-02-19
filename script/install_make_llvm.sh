#!/bin/bash
## BUILD TYPE: make
INSTALL_VER=15.0.5
INSTALL_ROOT=~/genesis
INSTALL_TYPE_TAR=0
JOBS_NUM=$((`nproc` - 1))

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
        echo "Usage: $0 [-v|--ver VERSION] [-p|--root INSTALL_ROOT] [--tar]"
        echo "  -v, --ver VERSION       : Specify the version to install"
        echo "  -p, --root INSTALL_ROOT : Specify the root directory to install"
        echo "  --tar                   : Use tarball to install"
        exit 0;;
    --force-reinstall)
        echo "[MESS] force reinstall"
        FORCE_REINSTALL=1
        shift;;
    --tar)
        INSTALL_TYPE_TAR=1
        shift;;
    -j=*)
        JOBS_NUM=${1#*=}
        shift;;
    -j)
        shift
        JOBS_NUM=$1
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
    CURRENT_VER=$(clang --version | grep version)
    if [[ "${CURRENT_VER}" =~ "${INSTALL_VER}" ]]; then
        echo "[SKIP] ${CURRENT_VER} is already installed"
        exit 0
    fi

    CURRENT_VER=$(clang++ --version | grep version)
    if [[ "${CURRENT_VER}" =~ "${INSTALL_VER}" ]]; then
        echo "[SKIP] ${CURRENT_VER} is already installed"
        exit 0
    fi
fi

INSTALL_URL=https://github.com/llvm/llvm-project.git
RESULT=0
# ========================================
INSTALL_ROOT=${INSTALL_ROOT}/llvm

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
        pushd "${INSTALL_DIR}" >/dev/null 2>&1
            git checkout .
            git checkout llvmorg-${INSTALL_VER}
        popd >/dev/null 2>&1
    fi
    mkdir -p ${INSTALL_ROOT}/llvm_build
    pushd "${INSTALL_ROOT}/llvm_build" >/dev/null 2>&1
        # BUILD LLVM
        cmake -G Ninja ${INSTALL_DIR}/llvm \
                -D BUILD_SHARED_LIBS:BOOL=OFF \
                -D CMAKE_BUILD_TYPE=Release \
                -D LLVM_TARGETS_TO_BUILD="AArch64;ARM;NVPTX" \
                -D LLVM_ENABLE_ASSERTIONS=ON \
                -D LLVM_ENABLE_RTTI=ON \
                -D LLVM_ENABLE_TERMINFO=OFF \
                -D LLVM_ENABLE_PROJECTS="clang;clang-tools-extra;lld;lldb;compiler-rt;" \
                -D CMAKE_INSTALL_PREFIX="/usr/local" \
                -D CMAKE_C_COMPILER=aarch64-linux-gnu-gcc \
                -D CMAKE_CXX_COMPILER=aarch64-linux-gnu-g++ \
                -D CMAKE_SYSTEM_PROCESSOR=aarch64 \
                -D CMAKE_C_FLAGS=-march=armv8-a \
                -D CMAKE_CXX_FLAGS=-march=armv8-a \
                -D OPENMP_ENABLE_LIBOMPTARGET=ON
        RESULT=$?

        if [ ${RESULT} -eq 0 ]; then
            ninja -j ${JOBS_NUM}
            RESULT=$?
        fi
        if [ ${RESULT} -eq 0 ]; then
            sudo ninja install
            RESULT=$?
        fi
    popd >/dev/null 2>&1
popd >/dev/null 2>&1

if [ ${RESULT} -eq 0 ]; then
    # Check your LLVM installation
    ## You should get 15.0.5
    echo "llvm-config: "$(llvm-config --version)
    clang --version
    clang --print-targets
    #clang++ --version
    #clang++ --print-targets
fi

exit ${RESULT}
