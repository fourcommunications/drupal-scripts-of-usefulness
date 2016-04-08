#!/usr/bin/env bash
#set -e
clear
echo -n "
*************************************************************************

Merge the Git repositories in a build into the current branch.

*************************************************************************

You should run this command after committing all your work, e.g. to
'develop', and then running ./checkout-branch.sh to switch to the next
branch.
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

SOURCEBRANCH=""

until [ ! "x$SOURCEBRANCH" = "x" ]; do
  echo -n "
What branch do you want to merge from? Usually, one of 'develop', 'rc', or 'master': "
  read SOURCEBRANCH
done

echo "Using: $SOURCEBRANCH."

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
Merging $SOURCEBRANCH on to the current branch in $DIRECTORYNAME..."

    cd "$DIRECTORYNAME"

    git merge "$SOURCEBRANCH"

    echo "Updating submodules..."
    git submodule update --recursive

    cd ..

    echo "Done. Next!

    ---
    "
  else
    echo "Directory $DIRECTORYNAME not found in $DEPLOYDIRECTORY. Sad face. Moving on..."
  fi
done
