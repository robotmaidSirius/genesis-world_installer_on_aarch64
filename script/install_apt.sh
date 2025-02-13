#!/bin/bash
REQUIREMENTS_TEXT=${1:-requirements.txt}
RESULT=0

while read LINE
do
  if [ -z "${LINE}" ]; then continue; fi
  if [[ ${LINE} =~ ^#.* ]]; then continue; fi

  export APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1
  echo -e "#####################\n[APT] Install '${LINE}'\n#####################"
  sudo -E apt install -y ${LINE}
  if [ $? -ne 0 ]; then
    echo "[ERROR] Install '${LINE}' is failed" >&2
    RESULT=1
    exit ${RESULT}
  fi
done < ${REQUIREMENTS_TEXT}

exit ${RESULT}
