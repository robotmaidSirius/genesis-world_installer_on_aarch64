#!/bin/bash
TARGET_PYTHON_VERSION=3.11.11
INSTALL_DIR=${HOME}/.pyenv

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
        echo "Usage: $0 -v|--ver [version] -p|--root [path]"
        exit 0;;
    -v=*|--ver=*)
        TARGET_PYTHON_VERSION=${1#*=}
        shift;;
    -v|--ver)
        shift
        TARGET_PYTHON_VERSION=$1
        shift;;
    -p=*|--root=*)
        INSTALL_DIR=${1#*=}
        shift;;
    -p|--root)
        shift
        INSTALL_DIR=$1
        shift;;
    *) echo "Unknown parameter passed: $1"; shift;;
  esac
done
RESULT=0
# ========================================

if [ -d "${INSTALL_DIR}" ]; then
  if [ -d "${INSTALL_DIR}/plugins/pyenv-update" ]; then
    pyenv update
  fi
  pyenv update
  echo "pyenvは既にインストールされています"
  exit 0
fi

sudo apt install -y \
  libffi-dev libsqlite3-dev zlib1g-dev libbz2-dev libreadline-dev \
  libssl-dev libncursesw5-dev xz-utils tk-dev liblzma-dev \
  libgdbm-dev libnss3-dev

# リポジトリのクローンと環境変数の設定
git clone https://github.com/pyenv/pyenv.git ${INSTALL_DIR}
echo 'export PYENV_ROOT="${HOME}/.pyenv"' >> ~/.bashrc
echo 'export PATH="${PYENV_ROOT}/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(pyenv init -)"' >> ~/.bashrc
source ~/.bashrc

# Pythonのインストール
cd ~
pyenv install ${TARGET_PYTHON_VERSION}
pyenv global ${TARGET_PYTHON_VERSION}
source ~/.bashrc

# 動作
#pyenv versions
#python --version

# pipのバージョンをを上げる
python -m pip install --upgrade pip

# pyenvのupdateプラグインをインストール
git clone https://github.com/pyenv/pyenv-update.git $(pyenv root)/plugins/pyenv-update

exit ${RESULT}
