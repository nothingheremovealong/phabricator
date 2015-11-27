#!/bin/bash

if [ ! -d /var/repo/ ]; then
  echo "Creating hosted repo folder..."
  sudo mkdir -p /var/repo && sudo chown phabricator-daemon:phabricator-daemon /var/repo
fi
