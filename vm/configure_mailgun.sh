#!/bin/bash

if [ "$#" -lt 1 ]; then
  echo "Usage: ${BASH_SOURCE[0]} <http://base_uri>"
  exit 1
fi

PHABRICATOR_BASE_URI=$1
PHABRICATOR_BASE_DOMAIN=$(echo $PHABRICATOR_BASE_URI | cut -d'/' -f3-)

pushd phabricator >> /dev/null

echo "Configuring Phabricator for Mailgun..."

echo "Please enter your Mailgun credentials from https://mailgun.com/cp/domains"
echo
echo "Learn more about using mailgun with Google Cloud Engine at:"
echo "    https://cloud.google.com/compute/docs/tutorials/sending-mail/using-mailgun"
echo
echo -n "Mailgun API key: "
read apikey
echo
echo -n "Mailgun domain (e.g. subdomain.domain.com): "
read domain
echo

./bin/config set mailgun.api-key $apikey
./bin/config set mailgun.domain $domain

./bin/config set --database metamta.mail-adapter PhabricatorMailImplementationMailgunAdapter
./bin/config set --database metamta.domain $PHABRICATOR_BASE_DOMAIN
./bin/config set --database metamta.default-address noreply@$PHABRICATOR_BASE_DOMAIN

popd >> /dev/null
