#!/bin/bash

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
      printf "* Error: Invalid argument, run --help for valid arguments. *\n"
      printf "***********************************************************\n"
      exit 1
  esac
  shift
done

echo "
This script is used to turn off the Production Settings feature,
enable the Development Settings feature, and revert those settings.

Parameters:

--uri: the site's URI, e.g. manbo.4com.local

Options: --uri=$URI
"

URISTRING=""
if [ ! "x$URI" = "x" ]; then
  # Also specify the URI for Drush.
  URISTRING="--uri=$URI"
fi

echo "Disabling production_settings, boost_config, and advagg settings, and enabling development_settings, and reverting the development_settings feature."

drush "$URISTRING" dis production_settings advanced_aggregation_settings advagg boost_config boost -y
drush "$URISTRING" en development_settings -y
drush "$URISTRING" fr development_settings -y
drush "$URISTRING" cc all

echo "All done."
