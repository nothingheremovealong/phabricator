#!/bin/bash

if [ "$#" -lt 1 ]; then
  echo "Usage: ${BASH_SOURCE[0]} <project_name>"
  exit 1
fi

PROJECT=$1

NETWORK_NAME=phabricator

echo "Network..."

if [ -z "$(gcloud --project=${PROJECT} --quiet compute networks list | grep $NETWORK_NAME)" ]; then
  echo "- Creating $NETWORK_NAME network..."
  gcloud --project="${PROJECT}" --quiet compute networks create $NETWORK_NAME --range "10.0.0.0/24" || exit 1
fi

echo " Firewall rules..."

if [ -z "$(gcloud --project=${PROJECT} --quiet compute firewall-rules list | grep $NETWORK_NAME | grep allow-internal)" ]; then
echo " - Creating internal $NETWORK_NAME firewall rules..."
  gcloud --project="${PROJECT}" --quiet compute firewall-rules create allow-internal \
    --allow "tcp:0-65535" \
    --network $NETWORK_NAME \
    --source-ranges "10.0.0.0/24" || exit 1
fi

if [ -z "$(gcloud --project=${PROJECT} --quiet compute firewall-rules list | grep $NETWORK_NAME | grep allow-ssh)" ]; then
echo " - Creating temporary $NETWORK_NAME ssh firewall rules..."
  gcloud --project="${PROJECT}" --quiet compute firewall-rules create allow-ssh \
    --allow "tcp:22" \
    --network $NETWORK_NAME \
    --source-ranges "0.0.0.0/0" || exit 1
fi

echo "SQL..."

if [ -z "$(gcloud --quiet --project=${PROJECT} sql instances list | grep phabricator)" ]; then
echo "- Creating phabricator SQL database..."
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

echo "Compute instances..."

if [ -z "$(gcloud --quiet --project=${PROJECT} compute instances list | grep phabricator)" ]; then
echo "- Creating compute instance..."
  gcloud --quiet --project="${PROJECT}" compute instances create "phabricator" \
    --boot-disk-size "10GB" \
    --image "ubuntu-14-04" \
    --machine-type "n1-standard-1" \
    --network "$NETWORK_NAME" \
    --zone "us-central1-a" || exit 1
fi

while [ -z "$(gcloud --quiet --project=${PROJECT} compute instances list | grep phabricator)" ]; do
  sleep 10
done
