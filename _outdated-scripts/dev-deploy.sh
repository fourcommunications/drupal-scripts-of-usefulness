#!/usr/bin/env bash
#
# This script is used to update a Drupal installation to the latest code in a
# particular branch, and will then backup the database via Drush, before running
# a Drush database update.
#
# Please run this script with the following arguments:
#
# 1) Git commit hash to be deployed;
#
REVISION=$1
if [ "x$REVISION" = "x" ]; then
  echo "Fatal error: no Git revision provided in parameter 1."
  exit
fi
#
# 2) MULTISITE_IDENTIFIER - see settings.php in a project file for more info.
#
MULTISITE_IDENTIFIER=$2
if [ "x$MULTISITE_IDENTIFIER" = "x" ]; then
  echo "Fatal error: no multisite identifier provided in parameter 2."
  exit
fi
#
# 3) Website domain name (for Drupal path-matching purposes), e.g.
#    dev.d7.greyheaddev.com;
#
DOMAIN=$3
if [ "x$DOMAIN" = "x" ]; then
  echo "Fatal error: no domain provided in parameter 3."
  exit
fi
#
# 4, 5, 6) Database name, username and password, so that we can back up the database
#    and write out a new database connections file;
#
DATABASENAME=$4
DATABASEUSERNAME=$5
DATABASEPASSWORD=$6
if [ "x$DATABASENAME" = "x" ] || [ "x$DATABASEUSERNAME" = "x" ] || [ "x$DATABASEPASSWORD" = "x" ]; then
  echo "Fatal error: either database name, database username, or database password weren't provided in parameters 4 to 6 respectively."
  exit
fi
#
# 7) Path to the Project root with trailing slash, but not including the project
#    directory, e.g. "/home/rc/public_html";
#
PROJECTROOT=$7
if [ "x$PROJECTROOT" = "x" ]; then
  echo "Fatal error: no project root provided in parameter 7."
  exit
fi
#
# 8) Project directory name, no slashes at all, e.g. "greyhead_drupal7";
#
PROJECTDIRECTORYNAME=$8
if [ "x$PROJECTDIRECTORYNAME" = "x" ]; then
  echo "Fatal error: no project directory name provided in parameter 8."
  exit
fi
#
# 9) Is the deployment from scratch? (Not currently supported);
#
FROM_SCRATCH=$9
if [ "x$FROM_SCRATCH" = "x" ]; then
  echo "Fatal error: no FROM_SCRATCH parameter provided in parameter 9."
  exit
fi
#
# 10) The branch being deployed;
#
BRANCH=${10}
if [ "x$BRANCH" = "x" ]; then
  echo "Fatal error: no branch name provided in parameter 10."
  exit
fi
#
# 11) Repository clone URL, e.g.
#     "git@greyhead.git.beanstalkapp.com:/greyhead/greyhead_drupal7.git";
#
GITCLONEURL=${11}
if [ "x$GITCLONEURL" = "x" ]; then
  echo "Fatal error: no URL to perform a Git clone provided in parameter 11."
  exit
fi
#
# 12) %COMMENT% is the Beanstalk deployment comment
#
COMMENT=${12}
if [ "x$COMMENT" = "x" ]; then
  echo "Fatal error: no comment provided in parameter 12."
  exit
fi
#
# 13 and 14) User name and e-mail of the person who performed the deployment.
#
USER_NAME=${13}
USER_EMAIL=${14}
if [ "x$USER_NAME" = "x" ] || [ "x$USER_EMAIL" = "x" ]; then
  echo "Fatal error: either Beanstalk user name or email not provided in parameters 13 or 14, respectively."
  exit
fi
#
# 15) TIMESTAMP_UTC
#
TIMESTAMP_UTC=${15}
if [ "x$TIMESTAMP_UTC" = "x" ]; then
  echo "Fatal error: no timestamp provided in parameter 15."
  exit
fi
#
# 16) REPO_NAME
#
REPO_NAME=${16}
if [ "x$REPO_NAME" = "x" ]; then
  echo "Fatal error: no repo name provided in parameter 16."
  exit
fi
#
# 17) REPO_URL
#
REPO_URL=${17}
if [ "x$REPO_URL" = "x" ]; then
  echo "Fatal error: no repo URL provided in parameter 17."
  exit
fi
#
# 18) ROLLBACK - from %ROLLBACK?%
#
ROLLBACK=${18}
if [ "x$ROLLBACK" = "x" ]; then
  echo "Fatal error: no rollback flag provided in parameter 18."
  exit
