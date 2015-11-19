#!/bin/bash

sudo apt-get install -y npm
ln -sf /usr/bin/nodejs /usr/bin/node

pushd phabricator/support/aphlict/server >> /dev/null

npm install ws

popd >> /dev/null

pushd phabricator/ >> /dev/null

./bin/aphlict stop

./bin/config set notification.enabled true
./bin/config set notification.client-uri http://localhost/ws/

./bin/aphlict start --client-host=localhost

popd >> /dev/null
