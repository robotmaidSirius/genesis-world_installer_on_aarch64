#!/bin/bash
REQUIREMENTS_TEXT=requirements.txt
RESULT=0
CONTINUE_ON_ERROR=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
        echo "Usage: $0 [REQUIREMENTS_TEXT] [--continue_on_error]"
        echo "  REQUIREMENTS_TEXT   : Specify the requirements text file"
        echo "  --continue_on_error : Continue to the next process even if an error occurs"
        exit 0;;
    --continue_on_error)
        shift
        CONTINUE_ON_ERROR=1
        shift;;
    *)
        if [ -e $1 ]; then
          REQUIREMENTS_TEXT=$1
        else
          echo "[WARNING] Unknown parameter passed: $1" >&2;
        fi
        shift;;
  esac
done

while read LINE
do
  if [ -z "${LINE}" ]; then continue; fi
  if [[ ${LINE} =~ ^#.* ]]; then continue; fi

  export APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1
  echo -e "#####################\n[APT] Install '${LINE}'\n#####################"
  sudo -E apt-get install -y ${LINE}
  if [ $? -ne 0 ]; then
    RESULT=1
    if [ ${CONTINUE_ON_ERROR} -eq 1 ]; then
      echo "[WARNING] Install '${LINE}' is failed" >&2
    else
      echo "[ERROR] Install '${LINE}' is failed" >&2
      exit ${RESULT}
    fi
  fi
done < ${REQUIREMENTS_TEXT}

exit ${RESULT}
