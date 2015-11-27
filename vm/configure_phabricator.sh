#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

pushd phabricator >> /dev/null

echo "Stopping daemons..."

sudo ./bin/phd stop

sudo chown -R phabricator-daemon /var/tmp/phd

sudo ./bin/config set phabricator.timezone America/Los_Angeles
sudo ./bin/config set phabricator.show-prototypes true
sudo ./bin/config set pygments.enabled true
sudo ./bin/config set config.ignore-issues '{"mysql.ft_boolean_syntax":true, "mysql.ft_stopword_file": true, "daemons.need-restarting": true, "mysql.max_allowed_packet": true, "large-files": true, "mysql.innodb_buffer_pool_size": true}'
sudo ./bin/config set environment.append-paths '["/usr/lib/git-core/"]'
sudo ./bin/config set phd.user phabricator-daemon
sudo ./bin/config set diffusion.ssh-user git

popd >> /dev/null

