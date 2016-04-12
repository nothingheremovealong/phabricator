#!/bin/sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

set -e

# NOTE: This script assumes you are running it from a directory which contains
# arcanist/, libphutil/, and phabricator/.

pushd $DIR >> /dev/null

sudo git fetch
sudo git rebase origin/master
sudo git submodule update

popd >> /dev/null

### CYCLE WEB SERVER AND DAEMONS ###############################################

pushd phabricator >> /dev/null

# Stop daemons.
sudo su phabricator-daemon -c "./bin/phd stop"

# If running the notification server, stop it.
sudo su aphlict -c "./bin/aphlict stop"

# Stop the webserver.
sudo apachectl stop

### UPDATE SYSTEM PACKAGES ######################################################

sudo apt-get -qq update
sudo apt-get upgrade -y
sudo apt-get autoremove -y

### UPDATE WORKING COPIES ######################################################

popd >> /dev/null

sudo $DIR/configure_submodules.sh

pushd phabricator >> /dev/null

# Upgrade the database schema.
sudo ./bin/storage upgrade --force

# Restart the webserver.
sudo apachectl start

# Restart daemons.
sudo su phabricator-daemon -c "./bin/phd start"

# If running the notification server, start it.
if hash nodejs 2>/dev/null; then
  sudo su aphlict -c "./bin/aphlict start"
fi

popd >> /dev/null
