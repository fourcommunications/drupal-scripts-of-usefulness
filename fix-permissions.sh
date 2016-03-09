#!/bin/bash
# Script from https://www.drupal.org/node/244924
# Help menu
print_help() {
cat <<-HELP
This script is used to fix permissions of a Drupal installation
you need to provide the username of the user that you want to give
files/directories ownership.

You MUST run this script from the deployment-scripts directory at the root of
the Drupal 7 Project - the www and sites directories should both be located at
../ relative to this script.

Usage: (sudo) bash ${0##*/} --drupal_user=USER
Example: (sudo) bash ${0##*/} --drupal_user=monkey
HELP
exit 0
}


if [ $(id -u) != 0 ]; then
  printf "**************************************\n"
  printf "* Error: You must run this with sudo or root*\n"
  printf "**************************************\n"
  print_help
  exit 1
fi


# Make sure the www and sites directories can be found.
if ! [[ -d "../www" && -d "../sites" ]]; then
  echo "Couldn't verify that ../www and ../sites can be found."
  exit
fi


drupal_user=${2}
httpd_group=www-data


# Parse Command Line Arguments
while [ "$#" -gt 0 ]; do
  case "$1" in
    --drupal_user=*)
        drupal_user="${1#*=}"
        ;;
    --help) print_help;;
    *)
      printf "***********************************************************\n"
      printf "* Error: Invalid argument, run --help for valid arguments. *\n"
      printf "***********************************************************\n"
      exit 1
  esac
  shift
done


if [ -z "${drupal_user}" ] || [[ $(id -un "${drupal_user}" 2> /dev/null) != "${drupal_user}" ]]; then
  printf "*************************************\n"
  printf "* Error: Please provide a valid user. *\n"
  printf "*************************************\n"
  print_help
  exit 1
fi



cd ..
printf "Changing ownership of All The Things:\n user => "${drupal_user}" \t group => "${httpd_group}"\n"
chown -R ${drupal_user}:${httpd_group} .

printf "Changing permissions of all directories in the codebase to \"rwxr-x---\"...\n"
find . -type d -exec chmod 0750 '{}' \;

printf "Changing permissions of all files inside the codebase to \"rw-r-----\"...\n"
find . -type f -exec chmod 0640 '{}' \;

printf "Changing ownership and permissions on settings.php and local_databases.php:\n user => "${drupal_user}" \t group => "${httpd_group}"\n"
# In case it's a symlink...
chown -h ${drupal_user}:${httpd_group} settings.php
chown -h ${drupal_user}:${httpd_group} local_databases.php
# If it's a file...
chown ${drupal_user}:${httpd_group} settings.php
chown ${drupal_user}:${httpd_group} local_databases.php
chmod 0440 settings.php
chmod 0440 local_databases.php

printf "Changing ownership of \"privatefiles\" directory and its contents:\n user => "${httpd_group}" \t group => "${drupal_user}"\n"
# In case it's a symlink...
chown -h ${httpd_group}:${drupal_user} privatefiles

# If it's a symlink or directory, this should set the files inside privatefiles,
# and if it's a directory, this should also set the directory correctly.
chown -R ${httpd_group}:${drupal_user} privatefiles

printf "Changing permissions of \"privatefiles\" directory contents to \"0770\"...\n"
chmod 0770 privatefiles
chmod -R 0770 privatefiles

printf "Changing ownership of \"cache\" directory and its contents in \"www\":\n user => "${httpd_group}" \t group => "${drupal_user}"\n"
chown -R ${httpd_group}:${drupal_user} www/cache

printf "Changing permissions of \"cache\" directory contents in \"www\" to \"0770\"...\n"
chmod -R 0770 www/cache

printf "Changing permissions of all files inside all "files" directories in "sites" to "rw-rw----"...\n"
printf "Changing permissions of all directories inside all "files" directories in "sites" to "rwxrwx---"...\n"
for x in sites/*/files; do
  echo "Setting permissions on ${x}:"
  # For symlinks...
  chown -h ${httpd_group}:${drupal_user} ${x}

  # For directories...
  chmod 0770 ${x}
  chown -R ${httpd_group}:${drupal_user} ${x}

  find ${x} -type d -exec chmod 0770 '{}' \;
  find ${x} -type f -exec chmod 0660 '{}' \;
  echo "Finished setting ${x}."
  echo ""
done

printf "Making scripts in /deployment-scripts executable...\n"
chmod -R +x deployment-scripts/*.sh

echo "Done setting proper permissions on files and directories"
