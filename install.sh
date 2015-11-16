#!/bin/bash

# Recommended Google Cloud machine:
#
# Ubuntu 14.04
# Enable "Project Access"
# n1-standard-1 (1 vCPU, 3.75 GB memory)
#

if [ "$#" -ne 2 ]
then
  echo "Usage: ${BASH_SOURCE[0]} <sql_instance_name> <http://base_uri>"
  exit 1
fi

SQL_INSTANCE=$1
PHABRICATOR_BASE_URI=$2

confirm() {
  echo "Press RETURN to continue, or ^C to cancel.";
  read -e ignored
}

GIT='git'
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

LTS="Ubuntu 10.04"
ISSUE=`cat /etc/issue`
if [[ $ISSUE != Ubuntu* ]]
then
  echo "This script is intended for use on Ubuntu, but this system appears";
  echo "to be something else. Your results may vary.";
  echo
  confirm
elif [[ `expr match "$ISSUE" "$LTS"` -eq ${#LTS} ]]
then
  GIT='git-core'
fi

echo "PHABRICATOR UBUNTU INSTALL SCRIPT";
echo "This script will install Phabricator and all of its core dependencies.";
echo "Run it from the directory you want to install into.";
echo

ROOT=`pwd`
echo "Phabricator will be installed to: ${ROOT}.";
confirm

echo "Testing sudo..."
sudo true
if [ $? -ne 0 ]
then
  echo "ERROR: You must be able to sudo to run this script.";
  exit 1;
fi;

echo "Installing dependencies: git, apache, mysql, php...";
echo

set +x

# -qq No output except for errors
sudo apt-get -qq update

# Install git
sudo apt-get install -y git

# Install mysql
sudo apt-get install -y mysql-client libmysqlclient-dev

# Install Apache
sudo apt-get install -y apache2

# Install php
sudo apt-get install -y php5 php5-mysql php5-gd php5-dev php5-curl php-apc php5-cli php5-json

sudo apt-get clean

# Enable mod-rewrite
sudo a2enmod rewrite

HAVEPCNTL=`php -r "echo extension_loaded('pcntl');"`
if [ $HAVEPCNTL != "1" ]
then
  echo "Installing pcntl...";
  echo
  apt-get source php5
  PHP5=`ls -1F | grep '^php5-.*/$'`
  (cd $PHP5/ext/pcntl && phpize && ./configure && make && sudo make install)
else
  echo "pcntl already installed";
fi

echo "Configuring submodules..."
bash $DIR/configure_submodules.sh || exit 1

echo "Configuring apache..."
bash $DIR/configure_apache.sh || exit 1

echo "Configuring php..."
bash $DIR/configure_php.sh || exit 1

echo "Configuring pygments..."
bash $DIR/configure_pygments.sh || exit 1

echo "Configuring phabricator..."
bash $DIR/configure_phabricator.sh || exit 1

echo "Configuring scripts..."
bash $DIR/configure_scripts.sh || exit 1

echo "Configuring gcloud..."
bash $DIR/configure_gcloud.sh || exit 1

echo "Configuring sql..."
bash $DIR/configure_sql.sh $SQL_INSTANCE $PHABRICATOR_BASE_URI || exit 1

echo "Configuring sendgrid..."
bash $DIR/configure_sendgrid.sh || exit 1

pushd phabricator >> /dev/null
echo "Starting daemons"
./bin/phd start
popd >> /dev/null

echo "Restarting apache..."
apachectl restart

# Follow-up guides:
# - [Setting up mail](https://cloud.google.com/compute/docs/tutorials/sending-mail/)
