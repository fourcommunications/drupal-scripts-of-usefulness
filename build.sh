#!/usr/bin/env bash
#set -e
clear

# Note the starting directory.
STARTINGDIRECTORY=$(pwd)

echo "
*************************************************************************

This is a rough and ready script to build a Drupal codebase.

Local, development and staging builds contain the Git repositories so you
can make changes and commit them back to the remotes.

Live builds don't contain any Git files, database credentials, the Drupal
files directory, or other development tools, and are designed to be
uploaded to a live server for deployment with the deploy.sh script.

*************************************************************************

Once this script has completed, you will have a directory structure
similar to this (not all contents shown for brevity, and the live
build structure won't contain all these parts):

/ drupal7_core
  / configuration
  / patches
  / privatefiles
  / profiles
    / greyhead
  / www
    / (Drupal 7 - index.php, cron.php, etc)
    / sites -> symlink to /drupal7_sites_common
/ drupal7_sites_common
  / all
    / drush -> symlink to /drupal7_sites_projects/_drush_aliases
    / libraries
    / modules
      / contrib
      / custom
        / greyhead_* -> various greyhead modules (Git submodules)
      / features -> optional symlink to /drupal7_common_features
      / four-features -> optional symlink to /drupal7_four_features
    / themes
      / bootstrap
      / greyhead_bootstrap (Git submodule)
  / default
  / [your multisite name] -> optional symlink to /drupal7_sites_projects/[your multisite name]
  . sites.php
/ drupal7_sites_projects
  / _drush_aliases
  / [your multisite name]
    / modules
      / custom
        / project_customisations (custom module)
    / themes
      / [your project name]_bootstrap_subtheme (optional)
    / files -> symlink to the project's files directory
    . settings.php
    . settings.site_urls.php
/ drupal7_multisite_template
/ greyhead_multisitemaker
. local_databases.php (your database settings file)
. local_settings.php

*************************************************************************

Note: your webroot should point to /drupal7_core/www

*************************************************************************

These directories will contain the following Git repositories:

drupal7_core: this contains a copy of the latest release of Drupal 7, and the
code which configures the Drupal site for your local installation such as
setting development variables, etc.

drupal7_sites_common: this provides the Drupal /sites/all and /sites/default
directories, /sites/sites.php and a couple of other common files. This repo
will be symlinked into drupal7_core/www/sites

drupal7_multisite_template: provides a multisite directory to create a new
multisite in the codebase.

A choice of two Features repos:

Either: alexharries/drupal7_common_features, at
drupal7_core/www/sites/all/modules/features

Or: (Four Communications only) drupal7_four_features, at
drupal7_core/www/sites/all/modules/four-features

drupal7_sites_projects: the directory where your individual multisite projects
are kept. This will either be a checkout from a repo URL you specify,
one of two pre-configured Github repos (as long as you have access to clone
them), or a freshly-created directory which you will need to save, e.g. by
creating a git repository for.

This will contain the multisite directory with code (modules, themes, etc)
specifically for this Drupal website build. Individual projects' directories
are then symlinked into the drupal7_core/www/sites/ directory.

greyhead_multisitemaker: Multisite Maker is a quick 'n dirty way for you to
let non-technical Drupal users self-serve by setting up their own throwaway
Drupal instances. To enable, create a symlink from the www directory to the
multisitemaker directory; see
https://github.com/fourcommunications/greyhead_multisitemaker for full
destructions.

*************************************************************************
*************************************************************************

"

until [ ! "x$BUILDTYPE" = "x" ]; do
  echo -n "What type of build is this?

1: LOCAL
2: DEV
3: STAGING

(Live builds will be coming shortly. To deploy a live build, see live-deploy.sh)


Important information about branches
------------------------------------
Note that LOCAL and DEV builds will check out the 'develop' branch of the
drupal7_sites_projects repo, if you choose to download one; STAGING builds
will use the 'rc' branch, while LIVE builds use MASTER, so you need to make
sure you have merged from the dev branch to rc to move from development into
testing, and merge from the rc branch to master once everything passes
testing.

: "

  old_stty_cfg=$(stty -g)
  stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
  if echo "$answer" | grep -iq "^1" ;then
    BUILDTYPE="LOCAL"
  elif echo "$answer" | grep -iq "^2" ;then
    BUILDTYPE="DEV"
  elif echo "$answer" | grep -iq "^3" ;then
    BUILDTYPE="STAGING"
  elif echo "$answer" | grep -iq "^4" ;then
    BUILDTYPE="LIVE"
  fi
done

echo "Build type: $BUILDTYPE"

# Determine the branches to use for projects.
if [[ ${BUILDTYPE} = "LOCAL" || $BUILDTYPE = "DEV" ]]; then
  PROJECTSBRANCH="develop"
elif [[ ${BUILDTYPE} = "STAGING" ]]; then
  PROJECTSBRANCH="rc"
elif [[ ${BUILDTYPE} = "LIVE" ]]; then
  PROJECTSBRANCH="master"
fi

echo -n "
*************************************************************************

What is the multisite directory name for this build?

This will be the directory in sites/ which contains modules, themes and files
for this build.

If you leave this blank, you will have to manually create the multisite
directory from the multisites template (or build it yourself of course).

You can enter 'default' if you want this site to use the sites/default
directory, but this will cause problems if you want to deploy this code to a
dev, staging or live server using these deployment scripts.

:"

read MULTISITENAME
echo "

Using: $MULTISITENAME.

"

# Remove hyphens from $MULTISITENAME, if any exist.
MULTISITENAMENOHYPHENS=$(echo $MULTISITENAME | sed 's/[\._-]//g')

# ---

echo -n "
*************************************************************************

(Optional) What is the URL of this build of the Drupal site, without
'http://' - e.g. 'www.example.com'?

You need to provide this if you want to configure the database connection
using this script, or have Drupal automagically create the
settings.this_site_url.info file.

You must provide this if you are building for a live deployment, unless
you know that the settings.site_urls.info file contains the live site's
URL.

:"

read SITEURI
echo "

Using: $SITEURI

"

# ---

BUILDPATH_SUBDIR=$MULTISITENAME
if [ "x$BUILDPATH_SUBDIR" = "x" ]; then
  BUILDPATH_SUBDIR="default"
fi

PWD=$(pwd)
BUILDPATH_DEFAULT="$PWD/../builds/$BUILDPATH_SUBDIR"

until [ -d "$BUILDPATH" ]; do
  echo -n "
*************************************************************************

What directory should we build Drupal in, without a trailing slash?

This directory should not already exist.

Leave blank to use the default: '$BUILDPATH_DEFAULT'
:"
  read BUILDPATH_ENTERED
  if [ ! "x$BUILDPATH_ENTERED" = "x" ]; then
    BUILDPATH=$BUILDPATH_ENTERED
  else
    BUILDPATH=$BUILDPATH_DEFAULT
  fi

  if [ -d "$BUILDPATH" ]; then
    echo "
  ***************************************************************
  WARNING: Directory already exists; please make sure it's empty.
  ***************************************************************
  "
  else
    echo "Making directory $BUILDPATH..."
    mkdir -p "$BUILDPATH"
  fi
done

echo "
Using: $BUILDPATH.

"

# Create a directory to track the build progress - we could use this to allow
# restarting of the script, if interrupted.
mkdir "$BUILDPATH/build-information"

# Create files to represent variables.
echo "$BUILDPATH" > "$BUILDPATH/build-information/BUILDPATH.txt"
echo "$BUILDTYPE" > "$BUILDPATH/build-information/BUILDTYPE.txt"
echo "$SITEURI" > "$BUILDPATH/build-information/SITEURI.txt"
echo "$MULTISITENAME" > "$BUILDPATH/build-information/MULTISITENAME.txt"
echo "$PROJECTSBRANCH" > "$BUILDPATH/build-information/PROJECTSBRANCH.txt"

# ---

# Only request files path if this isn't a live build.
if [ ! ${BUILDTYPE} = "LIVE" ]; then

  FILESPATHDEFAULT="$BUILDPATH/../../files/$MULTISITENAME"
  until [ -d "$FILESPATH" ]; do
    echo -n "
  *************************************************************************

  What is the absolute path of the Drupal files directory (including the
  directory itself), and without trailing slash?

  A symlink to this directory will be created in your multisite's directory.

  Default: '$FILESPATHDEFAULT': "
    read FILESPATHENTERED
    if [ "x$FILESPATHENTERED" = "x" ]; then
      FILESPATH="$FILESPATHDEFAULT"
    else
      FILESPATH="$FILESPATHENTERED"
    fi
    echo "

    Using: $FILESPATH - attempting to make the directory if it doesn't
    already exist..."

    mkdir -p "$FILESPATH"

    if [ ! -d "$FILESPATH" ]; then
      echo "Oh no! Unable to create the directory at $FILESPATH - does this script have permission to make directories there?"
    fi
  done

fi

# ---

GITHUBUSER_DEFAULT="fourcommunications"

# ---

GITHUBUSER_CORE=$GITHUBUSER_DEFAULT

echo -n "
*************************************************************************

What is the Github account from which you want to clone the drupal7_core repo? Leave blank to use the default: '$GITHUBUSER_CORE'
:"
read GITHUBUSER_CORE_ENTERED
if [ ! "x$GITHUBUSER_CORE_ENTERED" = "x" ]; then
  GITHUBUSER_CORE=$GITHUBUSER_CORE_ENTERED
fi
echo "Using: $GITHUBUSER_CORE

Cloning Drupal core from $GITHUBUSER_CORE..."

cd "$BUILDPATH"
git clone --recursive "https://github.com/$GITHUBUSER_CORE/drupal7_core.git" drupal7_core
cd "$BUILDPATH/drupal7_core"
git checkout master
git config core.fileMode false

# ---

echo -n "
*************************************************************************

Do you want to add an upstream remote for drupal7_core? E.g. if this is a
forked repo, you can add the fork's source repo so you can then pull in changes
by running: git fetch upstream; git checkout master; git merge upstream/master

Press Y/n: "

old_stty_cfg=$(stty -g)
stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
if echo "$answer" | grep -iq "^y" ;then
  # Add remotes.
  GITHUBUSER_CORE_REMOTE=$GITHUBUSER_DEFAULT
  echo -n "
*************************************************************************

What is the upstream Github account to pull changes from?
Leave blank to use the default: '$GITHUBUSER_CORE_REMOTE'
: "

  read GITHUBUSER_CORE_REMOTE_ENTERED
  if [ ! "x$GITHUBUSER_CORE_REMOTE_ENTERED" = "x" ]; then
    GITHUBUSER_CORE_REMOTE=${GITHUBUSER_CORE_REMOTE_ENTERED}
  fi

  cd "$BUILDPATH/drupal7_core"

  echo "Using: $GITHUBUSER_CORE_REMOTE. Adding remote..."

  REMOTE="https://github.com/$GITHUBUSER_CORE_REMOTE/drupal7_core.git"

  git remote add upstream ${REMOTE}

  echo "Remote '$REMOTE' added. Please check the following output is correct:

  "
  git remote -v

  echo "Continuing..."

fi

# ---

GITHUBUSER_SITES_COMMON=${GITHUBUSER_CORE}

echo -n "
*************************************************************************

What is the Github account from which you want to clone the drupal7_sites_common repo? Leave blank to use the default: '$GITHUBUSER_SITES_COMMON'
: "
read GITHUBUSER_SITES_COMMON_ENTERED
if [ ! "x$GITHUBUSER_SITES_COMMON_ENTERED" = "x" ]; then
  GITHUBUSER_SITES_COMMON=$GITHUBUSER_SITES_COMMON_ENTERED
fi
echo "Using: $GITHUBUSER_SITES_COMMON

Cloning Drupal sites common from $GITHUBUSER_SITES_COMMON..."

cd "$BUILDPATH"
git clone --recursive "https://github.com/$GITHUBUSER_SITES_COMMON/drupal7_sites_common.git" drupal7_sites_common
cd "$BUILDPATH/drupal7_sites_common"
git checkout master
git config core.fileMode false

# ---

echo -n "
*************************************************************************

Do you want to add an upstream remote for drupal7_sites_common? E.g. if this is a
forked repo, you can add the fork's source repo so you can then pull in changes
by running: git fetch upstream; git checkout master; git merge upstream/master

Press Y/n: "

old_stty_cfg=$(stty -g)
stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
if echo "$answer" | grep -iq "^y" ;then
  # Add remotes.
  GITHUBUSER_SITES_COMMON_REMOTE=$GITHUBUSER_CORE_REMOTE
  echo -n "
*************************************************************************

What is the upstream Github account to pull changes from? Leave blank to use the default: '$GITHUBUSER_SITES_COMMON_REMOTE'
: "
  read GITHUBUSER_SITES_COMMON_REMOTE_ENTERED
  if [ ! "x$GITHUBUSER_SITES_COMMON_REMOTE_ENTERED" = "x" ]; then
    GITHUBUSER_SITES_COMMON_REMOTE=$GITHUBUSER_SITES_COMMON_REMOTE_ENTERED
  fi

  cd "$BUILDPATH/drupal7_sites_common"

  echo "Using: $GITHUBUSER_SITES_COMMON_REMOTE. Adding remote..."

  REMOTE="https://github.com/$GITHUBUSER_SITES_COMMON_REMOTE/drupal7_sites_common.git"

  git remote add upstream $REMOTE

  echo "Remote '$REMOTE' added. Please check the following output is correct:

  "
  git remote -v

  echo "
  Continuing...
  "

fi


# ---

# Only clone multisite template if this is a LOCAL build.
if [ ${BUILDTYPE} = "LOCAL" ]; then

  GITHUBUSER_MULTISITE_TEMPLATE=$GITHUBUSER_SITES_COMMON

  echo -n "
  *************************************************************************

  What is the Github account from which you want to clone the drupal7_multisite_template repo? Leave blank to use the default: '$GITHUBUSER_MULTISITE_TEMPLATE'
  : "
  read GITHUBUSER_MULTISITE_TEMPLATE_ENTERED
  if [ ! "x$GITHUBUSER_MULTISITE_TEMPLATE_ENTERED" = "x" ]; then
    GITHUBUSER_MULTISITE_TEMPLATE=$GITHUBUSER_MULTISITE_TEMPLATE_ENTERED
  fi
  echo "Using: $GITHUBUSER_MULTISITE_TEMPLATE

  Cloning Drupal multisite template from $GITHUBUSER_MULTISITE_TEMPLATE..."

  cd "$BUILDPATH"
  git clone --recursive "https://github.com/$GITHUBUSER_MULTISITE_TEMPLATE/drupal7_multisite_template.git" drupal7_multisite_template
  cd "$BUILDPATH/drupal7_multisite_template"
  git checkout master
  git config core.fileMode false

  # ---

  echo -n "
  *************************************************************************

  Do you want to add an upstream remote for drupal7_multisite_template? E.g. if this is a
  forked repo, you can add the fork's source repo so you can then pull in changes
  by running: git fetch upstream; git checkout master; git merge upstream/master

  Y/n: "

  old_stty_cfg=$(stty -g)
  stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
  if echo "$answer" | grep -iq "^y" ;then
    # Add remotes.
    GITHUBUSER_MULTISITE_TEMPLATE_REMOTE=$GITHUBUSER_SITES_COMMON_REMOTE
    echo -v "
  *************************************************************************

  What is the upstream Github account to pull changes from? Leave blank to use the default: '$GITHUBUSER_MULTISITE_TEMPLATE_REMOTE'
  : "
    read GITHUBUSER_MULTISITE_TEMPLATE_REMOTE_ENTERED
    if [ ! "x$GITHUBUSER_MULTISITE_TEMPLATE_REMOTE_ENTERED" = "x" ]; then
      GITHUBUSER_MULTISITE_TEMPLATE_REMOTE=$GITHUBUSER_MULTISITE_TEMPLATE_REMOTE_ENTERED
    fi

    cd "$BUILDPATH/drupal7_multisite_template"

    echo "Using: $GITHUBUSER_MULTISITE_TEMPLATE_REMOTE. Adding remote..."

    REMOTE="https://github.com/$GITHUBUSER_MULTISITE_TEMPLATE_REMOTE/drupal7_multisite_template.git"

    git remote add upstream $REMOTE

    echo "Remote '$REMOTE' added. Please check the following output is correct:

    "
    git remote -v

    echo "
    Continuing...
    "

  fi
fi

# Now multisitemaker.
GITHUBUSER_MULTISITEMAKER=$GITHUBUSER_SITES_COMMON

echo -n "
*************************************************************************

What is the Github account from which you want to clone the greyhead_multisitemaker repo? Leave blank to use the default: '$GITHUBUSER_MULTISITEMAKER'
: "
read GITHUBUSER_MULTISITEMAKER_ENTERED
if [ ! "x$GITHUBUSER_MULTISITEMAKER_ENTERED" = "x" ]; then
  GITHUBUSER_MULTISITEMAKER="$GITHUBUSER_MULTISITEMAKER_ENTERED"
fi
echo "Using: $GITHUBUSER_MULTISITEMAKER

Cloning Drupal multisite template from $GITHUBUSER_MULTISITEMAKER..."

cd "$BUILDPATH"
git clone --recursive "https://github.com/$GITHUBUSER_MULTISITEMAKER/greyhead_multisitemaker.git" greyhead_multisitemaker
cd "$BUILDPATH/greyhead_multisitemaker"
git checkout master
git config core.fileMode false

# ---

echo -n "
*************************************************************************

Do you want to add an upstream remote for greyhead_multisitemaker? E.g. if this is a
forked repo, you can add the fork's source repo so you can then pull in changes
by running: git fetch upstream; git checkout master; git merge upstream/master

Y/n: "

old_stty_cfg=$(stty -g)
stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
if echo "$answer" | grep -iq "^y" ;then
  # Add remotes.
  GITHUBUSER_MULTISITEMAKER_REMOTE="$GITHUBUSER_MULTISITE_TEMPLATE_REMOTE"
  echo -v "
*************************************************************************

What is the upstream Github account to pull changes from? Leave blank to use the default: '$GITHUBUSER_MULTISITEMAKER_REMOTE'
: "
  read GITHUBUSER_MULTISITEMAKER_REMOTE_ENTERED
  if [ ! "x$GITHUBUSER_MULTISITEMAKER_REMOTE_ENTERED" = "x" ]; then
    GITHUBUSER_MULTISITEMAKER_REMOTE="$GITHUBUSER_MULTISITEMAKER_REMOTE_ENTERED"
  fi

  cd "$BUILDPATH/greyhead_multisitemaker"

  echo "Using: $GITHUBUSER_MULTISITEMAKER_REMOTE. Adding remote..."

  REMOTE="https://github.com/$GITHUBUSER_MULTISITEMAKER_REMOTE/greyhead_multisitemaker.git"

  git remote add upstream "$REMOTE"

  echo "Remote '$REMOTE' added. Please check the following output is correct:

  "
  git remote -v

  echo "
  Continuing...
  "
fi

# Now drupal-scripts-of-usefulness.
GITHUBUSER_SCRIPTS="$GITHUBUSER_MULTISITEMAKER"

echo -n "
*************************************************************************

What is the Github account from which you want to clone the drupal-scripts-of-usefulness repo? Leave blank to use the default: '$GITHUBUSER_SCRIPTS'
: "
read GITHUBUSER_SCRIPTS_ENTERED
if [ ! "x$GITHUBUSER_SCRIPTS_ENTERED" = "x" ]; then
  GITHUBUSER_SCRIPTS="$GITHUBUSER_SCRIPTS_ENTERED"
fi
echo "Using: $GITHUBUSER_SCRIPTS

Cloning Drupal multisite template from $GITHUBUSER_SCRIPTS..."

cd "$BUILDPATH"
git clone --recursive "https://github.com/$GITHUBUSER_SCRIPTS/greyhead_multisitemaker.git" greyhead_multisitemaker
cd "$BUILDPATH/greyhead_multisitemaker"
git checkout master
git config core.fileMode false

# ---

echo -n "
*************************************************************************

Do you want to add an upstream remote for drupal-scripts-of-usefulness? E.g. if this is a
forked repo, you can add the fork's source repo so you can then pull in changes
by running: git fetch upstream; git checkout master; git merge upstream/master

Y/n: "

old_stty_cfg=$(stty -g)
stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
if echo "$answer" | grep -iq "^y" ;then
  # Add remotes.
  GITHUBUSER_SCRIPTS_REMOTE="$GITHUBUSER_MULTISITE_TEMPLATE_REMOTE"
  echo -v "
*************************************************************************

What is the upstream Github account to pull changes from? Leave blank to use the default: '$GITHUBUSER_SCRIPTS_REMOTE'
: "
  read GITHUBUSER_SCRIPTS_REMOTE_ENTERED
  if [ ! "x$GITHUBUSER_SCRIPTS_REMOTE_ENTERED" = "x" ]; then
    GITHUBUSER_SCRIPTS_REMOTE="$GITHUBUSER_SCRIPTS_REMOTE_ENTERED"
  fi

  cd "$BUILDPATH/greyhead_multisitemaker"

  echo "Using: $GITHUBUSER_SCRIPTS_REMOTE. Adding remote..."

  REMOTE="https://github.com/$GITHUBUSER_SCRIPTS_REMOTE/greyhead_multisitemaker.git"

  git remote add upstream "$REMOTE"

  echo "Remote '$REMOTE' added. Please check the following output is correct:

  "
  git remote -v

  echo "
  Continuing...
  "
fi

# Download Drupal 7 core.
"$STARTINGDIRECTORY/script-components/download-drupal7-core.sh" --buildpath="$BUILDPATH" --drupalversion=7

echo -n "
*************************************************************************

Check out alexharries/drupal7_common_features?
Y/n: "

old_stty_cfg=$(stty -g)
stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
if echo "$answer" | grep -iq "^y" ;then
  cd "$BUILDPATH"
  git clone --recursive https://github.com/alexharries/drupal7_common_features.git drupal7_common_features

  echo "

  ---

  Symlinking sites/all/modules/features to $BUILDPATH/drupal7_common_features:"

  ln -s "$BUILDPATH/drupal7_common_features" "$BUILDPATH/drupal7_core/www/sites/all/modules/features"
fi

echo -n "
*************************************************************************

Check out drupal7_four_features? (This will only work if you have access to this Four Communications repo) Y/n: "

old_stty_cfg=$(stty -g)
stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
if echo "$answer" | grep -iq "^y" ;then
  cd "$BUILDPATH"
  git clone --recursive https://github.com/fourcommunications/drupal7_four_features.git drupal7_four_features

  echo "

  ---

  Symlinking sites/all/modules/features to $BUILDPATH/drupal7_four_features:"

  ln -s "$BUILDPATH/drupal7_four_features" "$BUILDPATH/drupal7_core/www/sites/all/modules/four-features"
fi

# drupal7_sites_projects

cd "$BUILDPATH"
echo -n "
*************************************************************************

Please choose which drupal7_sites_projects directory you want to check
out or create:

1. fourcommunications/drupal7_sites_projects (restricted access)
2. alexharries/drupal7_sites_projects (restricted access)
3. Another git repository and branch of your choosing
4. No checkout - just create a directory (you're responsible for saving)

: "

old_stty_cfg=$(stty -g)
stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
if echo "$answer" | grep -iq "^1" ;then
  # fourcomms
  PROJECTSCHECKOUT="four"
elif echo "$answer" | grep -iq "^2" ;then
  # alexharries
  PROJECTSCHECKOUT="greyhead"
elif echo "$answer" | grep -iq "^3" ;then
  # other
  PROJECTSCHECKOUT="custom"
elif echo "$answer" | grep -iq "^4" ;then
  # none
  PROJECTSCHECKOUT="create"
fi

if [ "$PROJECTSCHECKOUT" = "four" ]; then
  PROJECTSCLONEURL="https://github.com/fourcommunications/drupal7_sites_projects.git"
fi

if [ "$PROJECTSCHECKOUT" = "greyhead" ]; then
  PROJECTSCLONEURL="https://github.com/alexharries/drupal7_sites_projects.git"
fi

if [ "$PROJECTSCHECKOUT" = "four" ] || [ "$PROJECTSCHECKOUT" = "greyhead" ]; then
  CUSTOMPROJECTSBRANCH_DEFAULT="develop"
fi

if [ "$PROJECTSCHECKOUT" = "four" ] || [ "$PROJECTSCHECKOUT" = "greyhead" ] || [ "$PROJECTSCHECKOUT" = "custom" ]; then
  echo -n "
*************************************************************************

What branch should be checked out? (Leave blank for default '$CUSTOMPROJECTSBRANCH_DEFAULT') : "
  read CUSTOMPROJECTSBRANCH

  if [ "x$CUSTOMPROJECTSBRANCH" = "X" ]; then
    CUSTOMPROJECTSBRANCH=$CUSTOMPROJECTSBRANCH_DEFAULT
  fi

fi

if [ "$PROJECTSCHECKOUT" = "custom" ]; then
  echo -n "
*************************************************************************

What is the full clone URL of the repo? : "
  read PROJECTSCLONEURL

  if [ "x$PROJECTSCLONEURL" = "X" ]; then
    echo "No URL entered - cancelling and will create an empty dir instead."
    PROJECTSCHECKOUT=4
  fi
fi

if [ "$PROJECTSCHECKOUT" = "four" ] || [ "$PROJECTSCHECKOUT" = "greyhead" ] || [ "$PROJECTSCHECKOUT" = "custom" ]; then
  git clone --recursive "$PROJECTSCLONEURL" drupal7_sites_projects
  cd drupal7_sites_projects
  git checkout "$PROJECTSBRANCH"
fi

if [ "$PROJECTSCHECKOUT" = "create" ]; then
  mkdir -p "$BUILDPATH/drupal7_sites_projects"
fi

#if echo "$answer" | grep -iq "^y" ;then
#else
#  echo -n "
#*************************************************************************
#
#Check out alexharries/drupal7_sites_projects (if you have access)? Y/n: "
#
#  old_stty_cfg=$(stty -g)
#  stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
#  if echo "$answer" | grep -iq "^y" ;then
#    cd "$BUILDPATH"
#    git clone --recursive https://github.com/alexharries/drupal7_sites_projects.git drupal7_sites_projects
#    cd drupal7_sites_projects
#    git checkout "$PROJECTSBRANCH"
#  else
#    echo -n "
#*************************************************************************
#
#Check out another alexharries/drupal7_sites_projects (if you have access)? Y/n: "
#
#    old_stty_cfg=$(stty -g)
#    stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
#    if echo "$answer" | grep -iq "^y" ;then
#      cd "$BUILDPATH"
#      git clone --recursive https://github.com/alexharries/drupal7_sites_projects.git drupal7_sites_projects
#      cd drupal7_sites_projects
#      git checkout "$PROJECTSBRANCH"
#    else
#    echo -n "
#*************************************************************************
#
#Create the drupal7_sites_projects directory?
#
#This will allow you to set up a working local Drupal install, if you wish. Note that you will have to figure out how you want to save the work you do in this directory.
#
#Y/n: "
#
#    old_stty_cfg=$(stty -g)
#    stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
#    if echo "$answer" | grep -iq "^y" ;then
#      mkdir -p "$BUILDPATH/drupal7_sites_projects"
#    fi
#  fi
#fi

if [ -d "$BUILDPATH/drupal7_sites_projects" ]; then
  # If Drupal core and drupal7_sites_common were checked out ok, and we have
  # a multisite name, symlink the project dir and drush aliases in now.
  if [ ! "x$MULTISITENAME" = "x" ]; then
    # Symlink the multisite directory from sites/ to its physical location.
    MULTISITEPHYSICALLOCATION="$BUILDPATH/drupal7_sites_projects/$MULTISITENAME"
    MULTISITESYMLINKLOCATION="$BUILDPATH/drupal7_core/www/sites/$MULTISITENAME"

    if [[ ! -d "$MULTISITEPHYSICALLOCATION" && -d "$BUILDPATH/drupal7_multisite_template" ]]; then
      echo -p "
*************************************************************************

Multisite directory $MULTISITEPHYSICALLOCATION not found. Do you want to create it from the multisite template? Y/n: "

      old_stty_cfg=$(stty -g)
      stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
      if echo "$answer" | grep -iq "^y" ;then
        # Copy the sites template and comment out the URL template in
        # settings.site_urls.info.
        cp -R "$BUILDPATH/drupal7_multisite_template/sites-template" "$BUILDPATH/drupal7_sites_projects/$MULTISITENAMENOHYPHENS"
        perl -pi -e "s/SETTINGS_SITE_URLS\[\] = {{DOMAIN}}/; SETTINGS_SITE_URLS\[\] = {{DOMAIN}}/g" "$BUILDPATH/drupal7_sites_projects/$MULTISITENAMENOHYPHENS/settings.site_urls.info"

        MULTISITETHEMEPATH="$BUILDPATH/drupal7_sites_projects/$MULTISITENAMENOHYPHENS/themes"
        MULTISITETHEMETEMPLATEPATH="$MULTISITETHEMEPATH/username_bootstrap_subtheme"

        echo -n "
*************************************************************************

Do you want to create a Bootstrap sub-subtheme and commit it to the repo?

(Le quoi? See https://github.com/alexharries/greyhead_bootstrap for more info.)

Y/n: "

        old_stty_cfg=$(stty -g)
        stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
        if echo "$answer" | grep -iq "^y" ;then
          # Create the Bootstrap sub-subtheme.

          echo "Creating the subtheme ${MULTISITENAMENOHYPHENS}_bootstrap_subtheme at $BUILDPATH/drupal7_sites_projects/$MULTISITENAMENOHYPHENS/themes:"

          cd "$MULTISITETHEMEPATH"
          mv username_bootstrap_subtheme "$MULTISITENAMENOHYPHENS"_bootstrap_subtheme
          cd "$MULTISITENAMENOHYPHENS"_bootstrap_subtheme
          mv username_bootstrap_subtheme.info "$MULTISITENAMENOHYPHENS"_bootstrap_subtheme.info

          perl -pi -e "s/{{username}}/$MULTISITENAMENOHYPHENS/g" "$MULTISITENAMENOHYPHENS"_bootstrap_subtheme.info
          perl -pi -e "s/{{username}}/$MULTISITENAMENOHYPHENS/g" "prepros.cfg"
          perl -pi -e "s/function username/function $MULTISITENAMENOHYPHENS/g" "template.php"

          echo "Done."
        else
          echo "Removing theme template from $MULTISITETHEMETEMPLATEPATH"
          rm -r "$MULTISITETHEMETEMPLATEPATH"
        fi

        # Commit and push.
        echo "Committing..."
        cd ../../..

        git add "./$MULTISITENAME"
        git commit -m "Setting up $MULTISITENAME multisite directory."
        git push

        echo "Committed.
        "
      fi
    fi

    if [ -e "$MULTISITESYMLINKLOCATION" ]; then
      rm "$MULTISITESYMLINKLOCATION"
    fi

    ln -s "$MULTISITEPHYSICALLOCATION" "$MULTISITESYMLINKLOCATION"

    DRUSHALIASNAME="$MULTISITENAME.aliases.drushrc.php"
    DRUSHALIASESDIRECTORY="$BUILDPATH/drupal7_sites_projects/_drush_aliases"
    DRUSHALIASPHYSICALLOCATION="$DRUSHALIASESDIRECTORY/$DRUSHALIASNAME"

    # If the alias doesn't exist but the drupal7_sites_projects repo does,
    # we can attempt to create it.
    if [[ ! -f "$DRUSHALIASPHYSICALLOCATION" && -d "$BUILDPATH/drupal7_sites_projects" ]]; then
      echo -n "
*************************************************************************

Do you want to create the Drush alias file $DRUSHALIASPHYSICALLOCATION? Y/n: "

      old_stty_cfg=$(stty -g)
      stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
      if echo "$answer" | grep -iq "^y" ;then
        # Make the aliases directory if not present.
        if [ ! -d "$DRUSHALIASESDIRECTORY" ]; then
          mkdir -p "$DRUSHALIASESDIRECTORY"
        fi

        cp "$BUILDPATH/drupal7_multisite_template/template.aliases.drushrc.php" "$DRUSHALIASPHYSICALLOCATION"
      fi
    fi

    if [ -f "$DRUSHALIASPHYSICALLOCATION" ]; then

      # Check whether the alias has been set up for this build type already;
      # if not, offer to add it now.
      if grep -q "{{${BUILDTYPE}MULTISITENAMENOHYPHENS}}" "$DRUSHALIASPHYSICALLOCATION"; then
        echo "
*************************************************************************

Alias file already configured for this build type."
      else
        # Not configured - do we want to?

        echo -n "
*************************************************************************

This drush alias file hasn't been configured for a $BUILDTYPE environment yet;
do you want to add configuration for this build type and commit it now?

This will allow you to do, for example:

$ drush @${MULTISITENAMENOHYPHENS}.${BUILDTYPE} cc all

Y/n: "

        old_stty_cfg=$(stty -g)
        stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
        if echo "$answer" | grep -iq "^y" ;then
#          echo "Ha! Fooled you! This script can't set up the drush alias because bash/perl is a pain in the arse at replacing a placeholder with a slash. If you can figure it out, please help yourself to a biscuit. You've earnt it."

          perl -pi -e "s/{{MULTISITENAMENOHYPHENS}}/$MULTISITENAMENOHYPHENS/g" "$DRUSHALIASPHYSICALLOCATION"

#          perl -pi -e "s/{{-user}}/$USERNAME/g" "$USERNAMESHORT.aliases.drushrc.php"

          perl -pi -e "s/{{BUILDPATH-$BUILDTYPE}}/$BUILDPATH/g" "$DRUSHALIASPHYSICALLOCATION"

          if [ "x$SITEURI" = "x" ]; then
            echo -n "What is the site URL, without http:// or any trailing slash?: "
            read SITEURI
          fi

          perl -pi -e "s/{{SITEURI-$BUILDTYPE}}/$SITEURI/g" "$DRUSHALIASPHYSICALLOCATION"

          if [ ! "x$DRUSHREMOTEHOST" = "x" ]; then
            if [ "$BUILDTYPE" = "LOCAL" ]; then
              DRUSHREMOTEHOST="127.0.0.1"
            else
              echo -n "What is the remote hostname or IP? Leave blank for the default '$SITEURI': "
              read DRUSHREMOTEHOST

              if [ "x$DRUSHREMOTEHOST" = "x" ]; then
                DRUSHREMOTEHOST="127.0.0.1"
              fi
            fi
          fi

          perl -pi -e "s/{{DRUSHREMOTEHOST-$BUILDTYPE}}/$DRUSHREMOTEHOST/g" "$DRUSHALIASPHYSICALLOCATION"

          if [ ! "x$DRUSHREMOTEUSER" = "x" ]; then
            echo -n "What is the username to run Drush commands as, on the remote host?

This is usually the user account under which the website is hosted, and not www-data.

Leave blank for the default '$MULTISITENAMENOHYPHENS': "
            read DRUSHREMOTEUSER
          fi

          perl -pi -e "s/{{DRUSHREMOTEUSER-$BUILDTYPE}}/$DRUSHREMOTEUSER/g" "$DRUSHALIASPHYSICALLOCATION"

          cd "$DRUSHALIASESDIRECTORY"
          git add "$DRUSHALIASPHYSICALLOCATION"
          git commit -m "Added Drush alias file for $MULTISITENAME. May be mangled, so please check."
          git push

          echo "Alias file configured. Maybe. Please verify it's okay:

*************************************************************************
"
        cat "$DRUSHALIASPHYSICALLOCATION"
        echo "
*************************************************************************
"
        fi
      fi

#      echo "
#*************************************************************************
#
#Symlinking $DRUSHALIASPHYSICALLOCATION to $BUILDPATH/drupal7_core/www/sites/all/drush/$DRUSHALIASNAME:"
#
#      if [ -d "$BUILDPATH/drupal7_core/www/sites/all/drush" ]; then
#        mkdir "$BUILDPATH/drupal7_core/www/sites/all/drush"
#      fi
#
#      ln -s "$DRUSHALIASPHYSICALLOCATION" "$BUILDPATH/drupal7_core/www/sites/all/drush/$DRUSHALIASNAME"
    fi

    if [ ! "x$SITEURI" = "x" ]; then
      echo "
*************************************************************************

Creating the settings.this_site_url.info file at $BUILDPATH/drupal7_sites_projects/$MULTISITENAME/settings.this_site_url.info"

      echo "SETTINGS_SITE_URLS[] = $SITEURI" > "$BUILDPATH/drupal7_sites_projects/$MULTISITENAME/settings.this_site_url.info"

      echo "

      Done.

      "
    fi
  fi
fi

# Create symlinks.
echo "
*************************************************************************

";

if [[ -d "$BUILDPATH/drupal7_core/www" && -d "$BUILDPATH/drupal7_sites_common" ]]; then
  # Symlink common first.
  COMMONSITESSYMLINKPATH="$BUILDPATH/drupal7_core/www/sites"
  COMMONSITESPHYSICALPATH="$BUILDPATH/drupal7_sites_common"
  if [ -e "$COMMONSITESSYMLINKPATH" ]; then
    rm "$COMMONSITESSYMLINKPATH"
  fi

  echo "Linking $COMMONSITESSYMLINKPATH to $COMMONSITESPHYSICALPATH:"
  ln -s "$COMMONSITESPHYSICALPATH" "$COMMONSITESSYMLINKPATH"

  # Symlink drush aliases.
  DRUSHALIASESSYMLINKPATH="$BUILDPATH/drupal7_core/www/sites/all/drush"
  DRUSHALIASESPHYSICALPATH="$BUILDPATH/drupal7_sites_projects/_drush_aliases"
  if [ -e "$DRUSHALIASESSYMLINKPATH" ]; then
    rm
  fi

  echo "Linking $DRUSHALIASESSYMLINKPATH to $DRUSHALIASESPHYSICALPATH:"
  ln -s "$DRUSHALIASESPHYSICALPATH" "$DRUSHALIASESSYMLINKPATH"
fi

if [[ -d "$BUILDPATH/drupal7_core/www" && -d "$BUILDPATH/drupal7_sites_projects/$MULTISITENAME" ]]; then
  # Symlink the multisite itself.
  MULTISITESYMLINKPATH="$BUILDPATH/drupal7_core/www/sites/$MULTISITENAME"
  MULTISITEPHYSICALPATH="$BUILDPATH/drupal7_sites_common/$MULTISITENAME"
  if [ -e "$MULTISITESYMLINKPATH" ]; then
    rm "$MULTISITESYMLINKPATH"
  fi

  echo "Linking $MULTISITESYMLINKPATH to $MULTISITEPHYSICALPATH:"
  ln -s "$MULTISITEPHYSICALPATH" "$MULTISITESYMLINKPATH"
fi

if [[ -d "$BUILDPATH/drupal7_core/www" && -d "$BUILDPATH/greyhead_multisitemaker" ]]; then
  # Symlink multisitemaker.
  MULTISITEMAKERSYMLINKPATH="$BUILDPATH/drupal7_core/www/multisitemaker"
  MULTISITEMAKERPHYSICALPATH="$BUILDPATH/greyhead_multisitemaker"
  if [ -e "$MULTISITEMAKERSYMLINKPATH" ]; then
    rm "$MULTISITEMAKERSYMLINKPATH"
  fi

  echo "Linking $MULTISITEMAKERSYMLINKPATH to $MULTISITEMAKERPHYSICALPATH:"
  ln -s "$MULTISITEMAKERPHYSICALPATH" "$MULTISITEMAKERSYMLINKPATH"
fi

# Only symlink to files if we're not building for live, if the multisite dir
# is set up, and there isn't already a files link/directory.
if [[ ! ${BUILDTYPE} = "LIVE" && -d "$BUILDPATH/drupal7_sites_projects/$MULTISITENAME" && ! -e "$BUILDPATH/drupal7_sites_projects/$MULTISITENAME/files" ]]; then
  echo "
*************************************************************************

Symlinking $BUILDPATH/drupal7_sites_projects/$MULTISITENAME/files to $FILESPATH: "

  ln -s "$FILESPATH" "$BUILDPATH/drupal7_sites_projects/$MULTISITENAME/files"
fi

# ---

# Only create local_databases.php and local_settings.php files if we're not
# building for live.
if [ ! ${BUILDTYPE} = "LIVE" ]; then
  echo -n "
  *************************************************************************

  Do you already have local_databases.php and local_settings.php files (Y) or do you
  need to create new ones from the multisite template (n)?

  Y/n: "

  old_stty_cfg=$(stty -g)
  stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
  if echo "$answer" | grep -iq "^y" ;then
    # Yes, get the files' absolute path.
    EXISTING_LOCALSETTINGSPATH_DEFAULT="$BUILDPATH/../local_settings.php"

    until [ -f "$EXISTING_LOCALSETTINGSPATH" ]; do
      echo -n "
  *************************************************************************

  What is the absolute path to the local_settings.php file, including the filename?

  Leave blank to use the default: '$EXISTING_LOCALSETTINGSPATH_DEFAULT'
  : "
      read EXISTING_LOCALSETTINGSPATH_ENTERED
      if [ ! "x$EXISTING_LOCALSETTINGSPATH_ENTERED" = "x" ]; then
        EXISTING_LOCALSETTINGSPATH=$EXISTING_LOCALSETTINGSPATH_ENTERED
      else
        EXISTING_LOCALSETTINGSPATH=$EXISTING_LOCALSETTINGSPATH_DEFAULT
      fi

      if [ ! -f "$EXISTING_LOCALSETTINGSPATH" ]; then
        echo "Oops! '$EXISTING_LOCALSETTINGSPATH' either doesn't exist or isn't accessible. Please try again..."
      fi
    done

    EXISTING_LOCALDATABASESPATH_DEFAULT="$BUILDPATH/../local_databases.php"

    until [ -f "$EXISTING_LOCALDATABASESPATH" ]; do
      echo -n "
  *************************************************************************

  What is the absolute path to the local_databases.php file, including the filename?

  Leave blank to use the default: '$EXISTING_LOCALDATABASESPATH_DEFAULT'
  : "
      read EXISTING_LOCALDATABASESPATH_ENTERED
      if [ ! "x$EXISTING_LOCALDATABASESPATH_ENTERED" = "x" ]; then
        EXISTING_LOCALDATABASESPATH=${EXISTING_LOCALDATABASESPATH_ENTERED}
      else
        EXISTING_LOCALDATABASESPATH=${EXISTING_LOCALDATABASESPATH_DEFAULT}
      fi

      if [ ! -f "$EXISTING_LOCALDATABASESPATH" ]; then
        echo "Oops! '$EXISTING_LOCALDATABASESPATH' either doesn't exist or isn't accessible. Please try again..."
      fi
    done

    # Symlink local_settings and local_databases.
    ln -s ${EXISTING_LOCALDATABASESPATH} "$BUILDPATH/drupal7_core/local_databases.php"
    ln -s ${EXISTING_LOCALSETTINGSPATH} "$BUILDPATH/drupal7_core/local_settings.php"

#    # Is there a Drush alias?
#    if [ -f "$DRUSHALIASPHYSICALLOCATION" ]; then
#      echo "
#  *************************************************************************
#
#  Symlinking $DRUSHALIASPHYSICALLOCATION to $BUILDPATH/drupal7_core/www/sites/all/drush/$DRUSHALIASNAME: "
#
#      if [ -d "$BUILDPATH/drupal7_core/www/sites/all/drush" ]; then
#        mkdir "$BUILDPATH/drupal7_core/www/sites/all/drush"
#      fi
#
#      ln -s "$DRUSHALIASPHYSICALLOCATION" "$BUILDPATH/drupal7_core/www/sites/all/drush/$DRUSHALIASNAME"
#    fi

  else
    # No.
    LOCALDATABASESPATH="$BUILDPATH/drupal7_core/local_databases.php"

    echo "
  *************************************************************************

  Copying local_databases.php and local_settings.php to $BUILDPATH/drupal7_core.

  You will be asked for the database connection details shortly; if you don't
  want to or can't set them up now, you will need to edit the file at
  $LOCALDATABASESPATH to set them."

    cp "$BUILDPATH/drupal7_multisite_template/local_databases.template.php" "$LOCALDATABASESPATH"

    LOCALSETTINGSFILEPATH="$BUILDPATH/drupal7_core/local_settings.php"
    cp "$BUILDPATH/drupal7_multisite_template/local_settings.template.php" "$LOCALSETTINGSFILEPATH"

  fi

  # ---

  if [ ! "x$MULTISITENAME" = "x" ]; then
    echo -n "
  *************************************************************************

  Do you know the database connection details, and want to set them in $LOCALDATABASESPATH? Y/n: "

    old_stty_cfg=$(stty -g)
    stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
    if echo "$answer" | grep -iq "^y" ;then
      # Get DB connection details: DB name, username, password, host, and port.
      until [ ! "x$DBNAME" = "x" ]; do
        echo -n "
  *************************************************************************

  What is the database name? (required): "
        read DBNAME
        if [ "x$DBNAME" = "x" ]; then
            echo "Oh no! You need to provide the database name. Please go back and try again."
        fi
      done
      echo "Using: $DBNAME.

      ---"

      until [ ! "x$DBUSERNAME" = "x" ]; do
        echo -n "
  *************************************************************************

  What is the database username? (required): "
        read DBUSERNAME
        if [ "x$DBUSERNAME" = "x" ]; then
            echo "Oh no! You need to provide the database username. Please go back and try again."
        fi
      done
      echo "Using: $DBUSERNAME.

      ---"

      until [ ! "x$DBPASSWORD" = "x" ]; do
        echo -n "
  *************************************************************************

  What is the database password? (required): "
        read DBPASSWORD
        if [ "x$DBPASSWORD" = "x" ]; then
            echo "Oh no! You need to provide the database password - blank passwords aren't allowed (sorry). Please go back and try again."
        fi
      done
      echo "Using: $DBPASSWORD.

      ---"

      echo -n "
  *************************************************************************

  What is the database host? Leave empty for the default: 127.0.0.1: "
      read DBHOST
      if [ "x$DBHOST" = "x" ]; then
        DBPORT="127.0.0.1"
      fi
      echo "Using: $DBHOST

      ---"

      echo -n "
  *************************************************************************

  What is the database port? Leave empty for the default: 3306: "
      read DBPORT
      if [ "x$DBPORT" = "x" ]; then
        DBPORT=3306
      fi
      echo "Using: $DBPORT

      ---"

      # Create the DB connection string and inject into $LOCALDATABASESPATH before
      # "  // {{BUILDSHINSERT}}".

      # AROOGA ALERT! Finding a working search-replace command has been a f***ing
      # nightmare :( So please, if you're as synaptically challenged as I am, please
      # please please don't mess with the code on the following lines unless,
      # well, you wrote perl. Or something. I dunno. I've just spent three hours
      # trying to fix this. Three hours! Why did I do that? I could have taken a
      # plane to Spain in that time and now I could be sunning myself on a beach,
      # drinking cheap, warm Sangria out of a carton smeared with sand from the
      # "beach" I've rocked up to, which in reality is no more than a handful of
      # builders' sand (you know, the stuff that turns your skin orange) tossed
      # over the rubble and other apocryphal detritus that is left over when a
      # fast, cheap, dodgy building project on the continent leaves town.

      # So, er, yeah. Be careful with this code please...

      CONNECTIONSTRING="'$MULTISITENAME' => array('$SITEURI' => array('database' => '$DBNAME', 'username' => '$DBUSERNAME', 'password' => '$DBPASSWORD', 'port' => '$DBPORT')),"

      cd "$BUILDPATH/drupal7_core"
      echo ${CONNECTIONSTRING} > local_databases.tmp

      sed -e '/BUILDSHINSERT}}/r./local_databases.tmp' local_databases.php > local_databases_2.php
      mv local_databases_2.php local_databases.php
      rm local_databases.tmp

      # Here ends todays whinge...

      echo "
  *************************************************************************

  Done. Please check the output of local_databases.php to make sure it looks okay:

  ****************************************************************************"

      cat "$LOCALDATABASESPATH"

      echo "
  ****************************************************************************
      "

      echo -n "
  *************************************************************************

  Is Drupal already installed? Y/n: "

      old_stty_cfg=$(stty -g)
      stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
      if echo "$answer" | grep -iq "^y" ;then
        echo "Testing database..."

        cd "$BUILDPATH/drupal7_core/www/sites/$MULTISITENAME"
        drush rr
        drush cc all
        drush status
      else
        # TODO: add step to import a MySQL DB if database details known

        echo -n "
  *************************************************************************

  Do you have a database dump you want to import? Y/n: "

        old_stty_cfg=$(stty -g)
        stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
        if echo "$answer" | grep -iq "^y" ;then
          # Get the DB path.
          DATABASEDUMPPATH="monkey"

          until [ -e "$DATABASEDUMPPATH" ] || [ "x$DATABASEDUMPPATH" = "x" ]; do
            echo -n "
  *************************************************************************

  What is the absolute path to the database dump file, including the filename? (Leave blank to skip importing the database dump.)
  : "
            read DATABASEDUMPPATH

            if [ ! "x$DATABASEDUMPPATH" = "x" ]; then
              if [ ! -e "$DATABASEDUMPPATH" ]; then
                echo "Oops! '$DATABASEDUMPPATH' either doesn't exist or isn't a readable file. Please try again..."
              else
                COMMAND="mysql -u $DBUSERNAME -p$DBPASSWORD $DBNAME < $DATABASEDUMPPATH"
                echo "Attempting import: $COMMAND...
                "
                eval ${COMMAND}
                echo "MySQL import done."
              fi
            fi

          done
        fi
      fi
    fi

    # Do they want us to install Drupal?
    echo -n "
*************************************************************************

Do you want to run the Drupal installer? This will set up a minimal
Drupal install with a number of base modules and settings configured.

Y/n: "

    old_stty_cfg=$(stty -g)
    stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
    if echo "$answer" | grep -iq "^y" ;then
      # Get the admin username and password.
      echo -n "
*************************************************************************

Please choose an administrator username for the root Drupal user: "
      read ADMINUSERNAME

      echo -n "
*************************************************************************

Please choose a password for $ADMINUSERNAME: "
      read ADMINPASS

      FEATURESTOENABLE="drupal_search paragraph_page development_settings backup_migrate_daily"

      echo -n "
*************************************************************************

Should $SITEURI be accessed over http or https? Enter 'http' or 'https', or leave blank for 'https': "
      read PROTOCOL

      if [ "x$PROTOCOL" = "x" ]; then
        PROTOCOL="https"
      fi

      FEATURESTOENABLE="drupal_search paragraph_page development_settings backup_migrate_daily"

      # Do they want to enable four_communications_base_modules?
      if [ -d "$BUILDPATH/drupal7_four_features" ]; then
        # Actually, just do it :)

#        echo -n "
#*************************************************************************
#
#Do you want to enable the suite of Four Features? (Recommended) Y/n: "
#
#        old_stty_cfg=$(stty -g)
#        stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
#        if echo "$answer" | grep -iq "^y" ;then
#          FEATURESTOENABLE="$FEATURESTOENABLE four_communications_base_modules"
#        fi

        FEATURESTOENABLE="$FEATURESTOENABLE four_communications_base_modules fourcomms_update_notifications four_communications_user_roles four_login_toboggan_settings"

      # Otherwise, do they want to enable common_base_modules?
      elif [ -d "$BUILDPATH/drupal7_common_features/common_base_modules" ]; then
        # Just do it.

#        echo -n "
#*************************************************************************
#
#Do you want to enable the run the common_base_modules feature? Y/n: "
#
#        old_stty_cfg=$(stty -g)
#        stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
#        if echo "$answer" | grep -iq "^y" ;then
#          FEATURESTOENABLE="$FEATURESTOENABLE four_communications_base_modules"
#        fi

        FEATURESTOENABLE="$FEATURESTOENABLE common_base_modules update_notifications_redirect common_user_roles login_toboggan_settings"
      fi

      echo "
*************************************************************************

Beginning install..."

      cd "$BUILDPATH/drupal7_core/www/sites/$MULTISITENAME"

      drush --uri="$SITEURI" site-install minimal --account-name="$ADMINUSERNAME" --account-pass="$ADMINPASS"

      echo "
*************************************************************************

Drupal installed - enabling features..."

      drush --uri="$SITEURI" en features "$FEATURESTOENABLE" -y

      echo "
*************************************************************************

Reverting features..."

      drush --uri="$SITEURI" fra -y

      echo "
*************************************************************************

Clearing caches..."

      drush --uri="$SITEURI" cc all

      # Open the site in a web browser.
      COMMAND="$STARTINGDIRECTORY/script-components/open-url.sh $PROTOCOL://$SITEURI"
      eval ${COMMAND}

      echo "
*************************************************************************

You can now browse your site at $PROTOCOL://$SITEURI - yay!"

    fi
  else
    echo "
*************************************************************************

This script can't set up the database because no multisite directory name has been entered.

Please manually edit $BUILDPATH/drupal7_core/local_databases.php to set
the database details."
  fi
fi

echo "
*************************************************************************

All finished. Enjoy! :)

*************************************************************************
"

cd "$BUILDPATH"