fi

#
# So a template to call this script would be:
#
# ./deploy.sh %REVISION% {MULTISITE_IDENTIFIER} {DOMAIN} {DATABASENAME} {DATABASEUSERNAME} {DATABASEPASSWORD} {PROJECTROOT} {PROJECTDIRECTORYNAME} %FROM_SCRATCH% %BRANCH% {GITCLONEURL} %COMMENT% %USER_NAME% %USER_EMAIL% %TIMESTAMP_UTC% %REPO_NAME% %REPO_URL% %ROLLBACK?%
# ./deploy.sh 527a4f46cb82b5ac9f17c6b3521828249573d67d greyhead7 greyhead7.local {DATABASENAME} {DATABASEUSERNAME} {DATABASEPASSWORD} "/Volumes/Sites/Greyhead Design" drupal7 0 dev git@greyhead.git.beanstalkapp.com:/greyhead/greyhead_drupal7.git %COMMENT% %USER_NAME% %USER_EMAIL% %TIMESTAMP_UTC% "greyhead_drupal7" %REPO_URL% 0
#
#

# - Set $DATETIMENOW=YYYYMMDD-HHMMSS
DATETIMENOW=`date +%Y%m%d-%H%M%S`

#  - Write out a text file containing this deployment's information in the root of this version
LOGFILEDIR="$PROJECTROOT/$PROJECTDIRECTORYNAME/deployment-logs"
LOGFILE="deployment-log-$REVISION-$DATETIMENOW.txt"

# Make a directory for deployment logs, if it doesn't already exist
if [ ! -e "$LOGFILEDIR" ]; then
  mkdir "$LOGFILEDIR"
fi

# Create a "latest-deployment.txt" link
rm "$LOGFILEDIR/latest-deployment.txt"
ln -s "$LOGFILEDIR/$LOGFILE" "$LOGFILEDIR/latest-deployment.txt"

# Let the user know what's occurrin'.
echo "Deploying. Please tail -f $LOGFILEDIR/latest-deployment.txt for full details of the deployment..."

# Redirect all output from here to the logfile.
set -x
#exec > "$LOGFILEDIR/$LOGFILE" 2>&1

echo "Deployment log file"
echo "==================="
echo ""
echo "Script parameters:"
echo ""
echo "01: REVISION=$REVISION"
echo "02: MULTISITE_IDENTIFIER=$MULTISITE_IDENTIFIER"
echo "03: DOMAIN=$DOMAIN"
echo "04: DATABASENAME=$DATABASENAME"
echo "05: DATABASEUSERNAME=$DATABASEUSERNAME"
echo "06: DATABASEPASSWORD=$DATABASEPASSWORD"
echo "07: PROJECTROOT=$PROJECTROOT"
echo "08: PROJECTDIRECTORYNAME=$PROJECTDIRECTORYNAME"
echo "09: FROM_SCRATCH=$FROM_SCRATCH"
echo "10: BRANCH=$BRANCH"
echo "11: GITCLONEURL=$GITCLONEURL"
echo "12: COMMENT=$COMMENT"
echo "13: USER_NAME=$USER_NAME"
echo "14: USER_EMAIL=$USER_EMAIL"
echo "15: TIMESTAMP_UTC=$TIMESTAMP_UTC"
echo "16: REPO_NAME=$REPO_NAME"
echo "17: REPO_URL=$REPO_URL"
echo "18: ROLLBACK=$ROLLBACK"
echo ""
echo "--------------------------------------------------------------------------"
echo ""

