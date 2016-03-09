#!/usr/bin/env bash
#
# This is a basic script which will simply perform a git pull, updatedb and a
# drush cc all (soon to be drush cr in Drupal 8, don'tchaknow).
#
# You must provide the site's @name - which must have a corresponding drush
# alias file entry - and the environment, e.g. dev, rc or live (but see next
# comment).
#
# This script is designed for development and pre-release environments; live
# sites shouldn't really have a proper git checkout, but instead should have a
# tag checked out; deployments to live will therefore normally involve checking
# out a newer tag in a parallel directory, removing any unnecessary cruft such
# as the .git directory, and any unrelated Drupal multisite directories, and
# then a database backup is performed before switching the live site's code
# out of the webroot, and switching in the newly-checked out tag - for example,
# by deleting a symlink and re-creating it to point at the new checkout.
#
# So, this script is really only intended for dev and rc servers.
#
# Usage: ./updateremote.sh nhsnwlondon dev
#
# This will look for the Dev version of the @nhsnwlondon Drush alias, the same
# as if you typed:
#
# ./drush @nhsnwlondon.dev <some command>
#
# The following commands will be run on the remote:
#
# ./drush @[site].[environment] ssh 'git pull'
# ./drush @[site].[environment] updatedb -y
# ./drush @[site].[environment] cc all
#
# If you aren't sure if a Drush alias has been set up, look in this repo in:
#
# /drush/
#
# ... where you should find a number of Drush alias files. If your site isn't in
# there (it should be if it has been set up by following the script in the
# Intranet Open Atrium site), then please create it and commit it. Thanks!
#
SITE=$1
if [ "x$SITE" = "x" ]; then
  echo "Oops, no Drush @site alias provided in parameter 1. Try something like ./updateremote.sh nhsnwlondon dev"
  exit
fi
#
# 2) ENVIRONMENT
#
ENVIRONMENT=$2
if [ "x$ENVIRONMENT" = "x" ]; then
  echo "Please provide an environment type in parameter 2, e.g. 'dev' or 'rc', like this: ./updateremote.sh nhsnwlondon dev"
  exit
fi
#
echo "Updating remote @$SITE environment $ENVIRONMENT. Please check the output"
echo "of the commands to see if it all went well..."
echo ""
#
drush --root='../www/' @$SITE.$ENVIRONMENT ssh 'git pull'
drush --root='../www/' @$SITE.$ENVIRONMENT updatedb -y
drush --root='../www/' @$SITE.$ENVIRONMENT cc all
#
echo ""
echo "All done. Hopefully that didn't go terribly askew..."
echo ""
