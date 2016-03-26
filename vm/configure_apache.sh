#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function safe_copy {
  if [ ! -f $2 ]; then
    echo "Copying $1..."
    cp $1 $2
  else
    if ! cmp --silent $1 $2; then
      echo "Overwrite existing $1 at $2?"
      select yn in "Yes" "No"; do
        case $yn in
          Yes ) echo "Updating $2 site...";cp $1 $2; break;;
          No ) exit;;
        esac
      done
    fi
  fi
}

if [ $(grep -c "^Listen 80$" /etc/apache2/ports.conf) -ne 0  ]; then
  echo "Listening port set to 8080.";
  sudo sed -i -e 's/^Listen 80$/Listen 8080/' /etc/apache2/ports.conf
fi

if [ -f /etc/apache2/sites-enabled/000-default.conf ]; then
  echo "Removing default site..."
  sudo rm -f /etc/apache2/sites-enabled/000-default.conf
fi

safe_copy $DIR/sites/phabricator.conf /etc/apache2/sites-available/phabricator.conf

if [ ! -h /etc/apache2/sites-enabled/phabricator.conf ]; then
  echo "Activating phabricator site..."
  sudo ln -s /etc/apache2/sites-available/phabricator.conf /etc/apache2/sites-enabled/phabricator.conf
fi

if [ ! -d /usr/local/apache/logs ]; then
  echo "Configuring apache logs..."
  sudo mkdir -p /usr/local/apache/logs && chown www-data:www-data /usr/local/apache/logs
fi

if [ ! -d /var/log/phabricator ]; then
  echo "Configuring phabricator logs..."
  sudo mkdir -p /var/log/phabricator && chown www-data:www-data /var/log/phabricator
fi

