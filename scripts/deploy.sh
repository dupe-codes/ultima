#!/bin/sh

set -e

printf "\033[0;32mDeploying updates to GitHub...\033[0m\n"

msg="build: rebuilding site $(date)"
if [ -n "$*" ]; then
    msg="$*"
fi
git add .
git commit -m "$msg"

# push compiled deploy directory to deployment branch
git subtree push --prefix deploy origin deploy
