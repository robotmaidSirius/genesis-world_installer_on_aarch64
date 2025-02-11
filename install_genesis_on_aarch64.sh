#!/bin/bash
SCRIPT_DIR=$(cd $(dirname $0); pwd)/script
CONFIG_FILE=$(cd $(dirname $0); pwd)/config.json
RESULT=0
export MAX_JOBS=$((`nproc` - 1))

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
        echo "Usage: $0 -j|--jobs [jobs] -f|--config [config.json]"
        exit 0;;
    -j=*)
        MAX_JOBS=${1#*=}
        shift;;
    -j)
        shift
        MAX_JOBS=$1
        shift;;
    -f=*|--config=*)
        CONFIG_FILE=${1#*=}
        shift;;
    -f|--config)
        shift
        CONFIG_FILE=$1
        shift;;
    *) echo "Unknown parameter passed: $1"; shift;;
  esac
done
CONFIG_FILE=$(readlink -f ${CONFIG_FILE})
# ========================================

## apt管理のインストール
bash ${SCRIPT_DIR}/install_apt.sh ${SCRIPT_DIR}/requirements_apt.txt

# 環境設定の取得
if [ -f "${CONFIG_FILE}" ]; then
  # config.jsonからインストールするパッケージを取得
  INSTALL_ROOT=$(eval echo $(jq -r '.install_path' ${CONFIG_FILE}));
  PYTHON_VERSION=$(eval echo $(jq -r '.python_version' ${CONFIG_FILE}));
  ENV_NAME=$(eval echo $(jq -r '.venv_name' ${CONFIG_FILE}));

else
  RESULT=1
  echo "config.jsonが存在しません"
fi

if [ ${RESULT} -eq 0 ]; then
  ## pyenvのインストール
  bash ${SCRIPT_DIR}/install_pyenv.sh -v=${PYTHON_VERSION}

  mkdir -p ${INSTALL_ROOT}
  # 環境変数を設定
  pushd "${INSTALL_ROOT}" >/dev/null 2>&1
  pyenv local ${PYTHON_VERSION}
  if [ ! -d "${ENV_NAME}" ]; then
    python -m venv ${ENV_NAME}
  fi
  source ${ENV_NAME}/bin/activate
    ## ========================================
    # pip管理のインストール処理
    python -m pip install --upgrade pip
    # pip requirements.txtのインストール
    pip install -r ${SCRIPT_DIR}/requirements.txt

    ## ========================================
    ## Install: cmake
    bash ${SCRIPT_DIR}/install_cmake.sh -v=3.21.3 -p=${INSTALL_ROOT}
    ## Install: LLVM
    bash ${SCRIPT_DIR}/install_llvm.sh -v=15.0.5 -p=${INSTALL_ROOT} --tar
    ## Install: CoACD
    bash ${SCRIPT_DIR}/install_CoACD.sh -v=1.0.1 -p=${INSTALL_ROOT}
    ## Install: VTK
    bash ${SCRIPT_DIR}/install_vtk.sh -v=9.4.1 -p=${INSTALL_ROOT}

    ## ========================================
    ## Install: taichi
    bash ${SCRIPT_DIR}/install_taichi.sh -v=v1.7.3 -p=${INSTALL_ROOT}
    ## Install: libigl
    bash ${SCRIPT_DIR}/install_libigl.sh -v=2.4.1 -p=${INSTALL_ROOT}
    ## Install: PyMeshLab
    bash ${SCRIPT_DIR}/install_PyMeshLab.sh -v=v2023.12.post2 -p=${INSTALL_ROOT}
    ## Install: tetgen
    bash ${SCRIPT_DIR}/install_tetgen.sh -v=v0.6.4 -p=${INSTALL_ROOT}

    ## Install: genesis-world
    bash ${SCRIPT_DIR}/install_genesis.sh -v=v0.2.1 -p=${INSTALL_ROOT}

    ## ========================================
    ## Create script
    bash ${SCRIPT_DIR}/create_script.sh --env_name=${ENV_NAME}

  popd >/dev/null 2>&1

  ## バージョン情報の表示
  bash ${SCRIPT_DIR}/print_ver.sh

  deactivate
fi
