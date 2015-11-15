#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#if [ $(grep -c "^Listen 80$" /etc/apache2/ports.conf) -ne 0  ]; then
#  echo "Listening port set to 8080.";
#  sed -i -e 's/^Listen 80$/Listen 8080/' /etc/apache2/ports.conf
#fi

if [ -f /etc/apache2/sites-enabled/000-default.conf ]; then
  echo "Removing default site..."
  rm -f /etc/apache2/sites-enabled/000-default.conf
fi

if [ ! -f /etc/apache2/sites-available/phabricator.conf ]; then
  echo "Installing phabricator site..."
  cp $DIR/sites/phabricator.conf /etc/apache2/sites-available/phabricator.conf
else
  if ! cmp --silent $DIR/sites/phabricator.conf /etc/apache2/sites-available/phabricator.conf; then
    echo "Overwrite existing phabricator.conf?"
    select yn in "Yes" "No"; do
      case $yn in
        Yes ) echo "Updating phabricator site...";cp $DIR/sites/phabricator.conf /etc/apache2/sites-available/phabricator.conf; break;;
        No ) exit;;
      esac
    done
  fi
fi

if [ ! -h /etc/apache2/sites-enabled/phabricator.conf ]; then
  echo "Activating phabricator site..."
  ln -s /etc/apache2/sites-available/phabricator.conf /etc/apache2/sites-enabled/phabricator.conf
fi

if [ ! -d /usr/local/apache/logs ]; then
  echo "Configuring apache logs..."
  mkdir -p /usr/local/apache/logs && chown www-data:www-data /usr/local/apache/logs
fi

if [ ! -d /var/log/phabricator ]; then
  echo "Configuring phabricator logs..."
  mkdir -p /var/log/phabricator && chown www-data:www-data /var/log/phabricator
fi

