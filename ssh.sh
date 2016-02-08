#!/bin/bash

. lib/init.sh

port="22"
if [ ! -z "$(gcloud --quiet --project="${PROJECT}" compute instances describe $VM_NAME --zone=$ZONE | grep "ssh-222")" ]; then
  port="222"
fi

if [ -z "$(gcloud --project=${PROJECT} --quiet compute firewall-rules list | grep "\b$NETWORK_NAME\b" | grep "\btemp-allow-ssh\b")" ]; then
  echo "Creating temporary $NETWORK_NAME ssh firewall rule..."
  gcloud --project="${PROJECT}" --quiet compute firewall-rules create temp-allow-ssh \
    --allow "tcp:$port" \
    --network $NETWORK_NAME \
    --target-tags "phabricator" \
    --source-ranges "0.0.0.0/0" || exit 1
fi

gcloud --project=${PROJECT} compute ssh $VM_NAME --zone=$ZONE --ssh-flag="-p $port"

if [ "$(gcloud --project=${PROJECT} --quiet compute firewall-rules list | grep "\b$NETWORK_NAME\b" | grep "\btemp-allow-ssh\b")" ]; then
  echo -n "Removing temporary $NETWORK_NAME ssh firewall rule..."
  gcloud --project="${PROJECT}" --quiet compute firewall-rules delete temp-allow-ssh || exit 1
fi
