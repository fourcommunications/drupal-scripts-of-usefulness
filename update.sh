#!/usr/bin/env bash
#set -e
clear
echo -n "
*************************************************************************

Update Local Dev Environment

*************************************************************************

This script will (only*) update a Drupal 7 site built with the Greyhead
build-drupal.sh script from
https://github.com/alexharries/drupal-scripts-of-usefulness/blob/master/build-drupal.sh

This script can do the following to update your local dev build with the
latest upstream changes for its codebase - you can choose which of these
steps you want to run:

1. @TODO: Update any Drupal contrib modules in the sites/all/modules/contrib and
   sites/[multisite]/modules/contrib directories.

2. @TODO: Update Drupal core.

3. 'git pull' changes from the parent repositories, and update any
   submodules.

4. For forked repos, 'git merge' changes from the upstream source
   repositories, and update any submodules as necessary.

5. 'git push' any changes back up to the parent repositories.

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

#echo -n "(Optional) What is the URL of the Drupal site, without 'http://' - e.g.
#www.example.com? You need to provide this if you want to configure the
#database connection using this script, or have Drupal automagically create the
#settings.this_site_url.info file.
#
#:"
#
#read SITEURI
#echo "
#
#Using: $SITEURI
#
#"

# ---

DEPLOYDIRECTORY=""

until [ -d "$DEPLOYDIRECTORY/drupal7_core" ]; do
  echo -n "
  What is the path to the Drupal build which you want to update, either
  relative to this script, or an absolute path, without the trailing slash?

  e.g. '../builds/monkey' or '/Volumes/Sites/4Com/builds/monkey'

  Tip: the drupal7_core directory should be at the path you enter, with
  '/drupal7_core' on the end, e.g. '../builds/monkey/drupal7_core' or
  '/Volumes/Sites/4Com/builds/monkey/drupal7_core'

  :"
  read DEPLOYDIRECTORY

  if [ ! -d "$DEPLOYDIRECTORY/drupal7_core" ]; then
    echo "

D'oh! $DEPLOYDIRECTORY/drupal7_core doesn't exist or isn't a directory.

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

cd "$DEPLOYDIRECTORY"
echo "cd-ing to deploy directory $DEPLOYDIRECTORY."

# Create a list of the directories we want to test for and update, if they're
# present.
declare -a DIRECTORYNAMES=("drupal7_core" "drupal7_multisite_template" "drupal7_sites_common" "drupal7_common_features" "scripts-of-usefulness" "drupal7_four_features" "drupal7_sites_projects")

for DIRECTORYNAME in "${DIRECTORYNAMES[@]}"
do
  echo "
Trying $DIRECTORYNAME..."

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
        echo "Pushing all to origin..."
        git push --all
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
