#!/usr/bin/env bash
echo "IMPORTANT: Please run this script from the deployment-scripts/ directory."
echo "(Otherwise, bad things will happen)."
echo ""
# Get parameters:
MULTISITE_IDENTIFIER=$1
DOMAIN=$2
if [ "x$MULTISITE_IDENTIFIER" = "x" ] || [ "x$DOMAIN" = "x" ]; then
  echo "Run this script with the following arguments:"
  echo ""
  echo "./upgradeprojectstructure.sh MULTISITE_IDENTIFIER DOMAIN"
  echo ""
  echo "e.g. ./upgradeprojectstructure.sh greyhead7 greyhead7.greyheaddev.com"
  echo ""
  echo "Please re-run with the required information :)"
  exit
fi
echo ""
echo "This script will update your Drupal project's directory structure to be"
echo "compatible with the new deployment script ./deploy.sh in this directory."
echo ""
echo "To proceed, please change the webroot in your webserver config from e.g."
echo "'path/to/project/www' to 'path/to/project/current/code/www' (i.e. add"
echo "'current/code/' before the www directory)."
read -rsp $'Once you have done that, press any key to continue the script...\n' -n1 key
# - Set $DATETIMENOW=YYYYMMDD-HHMMSS
DATETIMENOW=`date +%Y%m%d-%H%M%S`
# Move up one directory.
cd ..
# Get the directory name
PROJECTDIRECTORYNAME="${PWD##*/}"
cd "www/"
# - Clear aches
drush cc all  --uri=$DOMAIN
# - Back the site up
drush sql-dump --result-file=../$MULTISITE_IDENTIFIER-$DATETIMENOW.sql --uri=$DOMAIN
cd ..
tar czf "$MULTISITE_IDENTIFIER-$DATETIMENOW.sql.gz" "$MULTISITE_IDENTIFIER-$DATETIMENOW.sql"
rm "$MULTISITE_IDENTIFIER-$DATETIMENOW.sql"
# - Create a parallel directory next to $PROJECTROOT/$PROJECTDIRECTORYNAME
#   called $PROJECTDIRECTORYNAME-new
cd ..
mkdir "$PROJECTDIRECTORYNAME-new"
# - Move $PROJECTROOT/$PROJECTDIRECTORYNAME into $PROJECTDIRECTORYNAME-new
mv "$PROJECTDIRECTORYNAME" "$PROJECTDIRECTORYNAME-new/"
# - Rename $PROJECTDIRECTORYNAME-new to $PROJECTDIRECTORYNAME
mv "$PROJECTDIRECTORYNAME-new" "$PROJECTDIRECTORYNAME"
# - cd $PROJECTROOT/$PROJECTDIRECTORYNAME
cd "$PROJECTDIRECTORYNAME"
# Create a deployment-logs directory and chmod it to 0777 so external deployment
# jobs can write to it.
mkdir deployment-logs
chmod 0777 deployment-logs
# - Rename $PROJECTDIRECTORYNAME to "code"
mv "$PROJECTDIRECTORYNAME" code/
# - mkdir current
mkdir 000000
ln -s 000000 current
# - Move code into current
mv code current/
# - cd current
cd current
# - Make a backups directory and move the backup file into it.
mkdir backups
# - Move the backup zip into the backups directory
mv "code/$MULTISITE_IDENTIFIER-$DATETIMENOW.sql.gz" backups/
# - Move the files directory to the project root (out of version control)
cd "code/sites/$MULTISITE_IDENTIFIER"
mv files ../../../..
# - Create a symlink to the files directory at $PROJECTROOT/$PROJECTDIRECTORYNAME/sites/$MULTISITE_IDENTIFIER
ln -s ../../../../files
# - Move the local settings file to the project root (also out of version control)
cd ../..
mv local_databases.php ../..
ln -s ../../local_databases.php

