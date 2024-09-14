#!/bin/sh

set -e

printf "\033[0;32mDeploying updates to GitHub...\033[0m\n"

# build & commit the project
make build

msg="build: rebuilding site $(date)"
if [ -n "$*" ]; then
    msg="$*"
fi
git add .
git commit -m "$msg"

# push public directory to gh-pages branch
# TODO: setup
# git subtree push --prefix build origin gh-pages
