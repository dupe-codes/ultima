#!/bin/sh

set -e

# Get the site name from first argument
SITE=$1

if [ -z "$SITE" ]; then
    printf "\033[0;31mError: Site name is required\033[0m\n"
    echo "Usage: $0 <site-name>"
    exit 1
fi

printf "\033[0;32mDeploying updates for site \"%s\" to GitHub...\033[0m\n" "$SITE"

# Create commit message
msg="build: rebuilding site $SITE $(date)"
if [ -n "$2" ]; then
    msg="$2"
fi

# Add and commit changes
git add .
git commit -m "$msg"

# Push compiled deploy directory to site-specific deployment branch
echo ""
printf "\033[0;32mPushing %s to deploy-%s branch...\033[0m\n" "deploy/$SITE" "$SITE"
git subtree push --prefix "deploy/$SITE" origin "deploy-$SITE"

# Push all changes to main
echo ""
printf "\033[0;32mPushing changes to main branch...\033[0m\n"
git push

echo ""
printf "\033[0;32mDeployment for site \"%s\" completed successfully!\033[0m\n" "$SITE"

# TODO: poll status of deployment on DigitalOcean app platform?
