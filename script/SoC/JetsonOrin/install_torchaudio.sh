#!/bin/bash
## TODO: Installation is unverified
INSTALL_VER=12.1
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
    *) echo "[WARNING] Unknown parameter passed: $1" >&2; shift;;
  esac
done
# ========================================

mkdir -p ${INSTALL_ROOT}
pushd "${INSTALL_ROOT}" >/dev/null 2>&1

popd >/dev/null 2>&1
exit ${RESULT}

