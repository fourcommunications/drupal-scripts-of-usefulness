#!/usr/bin/env bash
#set -e
clear
echo -n "
*************************************************************************

Switch to another branch

*************************************************************************

This script will switch a build to another branch.

*************************************************************************

DIRE WARNING: you should make sure there are no uncommitted changes in
the Git checkouts in the build which you want to update. This script will
probably fail and will almost certainly mangle All The Things if your
working copy isn't 'clean'.

*************************************************************************

* But if you didn't throw your Drupal 7 install together with Greyhead's
builder script, why would you _want_ to use this script to update your
defenceless Drupal install...? ;o)

*************************************************************************
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

NEWBRANCH=""

until [ ! "x$NEWBRANCH" = "x" ]; do
  echo -n "
What branch do you want to check out? Usually, one of 'develop', 'rc', or 'master': "
  read NEWBRANCH
done

echo "Using: $NEWBRANCH."

# ---

# Create a list of the directories we want to test for and check out, if they're
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
Checking out branch $NEWBRANCH in $DIRECTORYNAME..."

    cd "$DIRECTORYNAME"

    # Get branch name
    BRANCH=$(git rev-parse --symbolic-full-name --abbrev-ref HEAD)

    echo "Current branch is: $BRANCH"

    # Get status of current working directory.
    GITSTATUS="$(git status)"
    if [[ "$GITSTATUS" == *"working directory clean"* ]]; then
      echo "Working directory appears clean - nothing to commit - so we'll try to fetch and check out the branch..."

      git fetch
      git checkout -b "$NEWBRANCH" "remotes/origin/$NEWBRANCH"
    else
      echo "
      ---
      ERROR: couldn't verify that the current checkout is clean - the text 'working directory clean' wasn't found in the output of a git status:
      "

      git status

      echo "
      ---
      Please clean up the directory (or fix this script :)."
    fi

    cd ..

    echo "Done. Next!

    ---
    "
  else
    echo "Directory $DIRECTORYNAME not found in $DEPLOYDIRECTORY. Sad face. Moving on..."
  fi
done
