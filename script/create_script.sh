#!/bin/bash
## TODO: --tar オプションが未検証
INSTALL_VER=0.0.1
INSTALL_ROOT=~/genesis
INSTALL_TYPE_TAR=0
ENV_NAME=venv_genesis

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
    *) echo "Unknown parameter passed: $1"; shift;;
  esac
done
RESULT=0
# ========================================
CREATE_SCRIPT_ACTIVATE=${INSTALL_ROOT}/activate.sh

echo '#!/bin/bash' > ${CREATE_SCRIPT_ACTIVATE}
echo '## Ver.'${INSTALL_VER} >> ${CREATE_SCRIPT_ACTIVATE}
echo '' >> ${CREATE_SCRIPT_ACTIVATE}
echo 'source '${ENV_NAME}'/bin/activate' >> ${CREATE_SCRIPT_ACTIVATE}
chmod u+x ${CREATE_SCRIPT_ACTIVATE}
# ========================================
CREATE_SCRIPT_DEACTIVATE=${INSTALL_ROOT}/deactivate.sh

echo '#!/bin/bash' > ${CREATE_SCRIPT_DEACTIVATE}
echo '## Ver.'${INSTALL_VER} >> ${CREATE_SCRIPT_DEACTIVATE}
echo '' >> ${CREATE_SCRIPT_DEACTIVATE}
echo 'deactivate' >> ${CREATE_SCRIPT_DEACTIVATE}
chmod u+x ${CREATE_SCRIPT_DEACTIVATE}
# ========================================
exit ${RESULT}
