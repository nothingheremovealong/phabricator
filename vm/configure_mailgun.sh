#!/bin/bash

if [ "$#" -lt 2 ]; then
  echo "Usage: ${BASH_SOURCE[0]} <base_uri>"
  exit 1
fi

PHABRICATOR_BASE_DOMAIN=$1
MAILGUN_APIKEY=$2

pushd phabricator >> /dev/null

echo "Configuring Phabricator for Mailgun..."

sudo ./bin/config set mailgun.api-key $MAILGUN_APIKEY
sudo ./bin/config set mailgun.domain $PHABRICATOR_BASE_DOMAIN

sudo ./bin/config set --database metamta.mail-adapter PhabricatorMailImplementationMailgunAdapter
sudo ./bin/config set --database metamta.domain $PHABRICATOR_BASE_DOMAIN
sudo ./bin/config set --database metamta.default-address noreply@$PHABRICATOR_BASE_DOMAIN

popd >> /dev/null
