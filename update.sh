#!/usr/bin/env bash
#set -e
clear
echo -n "
*************************************************************************

Update a Drupal 7 build

*************************************************************************

This script will (only*) update a Drupal 7 site built with the Greyhead
build-drupal.sh script from
https://github.com/alexharries/drupal-scripts-of-usefulness/blob/master/build.sh

This script can do the following to update a build - you can choose which of
these steps you want to run:

1. Update Drupal contrib modules in the sites/all/modules/contrib and
   sites/[multisite]/modules/contrib directories.

2. Update Drupal core.

3. 'git pull' changes from the parent repositories, and update any
   submodules.

4. For forked repos, 'git merge' changes from the upstream source
   repositories, and update any submodules as necessary.

5. 'git push' any changes back up to the origin and upstream repositories.

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



What is the multisite directory name of this build?

This will be the directory in sites/ which contains modules, themes and files
for this build.

This is required if you want to run Drupal core or contrib module updates.

If you leave this blank, this script will skip the Drupal core and contrib
updates step.

:"

read MULTISITENAME
echo "

Using: $MULTISITENAME.

"

# ---

if [ ! "x$MULTISITENAME" = "x" ]; then
  echo -n "What is the URL of the Drupal site, without 'http://' - e.g.
  www.example.com? You need to provide this to run updates for Drupal core
  or contrib modules.

  :"

  read SITEURI
  echo "

  Using: $SITEURI

  "
fi

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

echo "Using: $DEPLOYDIRECTORY.

"

# ---

# Find out if we're updating Drupal core.
UPDATECORE=0
UPDATECONTRIB=0
if [ ! "x$MULTISITENAME" = "x" ]; then
  echo -n "
Update Drupal core? Y/n: "

  old_stty_cfg=$(stty -g)
  stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
  if echo "$answer" | grep -iq "^y" ;then
    UPDATECORE=1
  fi

  echo -n "
Update contrib modules? Y/n: "

  old_stty_cfg=$(stty -g)
  stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
  if echo "$answer" | grep -iq "^y" ;then
    UPDATECONTRIB=1
  fi
fi

# Find out if we're pulling from origin.
PULLORIGIN=0
echo -n "
'git pull' changes from origin? Y/n: "

old_stty_cfg=$(stty -g)
stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
if echo "$answer" | grep -iq "^y" ;then
  PULLORIGIN=1
fi

# Find out if we're pulling from upstream.
PULLUPSTREAM=0
echo -n "
Merge changes from upstream repos, where configured? Y/n: "

old_stty_cfg=$(stty -g)
stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
if echo "$answer" | grep -iq "^y" ;then
  PULLUPSTREAM=1
fi

# Find out if we're pushing back to origin.
PUSHORIGIN=0
echo -n "
'git push' changes to origin? Y/n: "

old_stty_cfg=$(stty -g)
stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
if echo "$answer" | grep -iq "^y" ;then
  PUSHORIGIN=1
fi

# ---

# Find out if we're pushing back to upstream.
PUSHUPSTREAM=0
echo -n "
'git push' changes to upstream remotes? Y/n: "

old_stty_cfg=$(stty -g)
stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
if echo "$answer" | grep -iq "^y" ;then
  PUSHUPSTREAM=1
fi

# ---

echo "cd-ing to deploy directory $DEPLOYDIRECTORY."
cd "$DEPLOYDIRECTORY"

echo "Current directory: $(pwd)

Listing the build directory contents...
"

ls -la

echo "
Hopefully that all looked correct...?
"

# If we're updating Drupal core and/or contrib modules, cd to the multisite
# directory and run drush up now.
if [ ! "x$SITEURI" = "x" ]; then
  if [ "$UPDATECORE" = 1 ] || [ "$UPDATECONTRIB" = 1 ]; then
    cd "core/www/sites/$MULTISITENAME"

    if [ "$UPDATECORE" = 1 ]; then
      echo "Updating Drupal core..."
      drush --uri="$SITEURI" up drupal
    fi

    if [ "$UPDATECONTRIB" = 1 ]; then
      echo "Updating contrib modules..."
      drush --uri="$SITEURI" up --no-core
    fi

    # Cd back to the build directory.
    cd ../../../..
  fi
fi

# ---

# Create a list of the directories we want to test for and update, if they're
# present.
DIRECTORYNAMES=(core "multisite-template" "sites-common" "features" "scripts-of-usefulness" "four-features" "sites-projects")

for DIRECTORYNAME in "${DIRECTORYNAMES[@]}"
do
  echo "
Trying '$DIRECTORYNAME'..."

  echo "Current directory: $(pwd)"

  if [ -d "$DIRECTORYNAME" ]; then
    echo "
Updating $DIRECTORYNAME..."

    cd "$DIRECTORYNAME"

    # Get branch name
    BRANCH=$(git rev-parse --symbolic-full-name --abbrev-ref HEAD)

    echo "Branch is: $BRANCH"

    # Get status of current working directory.
    GITSTATUS="$(git status)"
    if [[ "$GITSTATUS" == *"working directory clean"* ]]; then
      echo "Working directory appears clean - nothing to commit - so we'll try updates..."

      echo "Updating remotes..."
      git remote update

      echo "Running git fetch..."
      git fetch

      if [ "$PULLORIGIN" = 1 ]; then
        echo "Pulling from origin..."
        git pull
      fi

      # Merge upstream
      GITREMOTES="$(git remote show)"
      if [[ "$PULLUPSTREAM" = 1 && "$GITREMOTES" == *"upstream"* ]]; then
        echo "Pulling from upstream..."
        git fetch upstream; git merge upstream/$BRANCH
      else
        echo "No upstream remote found."
      fi

      echo "Updating submodules..."
      git submodule update --init --recursive
      git submodule update --recursive

      if [ "$PUSHORIGIN" = 1 ]; then
        echo "Pushing branch $BRANCH to origin..."
        git push
      fi

      if [ "$PUSHUPSTREAM" = 1 ]; then
        # Push upstream
        if [[ "$PULLUPSTREAM" = 1 && "$GITREMOTES" == *"upstream"* ]]; then
          echo "Pushing branch $BRANCH to upstream..."
          git push upstream "$BRANCH"
        else
          echo "No upstream remote found."
        fi
      fi
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
