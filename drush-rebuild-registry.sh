#!/usr/bin/env bash

# Parse command line arguments.
while [ "$#" -gt 0 ]; do
  case "$1" in
    --buildpath=*)
        BUILDPATH="${1#*=}"
        ;;
    --multisitename=*)
        MULTISITENAME="${1#*=}"
        ;;
    --uri=*)
        URI="${1#*=}"
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
# This script will rebuild the Drupal registry and forcibly flush caches.
#
#
# Parameters:
#
# --buildpath: the ABSOLUTE path to the build directory (i.e. the directory
# which contains the core/ directory). This must not end in a slash.
#
# If you provide this, you must also provide --multisitename.
#
#
# --multisitename: the multisite directory name
# e.g. --multisitename=manbo
#
# If you provide this, you must also provide --buildpath.
#
#
# --uri: the site's URI, e.g. manbo.4com.local

Options: --buildpath=$BUILDPATH --uri=$URI --multisitename=$MULTISITENAME
"

if [ ! "x$BUILDPATH" = "x" ]; then
  if [ ! -d "$BUILDPATH/core/www/sites/$MULTISITENAME" ]; then
    printf "Error: Please specify the ABSOLUTE path to the deployment directory in --buildpath - '$BUILDPATH' is not a directory.\n"
    print_help
    exit 1
  fi

  if [ "x$MULTISITENAME" = "x" ]; then
    printf "Error: Please specify the the multisite directory name in --multisitename, e.g. --multisitename=manbo\n"
    print_help
    exit 1
  fi

  cd "$BUILDPATH/core/www/sites/$MULTISITENAME"
fi

# Forcibly wipe the cache tables; this step is run before any others
# make sure any cached CTools include paths are regenerated.
drush sqlq 'truncate table cache' --uri="$URI"

# Now we run drush cc all, before we rebuild the registry; this is
# yet another CTools workaround.
drush cc all --uri="$URI"

# At last, we can reset the registry, which should avoid any annoying
# 500 errors if anything's been moved.
drush rr --fire-bazooka --uri="$URI"

# Clear caches and get a status report.
drush cc all --uri="$URI"
drush status --uri="$URI"

echo "Rebuild of registry complete. Yay!
***
"
