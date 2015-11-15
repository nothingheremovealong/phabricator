#!/bin/bash

if [ "$#" -ne 1 ]
then
  echo "Usage: ${BASH_SOURCE[0]} <sql_instance_name>"
  exit 1
fi

SQL_INSTANCE=$1

sudo apt-get install -y uuid-runtime jq

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

pushd phabricator >> /dev/null
export SQL_DETAILS="$(/google/google-cloud-sdk/bin/gcloud sql instances describe ${SQL_INSTANCE} --format=json)"
if [ -z "${SQL_DETAILS}" ]; then
  echo "Failed to lookup details for the '${SQL_INSTANCE}' Cloud SQL instance. Make sure that you have the SQL API enabled."
  exit
fi
popd >> /dev/null

export SQL_HOST=$(echo ${SQL_DETAILS} | jq -r '.ipAddresses[0].ipAddress')
if [ -z "${SQL_HOST}" ]; then
  echo "Failed to lookup the IP address of the '${SQL_INSTANCE}' Cloud SQL instance"
  exit
fi

export SQL_USER=root
echo "Setting up a connection to ${SQL_INSTANCE} at ${SQL_HOST} as ${SQL_USER}"

export SQL_PASS="$(uuidgen)"
/google/google-cloud-sdk/bin/gcloud sql instances set-root-password --password "${SQL_PASS}" "${SQL_INSTANCE}"

pushd /opt/phabricator >> /dev/null

# Configure Phabricator's connection to the SQL server.
./bin/config set mysql.host ${SQL_HOST}
./bin/config set mysql.port 3306
./bin/config set mysql.user ${SQL_USER}
./bin/config set mysql.pass ${SQL_PASS}

# Configure Phabricator's reference to itself.
#./bin/config set phabricator.base-uri ${PHABRICATOR_BASE_URI}
#./bin/config set security.alternate-file-domain ${ALTERNATE_FILE_DOMAIN}
./bin/config set phd.taskmasters 4

popd >> /dev/null

# And setup the .my.cnf file so that mysql commands are authenticated.
cat > ~/.my.cnf <<EOF
[client]
host=${SQL_HOST}
user=${SQL_USER}
password=${SQL_PASS}
EOF
