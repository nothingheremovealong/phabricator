#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo apt-get install -y npm

ln -s /usr/bin/nodejs /usr/bin/node

pushd phabricator/support/aphlict/server >> /dev/null

npm install ws

popd >> /dev/null

# Start the notification server
pushd phabricator >> /dev/null

./bin/config set notification.enabled true
./bin/config set notification.client-uri http://localhost/ws/

sudo su www -c "bin/aphlict restart --client-host=localhost"

popd >> /dev/null
