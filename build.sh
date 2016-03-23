#!/usr/bin/env bash
#set -e
clear

# Note the starting directory.
STARTINGDIRECTORY=$(pwd)

echo -n "
*************************************************************************

This is a rough and ready script to build a local Drupal codebase with
which you can edit code and commit back to the parent repos.

*************************************************************************

Once this script has completed, you will have a directory which contains the
following Git repositories:

drupal7_core: this contains a copy of the latest release of Drupal 7, and the
code which configures the Drupal site for your local installation such as
setting development variables, etc.

drupal7_sites_common: this provides the Drupal /sites/all and /sites/default
directories, /sites/sites.php and a couple of other common files. This repo
will be symlinked into drupal7_core/www/sites

drupal7_multisite_template: provides a multisite directory to create a new
multisite in the codebase.

A choice of two Features repos - either greyhead_common_featues or (Four only)
drupal7_four_features, which is symlinked into
drupal7_core/www/sites/all/modules/features

drupal7_sites_projects: the Projects directory for Greyhead/Four
Communications, where you can work on code which is specifically for a
particular Four Drupal project. Individual projects will be symlinked into
drupal7_core/www/sites/[project directory name]

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

(To perform a live build, see live-deploy.sh)

: "

  old_stty_cfg=$(stty -g)
  stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
  if echo "$answer" | grep -iq "^1" ;then
    BUILDTYPE="LOCAL"
  elif echo "$answer" | grep -iq "^2" ;then
    BUILDTYPE="DEV"
  elif echo "$answer" | grep -iq "^3" ;then
    BUILDTYPE="STAGING"
  fi
done

echo "Build type: $BUILDTYPE"

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

(Optional) What is the URL of the Drupal site, without 'http://' - e.g.
www.example.com? You need to provide this if you want to configure the
database connection using this script, or have Drupal automagically create the
settings.this_site_url.info file.

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

echo "Using: $BUILDPATH.

"

# ---

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
    FILESPATH=$FILESPATHDEFAULT
  else
    FILESPATH=$FILESPATHENTERED
  fi
  echo "

  Using: $FILESPATH - attempting to make the directory if it doesn't
  already exist..."

  mkdir -p "$FILESPATH"

  if [ ! -d "$FILESPATH" ]; then
    echo "Oh no! Unable to create the directory at $FILESPATH - does this script have permission to make directories there?"
  fi
done

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
    GITHUBUSER_CORE_REMOTE=$GITHUBUSER_CORE_REMOTE_ENTERED
  fi

  cd "$BUILDPATH/drupal7_core"

  echo "Using: $GITHUBUSER_CORE_REMOTE. Adding remote..."

  REMOTE="https://github.com/$GITHUBUSER_CORE_REMOTE/drupal7_core.git"

  git remote add upstream $REMOTE

  echo "Remote '$REMOTE' added. Please check the following output is correct:

  "
  git remote -v

  echo "
  Continuing...
  "

fi

# ---

GITHUBUSER_SITES_COMMON=$GITHUBUSER_CORE

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

# Download Drupal 7 core.
"$STARTINGDIRECTORY/script-components/download-drupal7-core.sh" --buildpath="$BUILDPATH" --drupalversion=7

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

echo -n "
*************************************************************************

Check out fourcommunications/drupal7_sites_projects (if you have access)?

If you choose 'no' here, you will be asked if you want to check out
'alexharries/drupal7_sites_projects' instead.

Y/n: "

old_stty_cfg=$(stty -g)
stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
if echo "$answer" | grep -iq "^y" ;then
  cd "$BUILDPATH"
  git clone --recursive https://github.com/fourcommunications/drupal7_sites_projects.git drupal7_sites_projects
  cd drupal7_sites_projects
  git checkout develop
else
  echo -n "
*************************************************************************

Check out alexharries/drupal7_sites_projects (if you have access)? Y/n: "

  old_stty_cfg=$(stty -g)
  stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
  if echo "$answer" | grep -iq "^y" ;then
    cd "$BUILDPATH"
    git clone --recursive https://github.com/alexharries/drupal7_sites_projects.git drupal7_sites_projects
    cd drupal7_sites_projects
    git checkout develop
  fi
fi

if [ -d "$BUILDPATH/drupal7_sites_projects" ]; then
  # If Drupal core and drupal7_sites_common were checked out ok, and we have
  # a multisite name, symlink the project dir and drush aliases in now.
  if [ ! "x$MULTISITENAME" = "x" ]; then
    # Symlink the multisite directory from sites/ to its physical location.
    MULTISITEPHYSICALLOCATION="$BUILDPATH/drupal7_sites_projects/$MULTISITENAME"
    MULTISITESYMLINKLOCATION="$BUILDPATH/drupal7_core/www/sites/$MULTISITENAME"

    if [ ! -d "$MULTISITEPHYSICALLOCATION" ]; then
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

        echo -n "
