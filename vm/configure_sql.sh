#!/bin/bash

set -e

if [ "$#" -lt 2 ]; then
  echo "Usage: ${BASH_SOURCE[0]} <sql_instance_name> <http://base_uri> (<http://alternate_base_uri>)"
  exit 1
fi

if ! /google/google-cloud-sdk/bin/gcloud --quiet sql instances list >> /dev/null 2> /dev/null; then
  PROJECT=$(gcloud info | grep Project | cut -d"[" -f2 | cut -d"]" -f1)
  echo
  echo
  echo "  Error: Google Cloud SQL API has not been enabled for $PROJECT."
  echo
  echo "  1. Please visit https://console.developers.google.com/apis/api/sqladmin/overview?project=$PROJECT"
  echo "  2. Enable API button"
  echo "  3. Rerun this script"
  echo
  exit 1
fi

SQL_INSTANCE=$1
PHABRICATOR_BASE_URI=$2
if [ "$#" -eq 3 ]; then
  PHABRICATOR_ALTERNATE_BASE_URI=$3
else
  PHABRICATOR_ALTERNATE_BASE_URI=
fi

sudo apt-get install -y uuid-runtime jq

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

pushd phabricator >> /dev/null
export SQL_DETAILS="$(/google/google-cloud-sdk/bin/gcloud sql instances describe ${SQL_INSTANCE} --format=json)"
if [ -z "${SQL_DETAILS}" ]; then
  echo "Failed to lookup details for the '${SQL_INSTANCE}' Cloud SQL instance. Make sure that you have the SQL API enabled."
  exit 1
fi
popd >> /dev/null

export SQL_HOST=$(echo ${SQL_DETAILS} | jq -r '.ipAddresses[0].ipAddress')
if [ -z "${SQL_HOST}" ]; then
  echo "Failed to lookup the IP address of the '${SQL_INSTANCE}' Cloud SQL instance"
  exit 1
fi

export SQL_USER=root
echo "Setting up a connection to ${SQL_INSTANCE} at ${SQL_HOST} as ${SQL_USER}"

export SQL_PASS="$(uuidgen)"
/google/google-cloud-sdk/bin/gcloud sql instances set-root-password --password "${SQL_PASS}" "${SQL_INSTANCE}"

pushd /opt/phabricator >> /dev/null

# Configure Phabricator's connection to the SQL server.
sudo ./bin/config set mysql.host ${SQL_HOST}
sudo ./bin/config set mysql.port 3306
sudo ./bin/config set mysql.user ${SQL_USER}
sudo ./bin/config set mysql.pass ${SQL_PASS}

# Configure Phabricator's reference to itself.
sudo ./bin/config set phabricator.base-uri ${PHABRICATOR_BASE_URI}
sudo ./bin/config set security.alternate-file-domain ${PHABRICATOR_ALTERNATE_BASE_URI}
sudo ./bin/config set phd.taskmasters 4

popd >> /dev/null

echo "Upgrading $SQL_INSTANCE db..."

sudo phabricator/bin/storage upgrade --force
