#!/bin/bash

set -e

function disable_php {
  if [ $(grep -c "^$1" /etc/php5/apache2/php.ini) = 0 ]; then
    echo "Disabling $1..."
    echo "$1 = 0" >> /etc/php5/apache2/php.ini
  fi
}

disable_php apc.stat
disable_php apc.slam_defense
disable_php opcache.validate_timestamps

if [ $(grep -c "^post_max_size = 8M$" /etc/php5/apache2/php.ini) -ne 0  ]; then
  echo "Increasing post max size to 32M.";
  sed -i -e "s/post_max_size = 8M/post_max_size = 32M/" /etc/php5/apache2/php.ini
fi

