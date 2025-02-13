#!/bin/bash
SCRIPT_DIR=$(cd $(dirname $(realpath "${BASH_SOURCE:-0}")); pwd)/script
CONFIG_FILE=$(cd $(dirname $(realpath "${BASH_SOURCE:-0}")); pwd)/config.json
RESULT=0
export MAX_JOBS=$((`nproc` - 1))
if [[ ${MAX_JOBS} -le 0 ]]; then
  export MAX_JOBS=1
fi

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
function get_jq_value() {
  local key=${1}
  local value=$(eval echo $(jq -r '.'${key} ${CONFIG_FILE}));
  if [ "null" == "${value}" ];then
    value=""
  fi
  echo ${value}
}
function flag_jq_value() {
  local key=${1}
  local value=$(eval echo $(jq -r '.'${key} ${CONFIG_FILE}));
  if [ true == "${value}" ];then
    value=1
  else
    value=0
  fi
  echo ${value}
}
# ========================================
echo -e "####################\n $0\n####################"
sudo apt install -y jq fzf

# TODO: ここで使用するデバイスの情報を確認する


# TODO: カスタムインストールするか確認する

# 環境設定の取得
if [ -f "${CONFIG_FILE}" ]; then
  # config.jsonからインストールするパッケージを取得
  INSTALL_ROOT=$(eval echo $(get_jq_value 'install_path'));
  PYTHON_VERSION=$(get_jq_value "packages.version.python");
  ENV_NAME=$(get_jq_value "venv_name");
  SKIP_APT=$(flag_jq_value "skip_apt");
  SKIP_PIP=$(flag_jq_value "skip_pip");
  INSTALL_PYENV=$(flag_jq_value "pyenv.install");

else
  RESULT=1
  echo "config.jsonが存在しません"
  # TODO: config.jsonが無い場合は、デフォルトを生成して実施する？
  exit 0
fi

## apt管理のインストール
if [ ${SKIP_APT} -ne 1 ]; then
  echo -e "\n==============\n# Install: apt\n=============="
  bash ${SCRIPT_DIR}/install_apt.sh ${SCRIPT_DIR}/requirements_apt.txt
  RESULT=$?
  if [ ${RESULT} -ne 0 ]; then
    echo "[ERROR] Install 'apt requirements_apt.txt' is failed" >&2
    exit 0
  fi
fi

