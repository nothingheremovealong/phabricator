#!/bin/bash

if [ "$#" -lt 1 ]; then
  echo "Usage: ${BASH_SOURCE[0]} <project_name>"
  exit 1
fi

PROJECT=$1

. phabricator.sh

if [ -z "$(gcloud --project=${PROJECT} --quiet compute firewall-rules list | grep "\b$NETWORK_NAME\b" | grep "\btemp-allow-ssh\b")" ]; then
  echo "Creating temporary $NETWORK_NAME ssh firewall rule..."
  gcloud --project="${PROJECT}" --quiet compute firewall-rules create temp-allow-ssh \
    --allow "tcp:22" \
    --network $NETWORK_NAME \
    --source-ranges "0.0.0.0/0" || exit 1
fi

gcloud --project=${PROJECT} compute ssh $VM_NAME --zone us-central1-a

if [ "$(gcloud --project=${PROJECT} --quiet compute firewall-rules list | grep "\b$NETWORK_NAME\b" | grep "\btemp-allow-ssh\b")" ]; then
  echo -n "Removing temporary $NETWORK_NAME ssh firewall rule..."
  gcloud --project="${PROJECT}" --quiet compute firewall-rules delete temp-allow-ssh || exit 1
fi
