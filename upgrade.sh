git submodule foreach "git fetch;git checkout origin/stable"
git add .
git commit -am "Upgrading phabricator to latest stable." || exit 1
