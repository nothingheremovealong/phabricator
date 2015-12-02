#!/bin/bash -e

#VM_NAME=
#DNS_NAME=
#TOP_LEVEL_DOMAIN=
#GIT_SUBDOMAIN=
#NOTIFICATIONS_SUBDOMAIN=

gcloud_instances() {
  gcloud --quiet compute instances "$@"
}

VM_EXTERNAL_IP=$(gcloud_instances list | grep "\b$VM_NAME\b" | awk '{print $5}')

pushd /opt/phabricator >> /dev/null

sudo su phabricator-daemon -c "./bin/phd restart"
./bin/aphlict restart
sudo $(whereis -b sshd | cut -d' ' -f2) -f /etc/ssh/sshd_config.phabricator

gcloud_dns_records() {
  /google/google-cloud-sdk/bin/gcloud --quiet dns record-sets "$@" --zone="$DNS_NAME"
}

if [[ -n "$GIT_SUBDOMAIN" || -n "$NOTIFICATIONS_SUBDOMAIN" ]; then
  gcloud_dns_records transaction start
  if [ -n "$GIT_SUBDOMAIN" ]; then
    gcloud_dns_records transaction add --name="$GIT_SUBDOMAIN.$TOP_LEVEL_DOMAIN." --ttl=60 --type=A $VM_EXTERNAL_IP
  fi
  if [ -n "$NOTIFICATIONS_SUBDOMAIN" ]; then
    gcloud_dns_records transaction add --name="$NOTIFICATIONS_SUBDOMAIN.$TOP_LEVEL_DOMAIN." --ttl=60 --type=A $VM_EXTERNAL_IP
  fi
  gcloud_dns_records transaction execute
fi

popd >> /dev/null
