#!/usr/bin/env bash
#set -e
clear
echo -n "
*************************************************************************

Get the git status of the git checkouts in a build.

*************************************************************************
"

# ---

DEPLOYDIRECTORY=""

until [ -d "$DEPLOYDIRECTORY/core" ]; do
  echo -n "
  What is the path to the Drupal build which you want to update, either
  relative to this script, or an absolute path, without the trailing slash?

  e.g. '../builds/monkey' or '/Volumes/Sites/4Com/builds/monkey'

  Tip: the core directory should be at the path you enter, with
  '/core' on the end, e.g. '../builds/monkey/core' or
  '/Volumes/Sites/4Com/builds/monkey/core'

  :"
  read DEPLOYDIRECTORY

  if [ ! -d "$DEPLOYDIRECTORY/core" ]; then
    echo "

D'oh! $DEPLOYDIRECTORY/core doesn't exist or isn't a directory.

Please try again..."
  fi
done

echo "Using: $DEPLOYDIRECTORY."

# ---

# Create a list of the directories we want to test for and update, if they're
# present.
DIRECTORYNAMES=(core "multisite-template" "sites-common" "features" "scripts-of-usefulness" "four-features" "sites-projects")

cd "$DEPLOYDIRECTORY"

for DIRECTORYNAME in "${DIRECTORYNAMES[@]}"
do
  echo "
Trying '$DIRECTORYNAME'..."

  echo "Current directory: $(pwd)"

  if [ -d "$DIRECTORYNAME" ]; then

    echo "
Checking git status in $DIRECTORYNAME..."

    cd "$DIRECTORYNAME"

    git status

    cd ..

    echo "Done. Next!

    ---
    "
  else
    echo "Directory $DIRECTORYNAME not found in $DEPLOYDIRECTORY. Sad face. Moving on..."
  fi
done
