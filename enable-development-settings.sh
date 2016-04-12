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

echo "Disabling production_settings, boost_config, and advagg settings, and enabling development_settings, and reverting the development_settings feature."

drush dis production_settings advanced_aggregation_settings advagg boost_config boost -y --uri="$URI"
drush en development_settings -y --uri="$URI"
drush fr development_settings -y --uri="$URI"
drush cc all

echo "All done."
