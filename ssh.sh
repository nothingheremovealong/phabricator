#!/bin/bash

. lib/init.sh

if [ -z "$(gcloud --project=${PROJECT} --quiet compute firewall-rules list | grep "\b$NETWORK_NAME\b" | grep "\btemp-allow-ssh\b")" ]; then
  echo "Creating temporary $NETWORK_NAME ssh firewall rule..."
  gcloud --project="${PROJECT}" --quiet compute firewall-rules create temp-allow-ssh \
    --allow "tcp:222" \
    --network $NETWORK_NAME \
    --target-tags "phabricator" \
    --source-ranges "0.0.0.0/0" || exit 1
fi

gcloud --project=${PROJECT} compute ssh $VM_NAME --zone us-central1-a --ssh-flag="-p 222"

if [ "$(gcloud --project=${PROJECT} --quiet compute firewall-rules list | grep "\b$NETWORK_NAME\b" | grep "\btemp-allow-ssh\b")" ]; then
  echo -n "Removing temporary $NETWORK_NAME ssh firewall rule..."
  gcloud --project="${PROJECT}" --quiet compute firewall-rules delete temp-allow-ssh || exit 1
fi
