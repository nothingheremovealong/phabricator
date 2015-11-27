#!/bin/bash

if [ $(grep -c "^Port 22$" /usr/sbin/sshd) -ne 0  ]; then
  echo "Listening port set to 222.";
  sudo sed -i -e 's/^Port 22$/Port 222/' /usr/sbin/sshd

  sudo service ssh restart
fi

sudo mkdir -p /etc/libexec/

if [ ! -f /etc/libexec/phabricator-ssh-hook.sh ]; then
  sudo cp phabricator/resources/sshd/phabricator-ssh-hook.sh /etc/libexec/
fi

sudo sed -i -e "s/^VCSUSER=.*$/VCSUSER=\"git\"/" /etc/libexec/phabricator-ssh-hook.sh
sudo sed -i -e 's:^ROOT=.*$:ROOT="'$(pwd)'/phabricator":' /etc/libexec/phabricator-ssh-hook.sh
sudo chown root /etc/libexec/phabricator-ssh-hook.sh
sudo chmod 755 /etc/libexec/phabricator-ssh-hook.sh

if [ ! -f /etc/ssh/sshd_config.phabricator ]; then
  sudo cp phabricator/resources/sshd/sshd_config.phabricator.example /etc/ssh/sshd_config.phabricator
fi

sudo sed -i -e "s:^AuthorizedKeysCommand .*$:AuthorizedKeysCommand /etc/libexec/phabricator-ssh-hook.sh:" /etc/ssh/sshd_config.phabricator
sudo sed -i -e "s:^AuthorizedKeysCommandUser .*$:AuthorizedKeysCommandUser git:" /etc/ssh/sshd_config.phabricator
sudo sed -i -e "s:^AllowUsers .*$:AllowUsers git:" /etc/ssh/sshd_config.phabricator

# TODO: Turn this into a service.
sudo $(whereis -b sshd | cut -d' ' -f2) -f /etc/ssh/sshd_config.phabricator
