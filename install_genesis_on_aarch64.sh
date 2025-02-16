#!/bin/bash
SCRIPT_DIR=$(cd $(dirname $(realpath "${BASH_SOURCE:-0}")); pwd)/script
CONFIG_FILE=$(cd $(dirname $(realpath "${BASH_SOURCE:-0}")); pwd)/config.json
DIST_DIR=$(cd $(dirname $(realpath "${BASH_SOURCE:-0}")); pwd)/dist
FLAG_KEEP_GOING=0
RESULT=0
export MAX_JOBS=$((`nproc` - 1))
if [[ ${MAX_JOBS} -le 0 ]]; then
  export MAX_JOBS=1
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
        echo "Usage: $0 [-f|--config CONFIG_FILE] [-j|--jobs MAX_JOBS] [--continue_on_error]"
        echo "  -f, --config CONFIG_FILE : Specify the configuration file"
        echo "  -j, --jobs MAX_JOBS      : Specify the maximum number of jobs"
        echo "  --continue_on_error      : Continue to the next process even if an error occurs"
        exit 0;;
    --continue_on_error)
        FLAG_KEEP_GOING=1
        shift;;
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
    *) echo "[WARNING] Unknown parameter passed: $1" >&2; shift;;
  esac
done

# ========================================
CONFIG_FILE=$(readlink -f ${CONFIG_FILE})
if [ ! -f "${CONFIG_FILE}" ]; then
  RESULT=1
  echo "[ERROR] config.json does not exist" >&2
  # TODO: Generate default if config.json does not exist?
  exit 0
fi
JSON_DATA=$(cat ${CONFIG_FILE} | jq -c .)
if [[ "" == "${JSON_DATA}" ]]; then
  RESULT=1
  echo "[ERROR] config.json is not a valid JSON file" >&2
fi
function get_jq_value() {
  local key=${1}
  local value=$(eval echo $(jq -r '.'${key} <<< "${JSON_DATA}"));
  if [ "null" == "${value}" ];then
    value=""
  fi
  echo ${value}
}
function flag_jq_value() {
  local key=${1}
  local value=$(eval echo $(jq -r '.'${key} <<< "${JSON_DATA}"));
  if [ true == "${value}" ];then
    value=1
  else
    value=0
  fi
  echo ${value}
}
# ========================================
echo -e "####################\n $0\n####################"
sudo apt-get install -y jq

# TODO: Confirm custom installation?

# Get packages to install from config.json
INSTALL_ROOT=$(eval echo $(get_jq_value 'install_path'));
PYTHON_VERSION=$(get_jq_value "packages.version.python");
ENV_NAME=$(get_jq_value "venv_name");
SKIP_APT=$(flag_jq_value "packages.skip.apt");
SKIP_PIP=$(flag_jq_value "packages.skip.pip");
INSTALL_PYENV=$(flag_jq_value "pyenv.install");

ARGUMENTS=""
if [ 1 == $(flag_jq_value "reinstall") ];then
  ARGUMENTS="--force-reinstall"
fi
mkdir -p ${DIST_DIR}

## Install via apt
if [ ${SKIP_APT} -ne 1 ]; then
  echo -e "\n==============\n# Install: apt\n=============="
  bash ${SCRIPT_DIR}/install_apt.sh ${SCRIPT_DIR}/requirements_apt.txt --continue_on_error
  RESULT=$?
  if [ ${RESULT} -ne 0 ]; then
    echo "[ERROR] Install 'apt requirements_apt.txt' failed" >&2
    if [[ ${FLAG_KEEP_GOING} -eq 0 ]]; then
      exit 0
    fi
  fi
fi

