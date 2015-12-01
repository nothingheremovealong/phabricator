#!/bin/bash

if [ "$#" -lt 1 ]; then
  echo "Usage: ${BASH_SOURCE[0]} <project_name>"
  exit 1
fi

PROJECT=$1

if [ ! -f phabricator.sh ]; then
  echo "No phabricator.sh was found."
  echo "A standard one has been made for you based off phabricator.sh.template."
  echo "Please configure phabricator.sh to your preferences."
  cp phabricator.sh.template phabricator.sh
  exit 1
fi
. phabricator.sh

gcloud_networks() {
  gcloud --project=${PROJECT} --quiet compute networks "$@"
}

gcloud_instances() {
  gcloud --project=${PROJECT} --quiet compute instances "$@"
}

gcloud_disks() {
  gcloud --project=${PROJECT} --quiet compute disks "$@" --zone "us-central1-a"
}

gcloud_attach_disk() {
  gcloud --project=${PROJECT} --quiet compute instances attach-disk $VM_NAME "$@" --zone "us-central1-a"
}

gcloud_dns_zones() {
  gcloud --project=${PROJECT} --quiet dns managed-zones "$@"
}

gcloud_dns_records() {
  gcloud --project=${PROJECT} --quiet dns record-sets "$@" --zone="$DNS_NAME"
}

gcloud_firewall_rules() {
  gcloud --project=${PROJECT} --quiet compute firewall-rules "$@"
}

gcloud_appengine() {
  gcloud --quiet --project="${PROJECT}" preview app "$@"
}
