#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

pushd phabricator >> /dev/null

echo "Stopping daemons..."
./bin/phd stop

./bin/config set phabricator.timezone America/Los_Angeles
./bin/config set phabricator.show-prototypes true
./bin/config set pygments.enabled true
./bin/config set config.ignore-issues '{"mysql.ft_boolean_syntax":true, "mysql.ft_stopword_file": true, "daemons.need-restarting": true, "mysql.max_allowed_packet": true, "large-files": true}'
./bin/config set environment.append-paths '["/usr/lib/git-core/"]'

popd >> /dev/null