*************************************************************************

Do you want to create a Bootstrap sub-subtheme and commit it to the repo?

(Le quoi? See https://github.com/alexharries/greyhead_bootstrap for more info.)

Y/n: "

        old_stty_cfg=$(stty -g)
        stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
        if echo "$answer" | grep -iq "^y" ;then
          # Create the Bootstrap sub-subtheme.

          echo "Creating the subtheme $MULTISITENAMENOHYPHENS_bootstrap_subtheme at $BUILDPATH/drupal7_sites_projects/$MULTISITENAMENOHYPHENS/themes:"

          cd "$BUILDPATH/drupal7_sites_projects/$MULTISITENAMENOHYPHENS/themes"
          mv username_bootstrap_subtheme "$MULTISITENAMENOHYPHENS"_bootstrap_subtheme
          cd "$MULTISITENAMENOHYPHENS"_bootstrap_subtheme
          mv username_bootstrap_subtheme.info "$MULTISITENAMENOHYPHENS"_bootstrap_subtheme.info

          perl -pi -e "s/{{username}}/$MULTISITENAMENOHYPHENS/g" "$MULTISITENAMENOHYPHENS"_bootstrap_subtheme.info
          perl -pi -e "s/{{username}}/$MULTISITENAMENOHYPHENS/g" "prepros.cfg"
          perl -pi -e "s/function username/function $MULTISITENAMENOHYPHENS/g" "template.php"

          echo "Done. Committing..."
          cd ../../..

          git add "./$MULTISITENAME"
          git commit -m "Setting up $MULTISITENAME multisite directory and subtheme $MULTISITENAMENOHYPHENS_bootstrap_subtheme."

          echo "Committed.
          "
        fi
      fi
    fi

    if [ -e "$MULTISITESYMLINKLOCATION" ]; then
      rm "$MULTISITESYMLINKLOCATION"
    fi

    ln -s "$MULTISITEPHYSICALLOCATION" "$MULTISITESYMLINKLOCATION"

    DRUSHALIASNAME="$MULTISITENAME.aliases.drushrc.php"
    DRUSHALIASLOCATION="$BUILDPATH/drupal7_sites_projects/_drush_aliases/$DRUSHALIASNAME"

    # If the alias doesn't exist but the drupal7_sites_projects repo does,
    # we can attempt to create it.
    if [[ ! -f "$DRUSHALIASLOCATION" && -d "$BUILDPATH/drupal7_sites_projects" ]]; then
      echo -n "
*************************************************************************

Do you want to create the Drush alias file $DRUSHALIASLOCATION? Y/n: "

      old_stty_cfg=$(stty -g)
      stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
      if echo "$answer" | grep -iq "^y" ;then
        cp "$BUILDPATH/drupal7_multisite_template/template.aliases.drushrc.php" "$DRUSHALIASLOCATION"
      fi
    fi

    if [ -f "$DRUSHALIASLOCATION" ]; then

      # Check whether the alias has been set up for this build type already;
      # if not, offer to add it now.
      if grep -q "{{${BUILDTYPE}MULTISITENAMENOHYPHENS}}" "$DRUSHALIASLOCATION"; then
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
          perl -pi -e "s/{{MULTISITENAMENOHYPHENS}}/$MULTISITENAMENOHYPHENS/g" "$DRUSHALIASLOCATION"
          perl -pi -e "s/{{${BUILDTYPE}$BUILDPATH}}/$BUILDPATH/g" "$DRUSHALIASLOCATION"

          if [ ! "x$SITEURI" = "x" ]; then
            perl -pi -e "s/{{${BUILDTYPE}$SITEURI}}/$SITEURI/g" "$DRUSHALIASLOCATION"
          fi

          if [ ! "x$DRUSHREMOTEHOST" = "x" ]; then
            perl -pi -e "s/{{${BUILDTYPE}$DRUSHREMOTEHOST}}/$DRUSHREMOTEHOST/g" "$DRUSHALIASLOCATION"
          fi

          if [ ! "x$DRUSHREMOTEUSER" = "x" ]; then
            perl -pi -e "s/{{${BUILDTYPE}$DRUSHREMOTEUSER}}/$DRUSHREMOTEUSER/g" "$DRUSHALIASLOCATION"
          fi

  #        perl -pi -e "s/{{$BUILDTYPE}}/$/g" "$DRUSHALIASLOCATION"

          git add "$DRUSHALIASLOCATION"

          echo "Alias file configured. Please verify it's okay."

        fi

      fi

      echo "
*************************************************************************

Symlinking $DRUSHALIASLOCATION to $BUILDPATH/drupal7_core/www/sites/all/drush/$DRUSHALIASNAME:"

      if [ -d "$BUILDPATH/drupal7_core/www/sites/all/drush" ]; then
        mkdir "$BUILDPATH/drupal7_core/www/sites/all/drush"
      fi

      ln -s "$DRUSHALIASLOCATION" "$BUILDPATH/drupal7_core/www/sites/all/drush/$DRUSHALIASNAME"
    fi

    echo "
*************************************************************************

Symlinking $BUILDPATH/drupal7_core/www/sites/$MULTISITENAME/files to $FILESPATH: "

    ln -s "$FILESPATH" "$BUILDPATH/drupal7_core/www/sites/$MULTISITENAME/files"

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

# ---

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
      EXISTING_LOCALDATABASESPATH=$EXISTING_LOCALDATABASESPATH_ENTERED
    else
      EXISTING_LOCALDATABASESPATH=$EXISTING_LOCALDATABASESPATH_DEFAULT
    fi

    if [ ! -f "$EXISTING_LOCALDATABASESPATH" ]; then
      echo "Oops! '$EXISTING_LOCALDATABASESPATH' either doesn't exist or isn't accessible. Please try again..."
    fi
  done

  # Symlink local_settings and local_databases.
  ln -s $EXISTING_LOCALDATABASESPATH "$BUILDPATH/drupal7_core/local_databases.php"
  ln -s $EXISTING_LOCALSETTINGSPATH "$BUILDPATH/drupal7_core/local_settings.php"

  # Is there a Drush alias?
  if [ -f "$DRUSHALIASLOCATION" ]; then
    echo "
*************************************************************************

Symlinking $DRUSHALIASLOCATION to $BUILDPATH/drupal7_core/www/sites/all/drush/$DRUSHALIASNAME: "

    if [ -d "$BUILDPATH/drupal7_core/www/sites/all/drush" ]; then
      mkdir "$BUILDPATH/drupal7_core/www/sites/all/drush"
    fi

    ln -s "$DRUSHALIASLOCATION" "$BUILDPATH/drupal7_core/www/sites/all/drush/$DRUSHALIASNAME"
  fi

else
  # No.
  echo "
*************************************************************************

Copying local_databases.php and local_settings.php to $BUILDPATH/drupal7_core.

You will be asked for the database connection details shortly; if you don't
want to or can't set them up now, you will need to edit the file at
$LOCALDATABASESPATH to set them."

  LOCALDATABASESPATH="$BUILDPATH/drupal7_core/local_databases.php"
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
    # "  // {{BUILDSHINSERT}}"

    CONNECTIONSTRING="'$MULTISITENAME' => array('$SITEURI' => array('database' => '$DBNAME', 'username' => '$DBUSERNAME', 'password' => '$DBPASSWORD', 'port' => '$DBPORT')),
  // {{BUILDSHINSERT}}"

  perl -pe 's/\/\/ {{BUILDSHINSERT}}/"$CONNECTIONSTRING"/e' "$LOCALDATABASESPATH"

#    perl -pi -e "s/{{MULTISITE_IDENTIFIER}}/$MULTISITENAME/g" "$LOCALDATABASESPATH"
#    perl -pi -e "s/{{DOMAIN}}/$SITEURI/g" "$LOCALDATABASESPATH"
#    perl -pi -e "s/{{DATABASENAME}}/$DBNAME/g" "$LOCALDATABASESPATH"
#    perl -pi -e "s/{{DATABASEUSERNAME}}/$DBUSERNAME/g" "$LOCALDATABASESPATH"
#    perl -pi -e "s/{{DATABASEPASSWORD}}/$DBPASSWORD/g" "$LOCALDATABASESPATH"
#    perl -pi -e "s/3306/$DBPORT/g" "$LOCALDATABASESPATH"

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
        DATABASEDUMPPATH=monkey

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
              eval $COMMAND
              echo "All done."
            fi
          fi

        done
      fi

    fi

  fi

  # TODO: add step to download node_modules to $BUILDPATH/node_modules if not already downloaded

  # TODO: add step to install Drupal?

else
  echo "
*************************************************************************

This script can't set up the database because no multisite directory name has been entered.

Please manually edit $BUILDPATH/drupal7_core/local_databases.php to set
the database details."

  cd "$BUILDPATH"
fi

echo "
*************************************************************************

All finished. Enjoy! :)

*************************************************************************
"

cd "$STARTINGDIRECTORY"
