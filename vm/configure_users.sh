#!/bin/bash

if ! cat /etc/passwd | grep "^phabricator-daemon" >> /dev/null; then
  sudo useradd -r -s /bin/bash phabricator-daemon
fi

if ! cat /etc/passwd | grep "^git" >> /dev/null; then
  sudo useradd -r -s /bin/bash git
fi

if ! cat /etc/passwd | grep "^aphlict" >> /dev/null; then
  sudo useradd -r -s /bin/bash aphlict
fi

if sudo cat /etc/shadow | grep "^git:\!:" >> /dev/null; then
  sudo sed -i -e "s/^git:\!:/git:NP:/" /etc/shadow
fi

if ! sudo cat /etc/sudoers | grep "^git ALL=(phabricator-daemon)" >> /dev/null; then
  echo "git ALL=(phabricator-daemon) SETENV: NOPASSWD: $(whereis -b git-upload-pack | cut -d' ' -f2-), $(whereis -b git-receive-pack | cut -d' ' -f2-)" | (sudo su -c 'EDITOR="tee -a" visudo')
fi