#  Directory structure:
#
#  current, old, older and oldest are symlinks to the current and previous 3 site
#  versions.
#
#  $PROJECTROOT/
#  $PROJECTROOT/$PROJECTDIRECTORYNAME/
#  $PROJECTROOT/$PROJECTDIRECTORYNAME/$REVISION/
#  $PROJECTROOT/$PROJECTDIRECTORYNAME/$REVISION/database-backups/
#  $PROJECTROOT/$PROJECTDIRECTORYNAME/$REVISION/code/
#  $PROJECTROOT/$PROJECTDIRECTORYNAME/$REVISION/code/configuration/
#  $PROJECTROOT/$PROJECTDIRECTORYNAME/$REVISION/code/...
#  $PROJECTROOT/$PROJECTDIRECTORYNAME/$REVISION/code/www/...
#  $PROJECTROOT/$PROJECTDIRECTORYNAME/current/
#  $PROJECTROOT/$PROJECTDIRECTORYNAME/current/backups/
#  $PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/
#  $PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/configuration/
#  $PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/...
#  $PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/www/...
#  $PROJECTROOT/$PROJECTDIRECTORYNAME/old/
#  $PROJECTROOT/$PROJECTDIRECTORYNAME/old/backups/
#  $PROJECTROOT/$PROJECTDIRECTORYNAME/old/code/
#  $PROJECTROOT/$PROJECTDIRECTORYNAME/old/code/configuration/
#  $PROJECTROOT/$PROJECTDIRECTORYNAME/old/code/...
#  $PROJECTROOT/$PROJECTDIRECTORYNAME/old/code/www/...
#  $PROJECTROOT/$PROJECTDIRECTORYNAME/older/
#  $PROJECTROOT/$PROJECTDIRECTORYNAME/older/backups/
#  $PROJECTROOT/$PROJECTDIRECTORYNAME/older/code/
#  $PROJECTROOT/$PROJECTDIRECTORYNAME/older/code/configuration/
#  $PROJECTROOT/$PROJECTDIRECTORYNAME/older/code/...
#  $PROJECTROOT/$PROJECTDIRECTORYNAME/older/code/www/...
#  $PROJECTROOT/$PROJECTDIRECTORYNAME/oldest/
#  $PROJECTROOT/$PROJECTDIRECTORYNAME/oldest/backups/
#  $PROJECTROOT/$PROJECTDIRECTORYNAME/oldest/code/
#  $PROJECTROOT/$PROJECTDIRECTORYNAME/oldest/code/configuration/
#  $PROJECTROOT/$PROJECTDIRECTORYNAME/oldest/code/...
#  $PROJECTROOT/$PROJECTDIRECTORYNAME/oldest/code/www/...
#  $PROJECTROOT/$PROJECTDIRECTORYNAME/files
#  $PROJECTROOT/$PROJECTDIRECTORYNAME/local_databases.php

#  High-level deployment plan:

# - cd to the project directory
cd "$PROJECTROOT/$PROJECTDIRECTORYNAME"

# - if dir $REVISION doesn't exist, set $NEWCHECKOUT=1
if [ ! -d "$PROJECTROOT/$PROJECTDIRECTORYNAME/$REVISION" ]; then
  # It's a new checkout - the directory doesn't exist
  echo "Revision directory $PROJECTROOT/$PROJECTDIRECTORYNAME/$REVISION doesn't exist - we need to re-check out this revision."
  NEWCHECKOUT=1
else
  # The directory already exists - it's one of current, old, older or oldest
  # directories
  echo "Revision directory $PROJECTROOT/$PROJECTDIRECTORYNAME/$REVISION already exists - we only need to perform a hard reset in this directory."
  NEWCHECKOUT=0
fi

# - if $NEWCHECKOUT=1 mkdir $REVISION
if [ "$NEWCHECKOUT" = "1" ]; then
  mkdir "$PROJECTROOT/$PROJECTDIRECTORYNAME/$REVISION"
fi

# - cd $REVISION
cd "$PROJECTROOT/$PROJECTDIRECTORYNAME/$REVISION"

# - mkdir backups
mkdir "$PROJECTROOT/$PROJECTDIRECTORYNAME/$REVISION/backups"

# - if $NEWCHECKOUT=1 git clone $GITCLONEURL ./code
if [ "$NEWCHECKOUT" = "1" ]; then
  # Perform a shallow checkout:
  git clone --depth 1 "$GITCLONEURL" --branch $BRANCH "$PROJECTROOT/$PROJECTDIRECTORYNAME/$REVISION/code"
fi

# - cd code
cd "$PROJECTROOT/$PROJECTDIRECTORYNAME/$REVISION/code"

# - git reset --hard %REVISION%
git reset --hard $REVISION

# Check if the files directory exists in the correct location (i.e. outside the
# sites/xxx/ directory). If it doesn't, attempt to move it out of the sites/xxx/
# directory.
if [ ! -d "$PROJECTROOT/$PROJECTDIRECTORYNAME/files" -a -d "$PROJECTROOT/$PROJECTDIRECTORYNAME/$REVISION/code/www/sites/$MULTISITE_IDENTIFIER/files" ]; then
  mv "$PROJECTROOT/$PROJECTDIRECTORYNAME/$REVISION/code/www/sites/$MULTISITE_IDENTIFIER/files" "$PROJECTROOT/$PROJECTDIRECTORYNAME/"
