#!/bin/bash
INSTALL_VER=0.0.2
INSTALL_ROOT=~/genesis
INSTALL_TYPE_TAR=0
ENV_NAME=venv_genesis
INSTALL_PYENV_DIR=${HOME}/.pyenv

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
        echo "Usage: $0 -p|--root [path]"
        exit 0;;
    -n=*|--env_name=*)
        ENV_NAME=${1#*=}
        shift;;
    -n|--env_name)
        shift
        ENV_NAME=$1
        shift;;
    -p=*|--pyenv_dir=*)
        if [ "" != "${1#*=}" ];then
            INSTALL_PYENV_DIR=${1#*=}
        fi
        shift;;
    -p|--pyenv_dir)
        shift
        if [ "" != "$1" ];then
            INSTALL_PYENV_DIR=$1
        fi
        shift;;
    *) echo "Unknown parameter passed: $1"; shift;;
  esac
done
if [ "" == "${ENV_NAME}" ];then
    echo "[ERROR] Please specify '--env_name'" >&2
    exit 1
fi
RESULT=0
# ========================================
CREATE_SCRIPT_ACTIVATE=${INSTALL_ROOT}/activate.sh

echo '#!/bin/bash' > ${CREATE_SCRIPT_ACTIVATE}
echo '## Ver.'${INSTALL_VER} >> ${CREATE_SCRIPT_ACTIVATE}
echo '' >> ${CREATE_SCRIPT_ACTIVATE}
echo 'export PYENV_ROOT="'${INSTALL_PYENV_DIR}'"' >> ${CREATE_SCRIPT_ACTIVATE}
echo 'export PATH="${PYENV_ROOT}/bin:$PATH"' >> ${CREATE_SCRIPT_ACTIVATE}
echo 'eval "$(pyenv init -)"' >> ${CREATE_SCRIPT_ACTIVATE}
echo 'source '${ENV_NAME}'/bin/activate' >> ${CREATE_SCRIPT_ACTIVATE}
echo 'history -s source '${ENV_NAME}'/bin/activate' >> ${CREATE_SCRIPT_ACTIVATE}
chmod u+x ${CREATE_SCRIPT_ACTIVATE}
# ========================================
CREATE_SCRIPT_DEACTIVATE=${INSTALL_ROOT}/exit_venv.sh

echo '#!/bin/bash' > ${CREATE_SCRIPT_DEACTIVATE}
echo '## Ver.'${INSTALL_VER} >> ${CREATE_SCRIPT_DEACTIVATE}
echo '' >> ${CREATE_SCRIPT_DEACTIVATE}
echo 'export PYENV_ROOT="'${INSTALL_PYENV_DIR}'"' >> ${CREATE_SCRIPT_ACTIVATE}
echo 'export PATH="${PYENV_ROOT}/bin:$PATH"' >> ${CREATE_SCRIPT_ACTIVATE}
echo 'eval "$(pyenv init -)"' >> ${CREATE_SCRIPT_ACTIVATE}
echo 'history -s deactivate' >> ${CREATE_SCRIPT_DEACTIVATE}
echo 'deactivate' >> ${CREATE_SCRIPT_DEACTIVATE}
chmod u+x ${CREATE_SCRIPT_DEACTIVATE}
# ========================================
exit ${RESULT}
