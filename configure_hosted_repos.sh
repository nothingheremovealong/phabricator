#!/bin/bash

if [ ! -d /var/repo/ ]; then
  echo "Creating hosted repo folder..."
  mkdir -p /var/repo && chown www-data:www-data /var/repo
fi