if [ ${RESULT} -eq 0 ]; then
  mkdir -p ${INSTALL_ROOT}
  # Set environment variables
  pushd "${INSTALL_ROOT}" >/dev/null 2>&1
    # pyenv settings
    export PYENV_ROOT=$(eval echo $(get_jq_value "pyenv.path"))
    export PATH="${PYENV_ROOT}/bin:$PATH"
    eval "$(pyenv init -)"
    PYENV_VERSION=$(pyenv --version)
    if [ "" == "${PYENV_VERSION}" ]; then
      if [ ${INSTALL_PYENV} -eq 1 ]; then
        ## Install pyenv
        echo -e "\n==============\n# Install: pyenv\n=============="
        bash ${SCRIPT_DIR}/setup_pyenv.sh --python_version=$(get_jq_value "packages.version.python") -p=${PYENV_ROOT}
        RESULT=$?
      else
        RESULT=1
      fi
      if [ ${RESULT} -ne 0 ]; then
        echo "[ERROR] Install 'pyenv' failed" >&2
        if [[ ${FLAG_KEEP_GOING} -eq 0 ]]; then
          exit 0
        fi
      fi
    fi

    echo -e "\n==============\n# pyenv: Version changes ${PYTHON_VERSION}\n=============="
    pyenv local ${PYTHON_VERSION}
    RESULT=$?
    if [ ${RESULT} -eq 0 ]; then
      if [ "${PYTHON_VERSION}" != "$(pyenv version-name)" ]; then
        RESULT=1
      fi
    fi
    if [ ${RESULT} -ne 0 ]; then
      if [ -d "${ENV_NAME}" ]; then
        rm -rf ${ENV_NAME}
      fi
      ## Install python
      echo -e "\n==============\n# Install: pyenv:${PYTHON_VERSION}\n=============="
      pyenv install --skip-existing ${PYTHON_VERSION}
      RESULT=$?
      if [ ${RESULT} -ne 0 ]; then
        echo "[ERROR] Install 'python ${PYTHON_VERSION}' failed" >&2
        if [[ ${FLAG_KEEP_GOING} -eq 0 ]]; then
          exit 0
        fi
      fi
      pyenv local ${PYTHON_VERSION}
    fi

    if [ "" != ${ENV_NAME} ];then
      echo -e "\n==============\n# Set venv: ${ENV_NAME}\n=============="
      if [ ! -d "${ENV_NAME}" ]; then
        python -m venv ${ENV_NAME}
      fi
      source ${ENV_NAME}/bin/activate
      echo "* Virtual environment: ${VIRTUAL_ENV_PROMPT}"
      echo "* Shims version      : $(pyenv version-name)"
      echo "* Version file       : $(pyenv version-file)"
      if [ ! -e ${ENV_NAME}/bin/activate ]; then
        echo "[ERROR] 'activate' script not found" >&2
        if [[ ${FLAG_KEEP_GOING} -eq 0 ]]; then
          exit 0
        fi
      fi
      if [ $(pyenv version-name) != ${PYTHON_VERSION} ]; then
        echo "[ERROR] 'python' version is not ${PYTHON_VERSION}" >&2
        exit 0
      fi
    fi

    ## ========================================
    # Install via pip
    echo -e "\n==============\n# pip install --upgrade pip\n=============="
    echo "* Python version     : $(python --version)"
    python -m pip install --upgrade pip
    # Install pip requirements.txt
    if [ ${SKIP_PIP} -ne 1 ]; then
      echo -e "\n==============\n# pip requirements.txt\n=============="
      pip install -U -r ${SCRIPT_DIR}/requirements.txt
      RESULT=$?
      if [ ${RESULT} -ne 0 ]; then
        echo "[ERROR] Install 'pip requirements.txt' failed" >&2
        if [[ ${FLAG_KEEP_GOING} -eq 0 ]]; then
          exit 0
        fi
      fi
    fi

    ## ========================================
    ## Install: cmake
    echo -e "\n==============\n# Install: cmake\n=============="
    bash ${SCRIPT_DIR}/install_make_cmake.sh -v=$(get_jq_value "packages.version.cmake") -p=${INSTALL_ROOT}
    RESULT=$?
    if [ ${RESULT} -ne 0 ]; then
      echo "[ERROR] Install 'cmake' failed." >&2
      if [[ ${FLAG_KEEP_GOING} -eq 0 ]]; then
        exit 0
      fi
    fi
    ## Install: LLVM
    echo -e "\n==============\n# Install: LLVM\n=============="
    bash ${SCRIPT_DIR}/install_make_llvm.sh -v=$(get_jq_value "packages.version.llvm") -p=${INSTALL_ROOT} --tar
    RESULT=$?
    if [ ${RESULT} -ne 0 ]; then
      echo "[ERROR] Install 'LLVM' failed." >&2
      if [[ ${FLAG_KEEP_GOING} -eq 0 ]]; then
        exit 0
      fi
    fi
    ## Install: CoACD
    echo -e "\n==============\n# Install: CoACD\n=============="
    bash ${SCRIPT_DIR}/install_python_CoACD.sh -v=$(get_jq_value "packages.version.CoACD") -p=${INSTALL_ROOT} --dist=${DIST_DIR} ${ARGUMENTS}
    RESULT=$?
    if [ ${RESULT} -ne 0 ]; then
      echo "[ERROR] Install 'install_CoACD' failed." >&2
      if [[ ${FLAG_KEEP_GOING} -eq 0 ]]; then
        exit 0
      fi
    fi
    ## Install: VTK
    echo -e "\n==============\n# Install: VTK\n=============="
    bash ${SCRIPT_DIR}/install_cmake_python_vtk.sh -v=$(get_jq_value "packages.version.vtk") -p=${INSTALL_ROOT} --dist=${DIST_DIR} ${ARGUMENTS}
    RESULT=$?
    if [ ${RESULT} -ne 0 ]; then
      echo "[ERROR] Install 'VTK' failed." >&2
      if [[ ${FLAG_KEEP_GOING} -eq 0 ]]; then
        exit 0
      fi
    fi

    ## ========================================
    ## Install: taichi
    echo -e "\n==============\n# Install: taichi\n=============="
    bash ${SCRIPT_DIR}/install_python_taichi.sh -v=$(get_jq_value "packages.version.taichi") -p=${INSTALL_ROOT} --dist=${DIST_DIR} ${ARGUMENTS} --apply_patch
    RESULT=$?
    if [ ${RESULT} -ne 0 ]; then
      echo "[ERROR] Install 'taichi' failed." >&2
      if [[ ${FLAG_KEEP_GOING} -eq 0 ]]; then
        exit 0
      fi
    fi
    ## Install: libigl
    echo -e "\n==============\n# Install: libigl\n=============="
    bash ${SCRIPT_DIR}/install_python_libigl.sh -v=$(get_jq_value "packages.version.libigl") -p=${INSTALL_ROOT} --dist=${DIST_DIR} ${ARGUMENTS}
    RESULT=$?
    if [ ${RESULT} -ne 0 ]; then
      echo "[ERROR] Install 'libigl' failed." >&2
      if [[ ${FLAG_KEEP_GOING} -eq 0 ]]; then
        exit 0
      fi
    fi
    ## Install: PyMeshLab
    echo -e "\n==============\n# Install: PyMeshLab\n=============="
    bash ${SCRIPT_DIR}/install_python_PyMeshLab.sh -v=$(get_jq_value "packages.version.PyMeshLab") -p=${INSTALL_ROOT} --dist=${DIST_DIR} ${ARGUMENTS}
    RESULT=$?
    if [ ${RESULT} -ne 0 ]; then
      echo "[ERROR] Install 'PyMeshLab' failed." >&2
      if [[ ${FLAG_KEEP_GOING} -eq 0 ]]; then
        exit 0
      fi
    fi
    ## Install: tetgen
    echo -e "\n==============\n# Install: tetgen\n=============="
    bash ${SCRIPT_DIR}/install_python_tetgen.sh -v=$(get_jq_value "packages.version.tetgen") -p=${INSTALL_ROOT} --dist=${DIST_DIR} ${ARGUMENTS}
    RESULT=$?
    if [ ${RESULT} -ne 0 ]; then
      echo "[ERROR] Install 'tetgen' failed." >&2
      if [[ ${FLAG_KEEP_GOING} -eq 0 ]]; then
        exit 0
      fi
    fi

    ## Install: genesis-world
    echo -e "\n==============\n# Install: genesis-world\n=============="
    bash ${SCRIPT_DIR}/install_python_genesis.sh -v=$(get_jq_value "packages.version.genesis") -p=${INSTALL_ROOT} --dist=${DIST_DIR} ${ARGUMENTS}
    RESULT=$?
    if [ ${RESULT} -ne 0 ]; then
      echo "[ERROR] Install 'genesis' failed." >&2
      if [[ ${FLAG_KEEP_GOING} -eq 0 ]]; then
        exit 0
      fi
    fi

    ## ========================================
    ## Create script
    echo -e "\n==============\n# Create script\n=============="
    bash ${SCRIPT_DIR}/create_script.sh --env_name=${ENV_NAME} --pyenv_dir=$(eval echo $(get_jq_value "pyenv.path"))
    RESULT=$?
    if [ ${RESULT} -ne 0 ]; then
      echo "[ERROR] Create script failed." >&2
      if [[ ${FLAG_KEEP_GOING} -eq 0 ]]; then
        exit 0
      fi
    fi

  popd >/dev/null 2>&1

  ## Display version information
  pushd "${DIST_DIR}" >/dev/null 2>&1
    bash ${SCRIPT_DIR}/print_ver.sh > ${DIST_DIR}/build_info.log
    md5sum *.whl *.log > ${DIST_DIR}/md5
  popd >/dev/null 2>&1

  if [ "" != ${ENV_NAME} ];then
    deactivate
  fi

  echo -e "\n==============\n# Finished\n    Install path : ${INSTALL_ROOT}\n=============="
fi
