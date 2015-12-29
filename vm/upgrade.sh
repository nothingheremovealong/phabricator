#!/bin/sh

set -e
set -x

# This is an example script for updating Phabricator, similar to the one used to
# update <https://secure.phabricator.com/>. It might not work perfectly on your
# system, but hopefully it should be easy to adapt. This script is not intended
# to work without modifications.

# NOTE: This script assumes you are running it from a directory which contains
# arcanist/, libphutil/, and phabricator/.

sudo apt-get -qq update
sudo apt-get upgrade -y
sudo apt-get autoremove -y

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

pushd $DIR >> /dev/null

sudo git fetch
sudo git rebase origin/master
sudo git submodule update

popd >> /dev/null

pushd phabricator >> /dev/null

### UPDATE WORKING COPIES ######################################################

sudo $DIR/configure_submodules.sh

### CYCLE WEB SERVER AND DAEMONS ###############################################

# Stop daemons.
sudo su phabricator-daemon -c "./bin/phd stop"

# If running the notification server, stop it.
sudo su aphlict -c "./bin/aphlict stop"

# Stop the webserver (apache, nginx, lighttpd, etc). This command will differ
# depending on which system and webserver you are running: replace it with an
# appropriate command for your system.
# NOTE: If you're running php-fpm, you should stop it here too.

sudo apachectl stop


# Upgrade the database schema. You may want to add the "--force" flag to allow
# this script to run noninteractively.
./bin/storage upgrade

# Restart the webserver. As above, this depends on your system and webserver.
# NOTE: If you're running php-fpm, restart it here too.
sudo apachectl start

# Restart daemons.
sudo su phabricator-daemon -c "./bin/phd start"

# If running the notification server, start it.
sudo su aphlict -c "./bin/aphlict start"

popd >> /dev/null
