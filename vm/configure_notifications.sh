#!/bin/bash

set -e

if [ "$#" -lt 1 ]; then
  echo "Usage: ${BASH_SOURCE[0]} <notifications_url>"
  exit 1
fi

NOTIFICATIONS_URL=$1
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo apt-get install -y npm

ln -s /usr/bin/nodejs /usr/bin/node

pushd phabricator/support/aphlict/server >> /dev/null
sudo npm install ws
popd >> /dev/null

# Start the notification server
pushd phabricator >> /dev/null

sudo ./bin/config set notification.enabled true
sudo ./bin/config set notification.client-uri $NOTIFICATIONS_URL:22280

sudo touch /var/log/aphlict.log
sudo chmod a+w /var/log/aphlict.log
sudo chown -R aphlict:aphlict /var/tmp/aphlict/

popd >> /dev/null
