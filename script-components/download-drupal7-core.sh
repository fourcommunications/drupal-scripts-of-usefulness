#!/usr/bin/env bash
# Note the starting directory.
STARTINGDIRECTORY=$(pwd)

# Default to Drupal 7.
DRUPALVERSION=7

# Parse command line arguments.
while [ "$#" -gt 0 ]; do
  case "$1" in
    --corepath=*)
        COREPATH="${1#*=}"
        ;;
    --multisitename=*)
        MULTISITENAME="${1#*=}"
        ;;
    --drupalversion=*)
        DRUPALVERSION="${1#*=}"
        ;;
    --help) print_help;;
    *)
      printf "***********************************************************\n"
      printf "* Error: Invalid argument '$1', run --help for valid arguments. *\n"
      printf "***********************************************************\n"
      exit 1
  esac
  shift
done

echo "
# This script will download Drupal 7 core to the directory specified in
# the --corepath parameter (which must not end in a slash), remove any
# unwanted files, create the cache directory, create symlinks to the
# specified sites and profile directories and, if found, copy in a
# .htaccess file.

Options: --corepath=$COREPATH
"

if [ ! -d "$COREPATH" ]; then
  printf "Error: Please specify the ABSOLUTE path to the 'core' directory in the deployment directory with --corepath - '$COREPATH' is not a directory.\n"
  print_help
  exit 1
fi

# ---

echo "
***
Downloading the latest Drupal $DRUPALVERSION release..."

cd "$COREPATH"
drush dl "drupal-$DRUPALVERSION" --drupal-project-rename=www -y
cd "www"

# ---

echo "Creating the cache directory..."

mkdir "cache"

# ---

echo "Removing unwanted Drupal files: .gitignore, .htaccess, *.txt, sites/"

rm .htaccess
rm .gitignore
rm *.txt
rm -rf sites

# ---

echo "Symlinking sites to $COREPATH/sites-common:"

ln -s "../../sites-common" "sites"

# ---

echo "Symlinking profiles/greyheadprofile to ../profiles/greyheadprofile:"

ln -s "../../profiles/greyheadprofile" "profiles/greyheadprofile"

# ---

echo "Symlinking profiles/fourprofile to ../profiles/fourprofile:"

ln -s "../../profiles/fourprofile" "profiles/fourprofile"

# ---

HTACCESSPATH="../../multisite-template/htaccess-template"

if [ -e "$HTACCESSPATH" ]; then
  echo "Copying htaccess from $HTACCESSPATH:"

  NEWHTACCESSPATH="./.htaccess"

  cp "$HTACCESSPATH" "$NEWHTACCESSPATH"

  HTACCESSREDIRECTSPATH="../../sites-projects/$MULTISITENAME/htaccess-template-redirects"

  if [ -e "$HTACCESSREDIRECTSPATH" ]; then
    # Copy the redirects file first, then delete it...
    echo "Copying htaccess redirects from $HTACCESSREDIRECTSPATH into $COREPATH/core/www/.htaccess:"

    cp "$HTACCESSREDIRECTSPATH" "./"
    perl -pe 's/# {{REDIRECTS}}/`cat htaccess-template-redirects`/e' "$HTACCESSPATH" > "$NEWHTACCESSPATH"
    rm htaccess-template-redirects
  else
    echo "$HTACCESSREDIRECTSPATH doesn't exist or isn't readaboo. Damn."
  fi

else
  echo "ERROR: htaccess template not found at: $HTACCESSPATH"
fi

# ---

cd "$STARTINGDIRECTORY"

echo "Downloading of Drupal 7 core complete. Yay!
***
"
