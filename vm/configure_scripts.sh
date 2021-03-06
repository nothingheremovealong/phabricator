#!/bin/bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function safe_copy {
  if [ ! -f $2 ]; then
    echo "Copying $1 to $2..."
    cp $1 $2
  else
    if ! cmp --silent $1 $2; then
      echo "Overwrite existing $1 at $2?"
      select yn in "Yes" "No"; do
        case $yn in
          Yes ) echo "Copying $1 to $2...";cp $1 $2; break;;
          No ) exit;;
        esac
      done
    fi
  fi
}

#safe_copy $DIR/scripts/PhabricatorMailImplementationPythonCLIAdapter.php /opt/phabricator/src/applications/metamta/adapter/PhabricatorMailImplementationPythonCLIAdapter.php
#safe_copy $DIR/scripts/send_mail.py /opt/send_mail.py