if [ ${RESULT} -eq 0 ]; then
  mkdir -p ${INSTALL_ROOT}
  # 環境変数を設定
  pushd "${INSTALL_ROOT}" >/dev/null 2>&1
  # pyenvの設定
  export PYENV_ROOT=$(eval echo $(get_jq_value "pyenv.path"))
  export PATH="${PYENV_ROOT}/bin:$PATH"
  eval "$(pyenv init -)"
  PYENV_VERSION=$(pyenv --version)
  if [ "command not found" == "${PYENV_VERSION}" ]; then
    if [ ${INSTALL_PYENV} -eq 1 ]; then
      ## pyenvのインストール
      echo -e "\n==============\n# Install: pyenv\n=============="
      bash ${SCRIPT_DIR}/setup_pyenv.sh --python_version=$(get_jq_value "packages.version.python") -p=${PYENV_ROOT}
      RESULT=$?
    else
      RESULT=1
    fi
    if [ ${RESULT} -ne 0 ]; then
      echo "[ERROR] Install 'pyenv' is failed" >&2
      exit 0
    fi
  fi

  pyenv local ${PYTHON_VERSION}
  if [ "" != ${ENV_NAME} ];then
    echo -e "\n==============\n# Set venv :${ENV_NAME}\n=============="
    if [ ! -d "${ENV_NAME}" ]; then
      python -m venv ${ENV_NAME}
    fi
    source ${ENV_NAME}/bin/activate
    echo "pyenv versions"
    pyenv versions
    if [ ! -e ${ENV_NAME}/bin/activate ]; then
      echo "[ERROR] Not found 'activate' script" >&2
      exit 0
    fi
  fi
    ## ========================================
    # pip管理のインストール処理
    python -m pip install --upgrade pip
    # pip requirements.txtのインストール
    if [ ${SKIP_PIP} -ne 1 ]; then
      echo -e "\n==============\n# pip requirements.txt\n=============="
      pip install -r ${SCRIPT_DIR}/requirements.txt
      RESULT=$?
      if [ ${RESULT} -ne 0 ]; then
        echo "[ERROR] Install 'pip requirements.txt' is failed" >&2
        exit 0
      fi
    fi

    ## ========================================
    ## Install: cmake
    echo -e "\n==============\n# Install: cmake\n=============="
    bash ${SCRIPT_DIR}/install_cmake.sh -v=$(get_jq_value "packages.version.cmake") -p=${INSTALL_ROOT}
    RESULT=$?
    if [ ${RESULT} -ne 0 ]; then
      echo "[ERROR] Install 'cmake' is failed." >&2
      exit 0
    fi
    ## Install: LLVM
    echo -e "\n==============\n# Install: LLVM\n=============="
    bash ${SCRIPT_DIR}/install_llvm.sh -v=$(get_jq_value "packages.version.llvm") -p=${INSTALL_ROOT} --tar
    RESULT=$?
    if [ ${RESULT} -ne 0 ]; then
      echo "[ERROR] Install 'LLVM' is failed." >&2
      exit 0
    fi
    ## Install: CoACD
    echo -e "\n==============\n# Install: CoACD\n=============="
    bash ${SCRIPT_DIR}/install_CoACD.sh -v=$(get_jq_value "packages.version.CoACD") -p=${INSTALL_ROOT}
    RESULT=$?
    if [ ${RESULT} -ne 0 ]; then
      echo "[ERROR] Install 'install_CoACD' is failed." >&2
      exit 0
    fi
    ## Install: VTK
    echo -e "\n==============\n# Install: VTK\n=============="
    bash ${SCRIPT_DIR}/install_vtk.sh -v=$(get_jq_value "packages.version.vtk") -p=${INSTALL_ROOT}
    RESULT=$?
    if [ ${RESULT} -ne 0 ]; then
      echo "[ERROR] Install 'VTK' is failed." >&2
      exit 0
    fi

    ## ========================================
    ## Install: taichi
    echo -e "\n==============\n# Install: taichi\n=============="
    bash ${SCRIPT_DIR}/install_taichi.sh -v=$(get_jq_value "packages.version.taichi") -p=${INSTALL_ROOT} --apply_patch
    RESULT=$?
    if [ ${RESULT} -ne 0 ]; then
      echo "[ERROR] Install 'taichi' is failed." >&2
      exit 0
    fi
    ## Install: libigl
    echo -e "\n==============\n# Install: libigl\n=============="
    bash ${SCRIPT_DIR}/install_libigl.sh -v=$(get_jq_value "packages.version.libigl") -p=${INSTALL_ROOT}
    RESULT=$?
    if [ ${RESULT} -ne 0 ]; then
      echo "[ERROR] Install 'libigl' is failed." >&2
      exit 0
    fi
    ## Install: PyMeshLab
    echo -e "\n==============\n# Install: PyMeshLab\n=============="
    bash ${SCRIPT_DIR}/install_PyMeshLab.sh -v=$(get_jq_value "packages.version.PyMeshLab") -p=${INSTALL_ROOT}
    RESULT=$?
    if [ ${RESULT} -ne 0 ]; then
      echo "[ERROR] Install 'PyMeshLab' is failed." >&2
      exit 0
    fi
    ## Install: tetgen
    echo -e "\n==============\n# Install: tetgen\n=============="
    bash ${SCRIPT_DIR}/install_tetgen.sh -v=$(get_jq_value "packages.version.tetgen") -p=${INSTALL_ROOT}
    RESULT=$?
    if [ ${RESULT} -ne 0 ]; then
      echo "[ERROR] Install 'tetgen' is failed." >&2
      exit 0
    fi

    ## Install: genesis-world
    echo -e "\n==============\n# Install: genesis-world\n=============="
    bash ${SCRIPT_DIR}/install_genesis.sh -v=$(get_jq_value "packages.version.genesis") -p=${INSTALL_ROOT}
    RESULT=$?
    if [ ${RESULT} -ne 0 ]; then
      echo "[ERROR] Install 'genesis' is failed." >&2
      exit 0
    fi

    ## ========================================
    ## Create script
    echo -e "\n==============\n# Create script\n=============="
    bash ${SCRIPT_DIR}/create_script.sh --env_name=${ENV_NAME} --pyenv_dir=$(eval echo $(get_jq_value "pyenv.path"))
    RESULT=$?
    if [ ${RESULT} -ne 0 ]; then
      echo "[ERROR] Create script is failed." >&2
      exit 0
    fi

  popd >/dev/null 2>&1

  ## バージョン情報の表示
  bash ${SCRIPT_DIR}/print_ver.sh

  if [ "" != ${ENV_NAME} ];then
    deactivate
  fi

  echo Install path : ${INSTALL_ROOT}
fi
