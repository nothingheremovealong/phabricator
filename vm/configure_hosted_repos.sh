#!/bin/bash

if [ ! -d /mnt/git-repos ]; then
  echo "Creating hosted repo folder..."
  sudo mkdir -p /mnt/git-repos && sudo chown phabricator-daemon:phabricator-daemon /mnt/git-repos
  
  # TODO: This assumes that there are no other disks mounted. We should be identifying the disk
  #       name from an `instances describe` call.
  sudo /usr/share/google/safe_format_and_mount -m "mkfs.ext4 -F" /dev/sdb /mnt/git-repos
fi

pushd phabricator >> /dev/null

sudo ./bin/config set repository.default-local-path /mnt/git-repos

popd >> /dev/null
