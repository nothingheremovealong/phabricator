#!/bin/bash

if [ "$#" -lt 1 ]; then
  echo "Usage: ${BASH_SOURCE[0]} <project_name>"
  exit 1
fi

PROJECT=$1

if [ -z "$(gcloud --quiet --project=${PROJECT} sql instances list | grep phabricator)" ]; then
  gcloud --quiet --project="${PROJECT}" sql instances create "phabricator" \
    --backup-start-time="00:00" \
    --assign-ip \
    --authorized-networks "0.0.0.0/0" \
    --authorized-gae-apps "${PROJECT}" \
    --gce-zone "us-central1-a" \
    --tier="D1" \
    --pricing-plan="PACKAGE" \
    --database-flags="sql_mode=STRICT_ALL_TABLES,ft_min_word_len=3,max_allowed_packet=33554432"
fi

INSTANCE_NAME=$(gcloud --project="${PROJECT}" --quiet sql instances list | grep phabricator | cut -d " " -f 1)
if [ -z "${INSTANCE_NAME}" ]; then
  # We could not load the name of the Cloud SQL instance, so we need to bail out.
  echo "Failed to load the name of the Cloud SQL instance to use for Phabricator"
  exit
fi

echo $INSTANCE_NAME


