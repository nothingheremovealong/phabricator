#!/bin/bash

usage() {
  echo "Usage: ${BASH_SOURCE[0]} -p <project_name>"
}

gcloud version >/dev/null 2>&1 || { echo >&2 "gcloud binary is missing. Download from https://cloud.google.com/sdk/?hl=en"; exit 1; }

GCLOUD_VERSION=$(gcloud version | grep "^Google" | cut -d' ' -f4 | cut -d'.' -f1)

if [ "$GCLOUD_VERSION" -lt 102 ]; then
  echo "Minimum gcloud version required: 102. Found $GCLOUD_VERSION instead."
fi

OPTIND=1 # Reset in case getopts has been used previously in the shell.

# Option defaults
PROJECT=""
VERBOSE=0

while getopts "h?vp:" opt; do
  case "$opt" in
  h|\?)
    usage
    exit 0
    ;;
  v)  VERBOSE=1
    ;;
  p)  PROJECT=$OPTARG
    ;;
  esac
done

verbose() {
  if [ "$VERBOSE" -eq "1" ]; then
    echo "$@"
  fi
}

status() {
  echo -n "$@"
}

status_no() {
  echo no
}

status_ok() {
  echo OK
}

if [ -z "$PROJECT" ]; then
  verbose "Inferring project from default settings..."
  PROJECT=$(gcloud config list 2>/dev/null | grep "^project" | cut -d' ' -f3)
  
  echo "Inferred project:"
  echo
  echo "    $PROJECT"
  echo
  echo "If incorrect, please terminate this script and provide a -p <project name> argument."
  echo "If correct, press enter to continue."
  echo
  echo "Provide a -p <project name> argument to avoid this warning in the future."
  read
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_ROOT_PATH="$( cd "$DIR/../config" && pwd )"
CONFIG_PATH="$CONFIG_ROOT_PATH/$PROJECT"

# Check existence of a config file for this project.
if [ ! -f "$CONFIG_PATH" ]; then
  echo "No config was found."
  echo "A standard one has been made for you based off phabricator.sh.template."
  echo "Please configure $CONFIG_PATH to your preferences."

  mkdir -p "$CONFIG_ROOT_PATH"
  cp $DIR/../phabricator.sh.template "$CONFIG_PATH"
  chmod +x $CONFIG_PATH

  default_zone=$(gcloud config list 2>/dev/null | grep "^zone" | cut -d' ' -f3)
  if [ ! -z "$default_zone" ]; then
    sed -i.bak "s/^ZONE=.*/ZONE=$default_zone/" "$CONFIG_PATH"
    rm "$CONFIG_PATH.bak"
  fi
  
  exit 1
fi

verbose "Reading config from $CONFIG_PATH"
. "$CONFIG_PATH"

# Verify that a ZONE has been provided.
if [ -z "$ZONE" ]; then
  echo "Config file has not specified a ZONE."
  echo "Please specify a ZONE in $CONFIG_PATH"
  exit 1
fi

# Colors

RED='\033[0;31m'
NC='\033[0m'

logger() {
  while read data; do
    verbose "$data"
  done
}

# Register aliases methods for interacting with gcloud

gcloud_project() {
  gcloud --project=${PROJECT} --quiet "$@"
}

gcloud_networks() {
  gcloud_project compute networks "$@"
}

gcloud_instances() {
  gcloud_project compute instances "$@"
}

gcloud_disks() {
  gcloud_project compute disks "$@" --zone "$ZONE"
}

gcloud_attach_disk() {
  gcloud_project compute instances attach-disk $VM_NAME "$@" --zone "$ZONE"
}

gcloud_dns_zones() {
  gcloud_project dns managed-zones "$@"
}

gcloud_dns_records() {
  gcloud_project dns record-sets "$@" --zone="$DNS_NAME"
}

gcloud_firewall_rules() {
  gcloud_project compute firewall-rules "$@"
}

gcloud_appengine() {
  gcloud_project preview app "$@"
}

gcloud_sql_instances() {
  gcloud_project sql instances "$@"
}
