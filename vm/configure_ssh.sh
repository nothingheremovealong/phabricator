#!/bin/bash

if [ $(grep -c "^Port 22$" /usr/sbin/sshd) -ne 0  ]; then
  echo "Listening port set to 222.";
  sudo sed -i -e 's/^Port 22$/Port 222/' /usr/sbin/sshd
fi

sudo service ssh restart