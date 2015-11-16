#!/bin/bash

if [ "$#" -lt 1 ]; then
  echo "Usage: ${BASH_SOURCE[0]} <project_name>"
  exit 1
fi

PROJECT=$1

echo Network...

if [ -z "$(gcloud --project=${PROJECT} --quiet compute networks list | grep phabricator)" ]; then
  echo Creating phabricator network...
  gcloud --project="${PROJECT}" --quiet compute networks create phabricator --range "10.0.0.0/24" || exit 1
fi

echo Firewall rules...

if [ -z "$(gcloud --project=${PROJECT} --quiet compute firewall-rules list | grep phabricator)" ]; then
echo Creating phabricator firewall rules...
  gcloud --project="${PROJECT}" --quiet compute firewall-rules create allow-internal \
    --allow "tcp:0-65535" \
    --network phabricator \
    --source-ranges "10.0.0.0/24" || exit 1
fi

echo SQL...

if [ -z "$(gcloud --quiet --project=${PROJECT} sql instances list | grep phabricator)" ]; then
echo Creating phabricator SQL database...
  gcloud --quiet --project="${PROJECT}" sql instances create "phabricator" \
    --backup-start-time="00:00" \
    --assign-ip \
    --authorized-networks "0.0.0.0/0" \
    --authorized-gae-apps "${PROJECT}" \
    --gce-zone "us-central1-a" \
    --tier="D1" \
    --pricing-plan="PACKAGE" \
    --database-flags="sql_mode=STRICT_ALL_TABLES,ft_min_word_len=3,max_allowed_packet=33554432" || exit 1
fi

SQL_INSTANCE_NAME=$(gcloud --project="${PROJECT}" --quiet sql instances list | grep phabricator | cut -d " " -f 1)
if [ -z "${SQL_INSTANCE_NAME}" ]; then
  # We could not load the name of the Cloud SQL instance, so we need to bail out.
  echo "Failed to load the name of the Cloud SQL instance to use for Phabricator"
  exit
fi
