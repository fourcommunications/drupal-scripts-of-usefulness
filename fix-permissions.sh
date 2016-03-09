#!/bin/bash
# Script from https://www.drupal.org/node/244924
# Help menu
print_help() {
cat <<-HELP
This script is used to fix permissions of a Drupal installation
you need to provide the username of the user that you want to give
files/directories ownership.

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
printf "Changing ownership of all files:\n user => "${drupal_user}" \t group => "${httpd_group}"\n"
chown -R ${drupal_user}:${httpd_group} .


#cd deployment-scripts/$drupal_path
#printf "Changing ownership of all contents of "${drupal_path}":\n user => "${drupal_user}" \t group => "${httpd_group}"\n"
#echo "chown -R ${drupal_user}:${httpd_group} ."
#chown -R ${drupal_user}:${httpd_group} .


printf "Changing permissions of all directories in the codebase to \"rwxr-x---\"...\n"
find . -type d -exec chmod 0750 '{}' \;


printf "Changing permissions of all files inside the codebase to \"rw-r-----\"...\n"
find . -type f -exec chmod 0640 '{}' \;


printf "Changing ownership of \"privatefiles\" directory and its contents:\n user => "${httpd_group}" \t group => "${drupal_user}"\n"
chown -R ${httpd_group}:${drupal_user} privatefiles/


printf "Changing permissions of \"privatefiles\" directory contents to \"0770\"...\n"
chmod -R 0770 privatefiles/


printf "Changing ownership of \"cache\" directory and its contents in \"www\":\n user => "${httpd_group}" \t group => "${drupal_user}"\n"
chown -R ${httpd_group}:${drupal_user} www/cache


printf "Changing permissions of \"cache\" directory contents in \"www\" to \"0770\"...\n"
chmod -R 0770 www/cache


printf "Changing ownership of \"files\" directories and their contents in \"sites\":\n user => "${httpd_group}" \t group => "${drupal_user}"\n"
#cd sites
find sites -type d -name files -exec chown -R ${httpd_group}:${drupal_user} '{}' \;


printf "Changing permissions of \"files\" directories in \"sites\" to \"rwxrwx---\"...\n"
find sites -type d -name files -exec chmod 0770 '{}' \;


printf "Changing ownership of \"files\" symlinks in \"sites\":\n user => \"${httpd_group}\" \t group => \"${drupal_user}\"\n"
#cd sites
find sites -xtype l -name files -exec chown -h ${httpd_group}:${drupal_user} '{}' \;


printf "Changing permissions of \"files\" symlinks in \"sites\" to \"0770\"...\n"
find sites -xtype l -name files -exec chmod 0770 '{}' \;


printf "Changing permissions of all files inside all "files" directories in "sites" to "rw-rw----"...\n"
printf "Changing permissions of all directories inside all "files" directories in "sites" to "rwxrwx---"...\n"
for x in sites/*/files; do
  find ${x} -type d -exec chmod 0770 '{}' \;
  find ${x} -type f -exec chmod 0660 '{}' \;
done


printf "Changing ownership of "cache" directory and its contents in "${drupal_path}/":\n user => "${httpd_group}" \t group => "${drupal_user}"\n"
#cd ../
chown -R ${httpd_group}:${drupal_user} www/cache


printf "Changing permission of "privatefiles" directory and contents in "${drupal_path}/" to "rwxrwx---"...\n"
chmod -R 0770 www/cache


printf "Changing ownership of "privatefiles" directory and its contents in "${drupal_path}/../":\n user => "${httpd_group}" \t group => "${drupal_user}"\n"
#cd ../
chown -R ${httpd_group}:${drupal_user} privatefiles


printf "Changing permission of "privatefiles" directory and contents in "${drupal_path}/../" to "rwxrwx---"...\n"
chmod -R 0770 privatefiles


echo "Done setting proper permissions on files and directories"