fi

# rm -rf the files directory, if it exists, in the sites/xxx/ directory.
rm -rf "$PROJECTROOT/$PROJECTDIRECTORYNAME/$REVISION/code/www/sites/$MULTISITE_IDENTIFIER/files"

#  - Symlink local_databases.php and files directories to the correct places
cd "$PROJECTROOT/$PROJECTDIRECTORYNAME/$REVISION/code/www/sites/$MULTISITE_IDENTIFIER"
ln -s "$PROJECTROOT/$PROJECTDIRECTORYNAME/files" "$PROJECTROOT/$PROJECTDIRECTORYNAME/$REVISION/code/www/sites/$MULTISITE_IDENTIFIER/files"

# - Move the local settings file to the project root (also out of version control)
cd "$PROJECTROOT/$PROJECTDIRECTORYNAME/$REVISION/code/"
rm "$PROJECTROOT/$PROJECTDIRECTORYNAME/$REVISION/code/local_databases.php"
ln -s "$PROJECTROOT/$PROJECTDIRECTORYNAME/local_databases.php" "$PROJECTROOT/$PROJECTDIRECTORYNAME/$REVISION/code/local_databases.php"

# Create a symlink in the sites/ directory which correctly maps the right
# sites directory:
ln -s "$PROJECTROOT/$PROJECTDIRECTORYNAME/$REVISION/code/www/sites/$MULTISITE_IDENTIFIER" "$PROJECTROOT/$PROJECTDIRECTORYNAME/$REVISION/code/www/sites/$DOMAIN"

# - Create a local databases file from the template file.
rm "$PROJECTROOT/$PROJECTDIRECTORYNAME/local_databases.php"
cp "$PROJECTROOT/$PROJECTDIRECTORYNAME/$REVISION/code/deployment-scripts/deployment-templates/local_databases.template.php" "$PROJECTROOT/$PROJECTDIRECTORYNAME/local_databases.php"
perl -pi -e "s/{{MULTISITE_IDENTIFIER}}/$MULTISITE_IDENTIFIER/g" "$PROJECTROOT/$PROJECTDIRECTORYNAME/local_databases.php"
perl -pi -e "s/{{DOMAIN}}/$DOMAIN/g" "$PROJECTROOT/$PROJECTDIRECTORYNAME/local_databases.php"
perl -pi -e "s/{{DATABASENAME}}/$DATABASENAME/g" "$PROJECTROOT/$PROJECTDIRECTORYNAME/local_databases.php"
perl -pi -e "s/{{DATABASEUSERNAME}}/$DATABASEUSERNAME/g" "$PROJECTROOT/$PROJECTDIRECTORYNAME/local_databases.php"
perl -pi -e "s/{{DATABASEPASSWORD}}/$DATABASEPASSWORD/g" "$PROJECTROOT/$PROJECTDIRECTORYNAME/local_databases.php"

#  - Take the site offline
drush vset maintenance_mode 1 --uri=$DOMAIN --root="$PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/www"

#  - Clear caches
drush cc all --uri=$DOMAIN --root="$PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/www"

#  - Back up the current database to $PROJECTROOT/$PROJECTDIRECTORYNAME/current/backups/$MULTISITE_IDENTIFIER-YYYYMMDD-HHMMSS.sql.gz
drush sql-dump --result-file="$PROJECTROOT/$PROJECTDIRECTORYNAME/current/backups/$MULTISITE_IDENTIFIER-$DATETIMENOW.sql" --uri=$DOMAIN --root="$PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/www"

cd "$PROJECTROOT/$PROJECTDIRECTORYNAME/current/backups"
tar czf "$MULTISITE_IDENTIFIER-$DATETIMENOW.sql.gz" "$MULTISITE_IDENTIFIER-$DATETIMENOW.sql"
rm "$MULTISITE_IDENTIFIER-$DATETIMENOW.sql"

#  - Create a symlink called ..../current/backups/latest-database-snapshot.sql.gz pointing
#    to this db dump
rm latest-database-snapshot.sql.gz
ln -s "$MULTISITE_IDENTIFIER-$DATETIMENOW.sql.gz" latest-database-snapshot.sql.gz

