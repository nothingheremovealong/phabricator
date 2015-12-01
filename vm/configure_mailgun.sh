#!/bin/bash

if [ "$#" -lt 2 ]; then
  echo "Usage: ${BASH_SOURCE[0]} <base_uri>"
  exit 1
fi

PHABRICATOR_BASE_DOMAIN=$1
MAILGUN_APIKEY=$2

pushd phabricator >> /dev/null

echo "Configuring Phabricator for Mailgun..."

./bin/config set mailgun.api-key $MAILGUN_APIKEY
./bin/config set mailgun.domain $PHABRICATOR_BASE_DOMAIN

./bin/config set --database metamta.mail-adapter PhabricatorMailImplementationMailgunAdapter
./bin/config set --database metamta.domain $PHABRICATOR_BASE_DOMAIN
./bin/config set --database metamta.default-address noreply@$PHABRICATOR_BASE_DOMAIN

popd >> /dev/null
