#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo apt-get install -y npm

pushd phabricator/support/aphlict/server >> /dev/null

npm install ws

popd >> /dev/null

# Start the notification server
pushd phabricator >> /dev/null

bin/aphlict start --client-host=localhost

popd >> /dev/null