#  - If $ROLLBACK=1 but we DON'T have a database, we can't rollback and
#    must exit with an error message
if [ ! -e "$PROJECTROOT/$PROJECTDIRECTORYNAME/$REVISION/backups/latest-database-snapshot.sql.gz" -a "$ROLLBACK" = "1" ]; then
  echo "A rollback was requested to revision $REVISION, but we don't have a"
  echo "database backup for that revision, so we can't perform a roll back as"
  echo "this could result in a database whose schema does not match the schema"
  echo "in code. We know this sucks, and we're sorry. :-("
  exec 2>&-
  echo "Something went horribly wrong. Sorry about this. Please see the log file at $LOGFILE for details."
  exit 1
fi

#  - If $ROLLBACK=1 and $NEWCHECKOUT!=1 and
#    $PROJECTROOT/$PROJECTDIRECTORYNAME/$REVISION/backups/latest-database-snapshot.sql.gz
#    exists, we have a DB backup and can restore the code
#[ -e latest-database-snapshot.sql.gz -a "$DOMAIN" = "greyhead7.local" ]
if [ -e "$PROJECTROOT/$PROJECTDIRECTORYNAME/$REVISION/backups/latest-database-snapshot.sql.gz" -a "$ROLLBACK" = "1" -a "$NEWCHECKOUT" != "1" ]; then
  cd "$PROJECTROOT/$PROJECTDIRECTORYNAME/$REVISION/backups"
  # Get the actual sql.gz filename:
  DATABASEBACKUPTORESTORE=`ls -l "$PROJECTROOT/$PROJECTDIRECTORYNAME/$REVISION/backups/latest-database-snapshot.sql.gz" | awk '{print $11}'`
  # Expand the file:
  tar -zxvf "$DATABASEBACKUPTORESTORE.sql.gz"
  # Restore the DB backup:
  cd "$PROJECTROOT/$PROJECTDIRECTORYNAME/$REVISION/code/www/sites/$MULTISITE_IDENTIFIER"
  drush sql-cli < "$PROJECTROOT/$PROJECTDIRECTORYNAME/$REVISION/backups/$DATABASEBACKUPTORESTORE.sql" --uri=$DOMAIN --root="$PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/www"
  # Remove the expanded zip file:
  rm "$PROJECTROOT/$PROJECTDIRECTORYNAME/$REVISION/backups/$DATABASEBACKUPTORESTORE.sql"
fi

#  - @TODO: if $ROLLBACK=1, we also need to make sure when we clean up the "oldest"
#    directory, we don't delete it if the directory name matches the revision
#    number we've just deployed
#  - Therefore, get the revision that oldest points to as $OLDREVISION and if
#    $OLDESTREVISION!=$REVISION and "x$PROJECTROOT" != "x" (to prevent root deletes)
#    cd $PROJECTROOT/$PROJECTDIRECTORYNAME/ && rm -rf ./$REVISION
OKTODELETEOLDESTVERSION=0

# If "oldest" exists at all
if [ -e "$PROJECTROOT/$PROJECTDIRECTORYNAME/oldest" ]; then
  OLDESTREVISION=`ls -l "$PROJECTROOT/$PROJECTDIRECTORYNAME/oldest" | awk '{print $11}'`
  # Be careful not to delete EVERYTHING in the project root directory!
  if [ "$OLDESTREVISION" != "$REVISION" -a "x$PROJECTROOT" != "x" -a "x$OLDESTREVISION" != "x" ]; then
    OKTODELETEOLDESTVERSION=1
  else
    OKTODELETEOLDESTVERSION=0
  fi
else
  # Oldest doesn't seem to exist
  OKTODELETEOLDESTVERSION=0
fi

if [ "$OKTODELETEOLDESTVERSION" = "1" -a "x$OLDESTREVISION" != "x" ]; then
  cd "$PROJECTROOT/$PROJECTDIRECTORYNAME"
  rm -rf "$PROJECTROOT/$PROJECTDIRECTORYNAME/$OLDESTREVISION"
  rm "$PROJECTROOT/$PROJECTDIRECTORYNAME/oldest"
fi

#  - Now we need to move all the remaining symlinks along by one:
#  - mv "older" > "oldest", "old" > "older", and "current" > "old"
cd "$PROJECTROOT/$PROJECTDIRECTORYNAME"
mv "$PROJECTROOT/$PROJECTDIRECTORYNAME/older" "$PROJECTROOT/$PROJECTDIRECTORYNAME/oldest"
mv "$PROJECTROOT/$PROJECTDIRECTORYNAME/old" "$PROJECTROOT/$PROJECTDIRECTORYNAME/older"
mv "$PROJECTROOT/$PROJECTDIRECTORYNAME/current" "$PROJECTROOT/$PROJECTDIRECTORYNAME/old"

