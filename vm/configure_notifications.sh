#!/bin/bash

if [ "$#" -lt 1 ]; then
  echo "Usage: ${BASH_SOURCE[0]} <notifications_url>"
  exit 1
fi

NOTIFICATIONS_URL=$1

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo apt-get install -y npm

ln -s /usr/bin/nodejs /usr/bin/node

pushd phabricator/support/aphlict/server >> /dev/null
npm install ws
popd >> /dev/null

# Start the notification server
pushd phabricator >> /dev/null

./bin/config set notification.enabled true
./bin/config set notification.client-uri $NOTIFICATIONS_URL:22280

touch /var/log/aphlict.log
chmod a+w /var/log/aphlict.log

popd >> /dev/null
