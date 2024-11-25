#!/usr/bin/env bash

# when creating new instances of ultima static sites,
# the deploy branch reference can get out of sync
#
# reset it with the following git subtree commands

git subtree split --prefix=deploy -b deploy-temp
git push origin deploy-temp:deploy --force
git branch -D deploy-temp
