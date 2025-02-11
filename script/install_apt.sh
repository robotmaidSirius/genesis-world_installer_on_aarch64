#!/bin/bash
REQUIREMENTS_TEXT=${1:-requirements.txt}
RESULT=0

while read LINE
do
  sudo apt install -y ${LINE}
done < ${REQUIREMENTS_TEXT}

exit ${RESULT}
