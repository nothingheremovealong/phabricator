#!/bin/bash

if [ "$#" -lt 1 ]; then
  echo "Usage: ${BASH_SOURCE[0]} <project_name>"
  exit 1
fi

PROJECT=$1

if [ ! -f phabricator.sh ]; then
  echo "No phabricator.sh was found."
  echo "A standard one has been made for you based off phabricator.sh.template."
  echo "Please configure phabricator.sh to your preferences."
  cp phabricator.sh.template phabricator.sh
  exit 1
fi
. phabricator.sh
