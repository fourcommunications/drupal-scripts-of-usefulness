#!/usr/bin/env bash
# ***********************************************************
# Bash commands to be run during a deployment.
# ***********************************************************

# This script should be named vx.x.x.sh where "x.x.x" matches the tag version
# being deployed. For example, if you're deploying tag 1.2.9, this script would
# be called v1.2.9.sh.

# This script should be placed in the multisite directory for the multisite it's
# being run against, in a deployment-scripts/ subdirectory. For example, if
# the multisite is chapterliving, then this script should be placed at
# sites/chapterliving/deployment-scripts/v1.2.9.sh.

# This script should be run with the parameter --uri=[site URI], e.g.
# v1.x.x.sh --uri=monkey.greyhead.local.

# All your drush commands should use the --uri parameter, e.g.
# drush --uri="$SITEURI" cc all

# Please don't change the following lines - add your commands after the line
# "Add your commands below this line", below.

# Parse Command Line Arguments
while [ "$#" -gt 0 ]; do
  case "$1" in
    -uri=*)
        SITEURI="${1#*=}"
        ;;
#    -anothercommandlineparameter=*)
#        VARIABLEFORANOTHERCOMMANDLINEPARAMETER="${1#*=}"
#        echo "Tag name: $TAGNAME"
#        ;;
    -help) print_help;;
    *)
      printf "***********************************************************\n"
      printf "* Error: Invalid argument '${1#*=}', run --help for valid arguments. *\n"
      printf "***********************************************************\n"
      exit 1
  esac
  shift
done

# ***********************************************************
# Add your commands below this line
# ***********************************************************

# e.g.
# drush --uri="$SITEURI" cc all
