#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

pushd $DIR >> /dev/null
git submodule update --init --recursive
popd >> /dev/null

function clone {
  if [ ! -d $1 ]; then
    echo "Cloning $1..."
    git clone $DIR/third_party/$1 $1
  fi

  pushd $DIR >> /dev/null
  sha=$(git submodule status third_party/$1 | cut -d' ' -f2)
  popd >> /dev/null
  pushd $1 >> /dev/null
  echo "Checking out $1/$sha..."
  git checkout -q $sha
  popd >> /dev/null
}

clone arcanist
clone libphutil
clone phabricator
