#!/bin/bash
## BUILD TYPE: python bdist_wheel
INSTALL_VER=v0.6.4
INSTALL_ROOT=~/genesis
DIST_DIR=$(cd $(dirname $(realpath "${BASH_SOURCE:-0}")); pwd)/dist
FORCE_REINSTALL=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
        echo "Usage: $0 [-v|--ver VERSION] [-p|--root INSTALL_ROOT] [-d|--dist DIST_DIR] [--force-reinstall]"
        echo "  -v, --ver VERSION       : Specify the version to install"
        echo "  -p, --root INSTALL_ROOT : Specify the root directory to install"
        echo "  -d, --dist DIST_DIR     : Specify the directory to store the wheel file"
        echo "  --force-reinstall       : Force reinstallation"
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
python -m pip install --upgrade tetgen==${INSTALL_VER#v}
if [[ ${FORCE_REINSTALL} -ne 1 ]]; then
    CURRENT_VER=$(pip show tetgen | grep Version)
    if [[ "${CURRENT_VER}" =~ "${INSTALL_VER#v}" ]]; then
        echo "[SKIP] tetgen ${CURRENT_VER} is already installed"
        exit 0
    fi
fi

INSTALL_URL=https://github.com/pyvista/tetgen.git
INSTALL_DIR=${INSTALL_ROOT}/tetgen
RESULT=0
# ========================================

mkdir -p ${INSTALL_ROOT}
pushd "${INSTALL_ROOT}" >/dev/null 2>&1
    if [ ! -d ${INSTALL_DIR} ]; then
        git clone --recurse-submodules ${INSTALL_URL} ${INSTALL_DIR}
    fi

    pushd "${INSTALL_DIR}" >/dev/null 2>&1
        rm -rf ./dist
        git checkout ${INSTALL_VER}
        if [ -e "requirements.txt" ]; then
            pip install --no-cache -r requirements.txt
        fi
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
