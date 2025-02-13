#!/bin/bash
TARGET_PYTHON_VERSION=3.11.11
INSTALL_DIR=${HOME}/.pyenv
INSTALL_ADD_BASHRC=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
        echo "Usage: $0 -v|--ver [version] -p|--root [path]"
        exit 0;;
    --write_bashrc)
        INSTALL_ADD_BASHRC=1
        shift;;
    -v=*|--python_version=*)
        TARGET_PYTHON_VERSION=${1#*=}
        shift;;
    -v|--python_version)
        shift
        TARGET_PYTHON_VERSION=$1
        shift;;
    -p=*|--root=*)
        if [ "" != "${1#*=}" ];then
            INSTALL_DIR=${1#*=}
        fi
        shift;;
    -p|--root)
        shift
        if [ "" != "$1" ];then
            INSTALL_DIR=$1
        fi
        shift;;
    *) echo "Unknown parameter passed: $1"; shift;;
  esac
done
RESULT=0
# ========================================
function install_pyenv_python() {
  local version=${1}
  local ret=0
  if [ "" != "${version}" ];then
    cd ~
    # TODO: インストールが失敗した場合の処理を追加する
    pyenv install ${version}
    ret=$?
    if [ ! -e "~/.python-version" ];then
      pyenv global ${version}
    fi
  fi
  if [[ ${ret} -eq 0 ]];then
    # pipのバージョンをを上げる
    python -m pip install --upgrade pip

    # Version確認
    #pyenv versions
    #python --version
  fi
}
# ========================================

if [ -d "${INSTALL_DIR}" ]; then
  if [ -d "${INSTALL_DIR}/plugins/pyenv-update" ]; then
    pyenv update
  fi
  pyenv update
  echo "pyenvは既にインストールされています"
  install_python ${TARGET_PYTHON_VERSION}
  exit 0
fi

sudo apt install -y \
  libffi-dev libsqlite3-dev zlib1g-dev libbz2-dev libreadline-dev \
  libssl-dev libncursesw5-dev xz-utils tk-dev liblzma-dev \
  libgdbm-dev libnss3-dev

# TODO: すでに登録されているなら、追加しない
# リポジトリのクローンと環境変数の設定
git clone https://github.com/pyenv/pyenv.git ${INSTALL_DIR}

if [ ${INSTALL_ADD_BASHRC} -ne 0 ];then
  echo 'export PYENV_ROOT="'${INSTALL_DIR}'"' >> ~/.bashrc
  echo 'export PATH="${PYENV_ROOT}/bin:$PATH"' >> ~/.bashrc
  echo 'eval "$(pyenv init -)"' >> ~/.bashrc
  source ~/.bashrc
fi
export PYENV_ROOT="${INSTALL_DIR}"
export PATH="${PYENV_ROOT}/bin:$PATH"
eval "$(pyenv init -)"

# pyenvのupdateプラグインをインストール
git clone https://github.com/pyenv/pyenv-update.git ${INSTALL_DIR}/plugins/pyenv-update

# Pythonのインストール
install_pyenv_python ${TARGET_PYTHON_VERSION}
RESULT=$?

if [[ ${RESULT} -eq 0 ]];then
    echo -e "\nSuccessfully installed pyenv"
else
    echo "\nFailed to install pyenv"
fi