#  - Lastly, ln -s $REVISION current
ln -s "$PROJECTROOT/$PROJECTDIRECTORYNAME/$REVISION" "$PROJECTROOT/$PROJECTDIRECTORYNAME/current"

#  - drush updatedb -y
cd "$PROJECTROOT/$PROJECTDIRECTORYNAME/$REVISION/code/www/sites/$MULTISITE_IDENTIFIER"
drush updatedb -y --uri=$DOMAIN --root="$PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/www"

#  - drush fra -y
drush fra -y --uri=$DOMAIN --root="$PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/www"

#  - drush cc all
drush cc all --uri=$DOMAIN --root="$PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/www"

#  - Put site back online
drush vset maintenance_mode 0 --uri=$DOMAIN --root="$PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/www"

# Leave a file which has the deployment details in the webroot:
touch "$PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/www/greyheaddeploymentinformation.txt"
echo "" > "$PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/www/greyheaddeploymentinformation.txt"
echo "Deployment log file" >> "$PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/www/greyheaddeploymentinformation.txt"
echo "===================" >> "$PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/www/greyheaddeploymentinformation.txt"
echo "" >> "$PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/www/greyheaddeploymentinformation.txt"
echo "Script parameters:" >> "$PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/www/greyheaddeploymentinformation.txt"
echo "" >> "$PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/www/greyheaddeploymentinformation.txt"
echo "01: REVISION=$REVISION" >> "$PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/www/greyheaddeploymentinformation.txt"
echo "02: MULTISITE_IDENTIFIER=$MULTISITE_IDENTIFIER" >> "$PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/www/greyheaddeploymentinformation.txt"
echo "03: DOMAIN=$DOMAIN" >> "$PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/www/greyheaddeploymentinformation.txt"
echo "04: DATABASENAME=$DATABASENAME" >> "$PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/www/greyheaddeploymentinformation.txt"
echo "05: DATABASEUSERNAME=$DATABASEUSERNAME" >> "$PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/www/greyheaddeploymentinformation.txt"
echo "06: DATABASEPASSWORD=(provided)" >> "$PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/www/greyheaddeploymentinformation.txt"
echo "07: PROJECTROOT=$PROJECTROOT" >> "$PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/www/greyheaddeploymentinformation.txt"
echo "08: PROJECTDIRECTORYNAME=$PROJECTDIRECTORYNAME" >> "$PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/www/greyheaddeploymentinformation.txt"
echo "09: FROM_SCRATCH=$FROM_SCRATCH" >> "$PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/www/greyheaddeploymentinformation.txt"
echo "10: BRANCH=$BRANCH" >> "$PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/www/greyheaddeploymentinformation.txt"
echo "11: GITCLONEURL=$GITCLONEURL" >> "$PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/www/greyheaddeploymentinformation.txt"
echo "12: COMMENT=$COMMENT" >> "$PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/www/greyheaddeploymentinformation.txt"
echo "13: USER_NAME=$USER_NAME" >> "$PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/www/greyheaddeploymentinformation.txt"
echo "14: USER_EMAIL=(provided)" >> "$PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/www/greyheaddeploymentinformation.txt"
echo "15: TIMESTAMP_UTC=$TIMESTAMP_UTC" >> "$PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/www/greyheaddeploymentinformation.txt"
echo "16: REPO_NAME=$REPO_NAME" >> "$PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/www/greyheaddeploymentinformation.txt"
echo "17: REPO_URL=$REPO_URL" >> "$PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/www/greyheaddeploymentinformation.txt"
echo "18: ROLLBACK=$ROLLBACK" >> "$PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/www/greyheaddeploymentinformation.txt"
echo "" >> "$PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/www/greyheaddeploymentinformation.txt"
echo "--------------------------------------------------------------------------" >> "$PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/www/greyheaddeploymentinformation.txt"
echo "" >> "$PROJECTROOT/$PROJECTDIRECTORYNAME/current/code/www/greyheaddeploymentinformation.txt"

echo "All done"
set +x
exec 3>&-

echo ""
echo "Deployment completed. Please cat $LOGFILEDIR/$LOGFILE for full details of the deployment."
echo ""
echo "Now get back to work, slackers! ;o)"
echo ""

# All done!

