#!/bin/bash

if [ "$#" -ne 1 ]
then
  echo "Usage: ${BASH_SOURCE[0]} <sql_instance_name>"
  exit 1
fi

SQL_INSTANCE=$1

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

pushd phabricator >> /dev/null
export SQL_DETAILS="$(/google/google-cloud-sdk/bin/gcloud sql instances describe ${SQL_INSTANCE} --format=json)"
if [ -z "${SQL_DETAILS}" ]; then
  echo "Failed to lookup details for the '${SQL_INSTANCE}' Cloud SQL instance. Make sure that you have the SQL API enabled."
  exit
fi
popd >> /dev/null
