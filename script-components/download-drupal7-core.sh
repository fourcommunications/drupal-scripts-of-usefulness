#!/usr/bin/env bash
# Note the starting directory.
STARTINGDIRECTORY=$(pwd)

# Default to Drupal 7.
DRUPALVERSION=7

# Parse command line arguments.
while [ "$#" -gt 0 ]; do
  case "$1" in
    --buildpath=*)
        BUILDPATH="${1#*=}"
        ;;
    --drupalversion=*)
        DRUPALVERSION="${1#*=}"
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

echo "
# This script will download Drupal 7 core to the directory specified in
# the --buildpath parameter (which must not end in a slash), remove any
# unwanted files, create the cache directory, create symlinks to the
# specified sites and profile directories and, if found, copy in a
# .htaccess file.

Options: --buildpath=$BUILDPATH
"

if [ ! -d "$BUILDPATH" ]; then
  printf "Error: Please specify the ABSOLUTE path to the deployment directory in --buildpath - '$BUILDPATH' is not a directory.\n"
  print_help
  exit 1
fi


# ---

echo "
***
Downloading the latest Drupal $DRUPALVERSION release..."

cd "$BUILDPATH/core"
drush dl "drupal-$DRUPALVERSION" --drupal-project-rename=www -y
cd "$BUILDPATH/core/www"

# ---

echo "Creating the cache directory..."

mkdir "$BUILDPATH/core/www/cache"

# ---

echo "Removing unwanted Drupal files: .gitignore, .htaccess, *.txt, sites/"

cd "$BUILDPATH/core/www"

rm .htaccess
rm .gitignore
rm *.txt
rm -rf sites

# ---

echo "Symlinking sites to $BUILDPATH/sites-common:"

ln -s "$BUILDPATH/sites-common" "$BUILDPATH/core/www/sites"

# ---

echo "Symlinking profiles/greyheadprofile to ../profiles/greyheadprofile:"

ln -s "$BUILDPATH/core/profiles/greyheadprofile" "$BUILDPATH/core/www/profiles/greyheadprofile"

# ---

echo "Symlinking profiles/fourprofile to ../profiles/fourprofile:"

ln -s "$BUILDPATH/core/profiles/fourprofile" "$BUILDPATH/core/www/profiles/fourprofile"

# ---

HTACCESSPATH="$BUILDPATH/multisite-template/htaccess-template"

if [ -e "$HTACCESSPATH" ]; then
  echo "Copying htaccess from $HTACCESSPATH:"

  NEWHTACCESSPATH="$BUILDPATH/core/www/.htaccess"

  cp "$HTACCESSPATH" "$NEWHTACCESSPATH"

  HTACCESSREDIRECTSPATH="$BUILDPATH/multisite-template/htaccess-template-redirects"

  if [ -e "$HTACCESSREDIRECTSPATH" ]; then
    echo "Copying htaccess redirects from $HTACCESSREDIRECTSPATH into $BUILDPATH/core/www/.htaccess:"

    if [ -e "$HTACCESSREDIRECTSPATH" ]; then
      # Copy the redirects file first, then delete it...
      cp "$HTACCESSREDIRECTSPATH" "$BUILDPATH/core/www/"
      cd "$BUILDPATH/core/www/"
      perl -pe 's/# {{REDIRECTS}}/`cat htaccess-template-redirects`/e' "$HTACCESSPATH" > "$NEWHTACCESSPATH"
      rm htaccess-template-redirects
    else
      echo "$HTACCESSREDIRECTSPATH doesn't exist or isn't readaboo. Damn."
    fi
  fi

else
  echo "ERROR: htaccess template not found at: $HTACCESSPATH"
fi

# ---

cd "$STARTINGDIRECTORY"

echo "Downloading of Drupal 7 core complete. Yay!
***
"
