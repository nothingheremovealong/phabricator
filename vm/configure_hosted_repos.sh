#!/bin/bash

set -e

if [ ! -d /mnt/git-repos ]; then
  echo "Creating hosted repo folder..."
  sudo mkdir -p /mnt/git-repos && sudo chown phabricator-daemon:phabricator-daemon /mnt/git-repos
  
  # TODO: This is assuming that the "first" disk mounted is the git-repos one and that its name is
  # /dev/sdb. We should be identifying the disk name from an `instances describe` call.
  sudo /usr/share/google/safe_format_and_mount -m "mkfs.ext4 -F" /dev/sdb /mnt/git-repos
fi

if [ ! -d /mnt/file-storage ]; then
  echo "Creating file storage folder..."
  sudo mkdir -p /mnt/file-storage && sudo chown www-data:www-data /mnt/file-storage
  
  # TODO: This is assuming that the "second" disk mounted is the git-repos one and that its name is
  # /dev/sdc. We should be identifying the disk name from an `instances describe` call.
  sudo /usr/share/google/safe_format_and_mount -m "mkfs.ext4 -F" /dev/sdc /mnt/file-storage
fi

pushd phabricator >> /dev/null

sudo ./bin/config set repository.default-local-path /mnt/git-repos
sudo ./bin/config set storage.local-disk.path /mnt/file-storage

popd >> /dev/null
