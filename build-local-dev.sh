#!/usr/bin/env bash
set -e
clear
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

(Four only) drupal7_sites_projects: the Projects directory for Four
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

# ---

echo -n "(Optional) What is the URL of the Drupal site, without 'http://' - e.g.
www.example.com? You need to provide this if you want to configure the
database connection using this script, or have Drupal automagically create the
settings.this_site_url.info file.

:"

read SITEURI
echo "

Using: $SITEURI

"

# ---

DEPLOYDIRECTORY_SUBDIR=$MULTISITENAME
if [ "x$DEPLOYDIRECTORY_SUBDIR" = "x" ]; then
  DEPLOYDIRECTORY_SUBDIR="default"
fi

PWD=$(pwd)
DEPLOYDIRECTORY="$PWD/$DEPLOYDIRECTORY_SUBDIR"

until [ -d "$DEPLOYDIRECTORY" ]; do
  echo -n "What directory should we build Drupal in, without a trailing slash?

  This directory should not already exist.

  Leave blank to use the default: '$DEPLOYDIRECTORY'
  :"
  read DEPLOYDIRECTORY_ENTERED
  if [ ! "x$DEPLOYDIRECTORY_ENTERED" = "x" ]; then
    DEPLOYDIRECTORY=$DEPLOYDIRECTORY_ENTERED
  fi

  if [ -d "$DEPLOYDIRECTORY" ]; then
    echo "
  ***************************************************************
  WARNING: Directory already exists. Please make sure it's empty.
  ***************************************************************
  "
  else
    mkdir $DEPLOYDIRECTORY
  fi
done

echo "Using: $DEPLOYDIRECTORY.

"

mkdir -p $DEPLOYDIRECTORY

# ---

FILESPATHDEFAULT="$DEPLOYDIRECTORY/files"
until [ -d "$FILESPATH" ]; do
  echo "What is the absolute path of the Drupal files directory (including the
  directory itself), and without trailing slash?

  A symlink to this directory will be created in your multisite's directory.

  Default: '$FILESPATHDEFAULT'"
  read FILESPATHENTERED
  if [ "x$FILESPATHENTERED" = "x" ]; then
    FILESPATH=$FILESPATHDEFAULT
  else
    FILESPATH=$FILESPATHENTERED
  fi
  echo "

  Using: $FILESPATH - attempting to make the directory if it doesn't
  already exist..."

  mkdir -p $FILESPATH

  if [ ! -d "$FILESPATH" ]; then
    echo "Oh no! Unable to create the directory at $FILESPATH - does this script have permission to make directories there?"
  fi
done

# ---

GITHUBUSER_DEFAULT="fourcommunications"

# ---

GITHUBUSER_CORE=$GITHUBUSER_DEFAULT

echo -n "

---

What is the Github account from which you want to clone the drupal7_core repo? Leave blank to use the default: '$GITHUBUSER_CORE'
:"
read GITHUBUSER_CORE_ENTERED
if [ ! "x$GITHUBUSER_CORE_ENTERED" = "x" ]; then
  GITHUBUSER_CORE=$GITHUBUSER_CORE_ENTERED
fi
echo "Using: $GITHUBUSER_CORE

Cloning Drupal core from $GITHUBUSER_CORE..."

cd $DEPLOYDIRECTORY
git clone --recursive "https://github.com/$GITHUBUSER_CORE/drupal7_core.git" drupal7_core
cd $DEPLOYDIRECTORY/drupal7_core
git checkout master

# ---

echo -n "

---

Do you want to add an upstream remote for drupal7_core? E.g. if this is a
forked repo, you can add the fork's source repo so you can then pull in changes
by running: git fetch upstream; git checkout master; git merge upstream/master

Press Y/n: "

old_stty_cfg=$(stty -g)
stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
if echo "$answer" | grep -iq "^y" ;then
  # Add remotes.
  GITHUBUSER_CORE_REMOTE=$GITHUBUSER_DEFAULT
  echo -n "What is the upstream Github account to pull changes from?
  Leave blank to use the default: '$GITHUBUSER_CORE_REMOTE'
  :"

  read GITHUBUSER_CORE_REMOTE_ENTERED
  if [ ! "x$GITHUBUSER_CORE_REMOTE_ENTERED" = "x" ]; then
    GITHUBUSER_CORE_REMOTE=$GITHUBUSER_CORE_REMOTE_ENTERED
  fi

  cd $DEPLOYDIRECTORY/drupal7_core

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

---

What is the Github account from which you want to clone the drupal7_sites_common repo? Leave blank to use the default: '$GITHUBUSER_SITES_COMMON'
:"
read GITHUBUSER_SITES_COMMON_ENTERED
if [ ! "x$GITHUBUSER_SITES_COMMON_ENTERED" = "x" ]; then
  GITHUBUSER_SITES_COMMON=$GITHUBUSER_SITES_COMMON_ENTERED
fi
echo "Using: $GITHUBUSER_SITES_COMMON

Cloning Drupal sites common from $GITHUBUSER_SITES_COMMON..."

cd $DEPLOYDIRECTORY
git clone --recursive "https://github.com/$GITHUBUSER_SITES_COMMON/drupal7_sites_common.git" drupal7_sites_common
cd drupal7_sites_common
git checkout master

# ---

echo -n "

---

Do you want to add an upstream remote for drupal7_sites_common? E.g. if this is a
forked repo, you can add the fork's source repo so you can then pull in changes
by running: git fetch upstream; git checkout master; git merge upstream/master

Press Y/n: "

old_stty_cfg=$(stty -g)
stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
if echo "$answer" | grep -iq "^y" ;then
  # Add remotes.
  GITHUBUSER_SITES_COMMON_REMOTE=$GITHUBUSER_CORE_REMOTE
  echo -n "What is the upstream Github account to pull changes from? Leave blank to use the default: '$GITHUBUSER_SITES_COMMON_REMOTE'
  :"
  read GITHUBUSER_SITES_COMMON_REMOTE_ENTERED
  if [ ! "x$GITHUBUSER_SITES_COMMON_REMOTE_ENTERED" = "x" ]; then
    GITHUBUSER_SITES_COMMON_REMOTE=$GITHUBUSER_SITES_COMMON_REMOTE_ENTERED
  fi

  cd $DEPLOYDIRECTORY/drupal7_sites_common

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

---

What is the Github account from which you want to clone the drupal7_multisite_template repo? Leave blank to use the default: '$GITHUBUSER_MULTISITE_TEMPLATE
:"
read GITHUBUSER_MULTISITE_TEMPLATE_ENTERED
if [ ! "x$GITHUBUSER_MULTISITE_TEMPLATE_ENTERED" = "x" ]; then
  GITHUBUSER_MULTISITE_TEMPLATE=$GITHUBUSER_MULTISITE_TEMPLATE_ENTERED
fi
echo "Using: $GITHUBUSER_MULTISITE_TEMPLATE

Cloning Drupal multisite template from $GITHUBUSER_MULTISITE_TEMPLATE..."

cd $DEPLOYDIRECTORY
git clone --recursive "https://github.com/$GITHUBUSER_MULTISITE_TEMPLATE/drupal7_multisite_template.git" drupal7_multisite_template
cd drupal7_multisite_template
git checkout master

# ---

echo -n "

---

Do you want to add an upstream remote for drupal7_multisite_template? E.g. if this is a
forked repo, you can add the fork's source repo so you can then pull in changes
by running: git fetch upstream; git checkout master; git merge upstream/master

Press Y/n: "

old_stty_cfg=$(stty -g)
stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
if echo "$answer" | grep -iq "^y" ;then
  # Add remotes.
  GITHUBUSER_MULTISITE_TEMPLATE_REMOTE=$GITHUBUSER_SITES_COMMON_REMOTE
  echo "What is the upstream Github account to pull changes from? Leave blank to use the default: '$GITHUBUSER_MULTISITE_TEMPLATE_REMOTE'
  :"
  read GITHUBUSER_MULTISITE_TEMPLATE_REMOTE_ENTERED
  if [ ! "x$GITHUBUSER_MULTISITE_TEMPLATE_REMOTE_ENTERED" = "x" ]; then
    GITHUBUSER_MULTISITE_TEMPLATE_REMOTE=$GITHUBUSER_MULTISITE_TEMPLATE_REMOTE_ENTERED
  fi

  cd $DEPLOYDIRECTORY/drupal7_multisite_template

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

# ---

echo "

---

Downloading the latest Drupal 7 release..."

cd $DEPLOYDIRECTORY/drupal7_core
drush dl drupal-7 --drupal-project-rename=www -y
cd www

echo "

---

Removing unwanted Drupal files: .gitignore, .htaccess, *.txt, sites/"

rm .htaccess
rm .gitignore
rm *.txt
rm -rf sites

echo "

---

Symlinking sites to $DEPLOYDIRECTORY/drupal7_sites_common:"

ln -s $DEPLOYDIRECTORY/drupal7_sites_common $DEPLOYDIRECTORY/drupal7_core/www/sites

# ---

echo -n "

---

Check out greyhead_common_features? (If you select 'no' here you will be asked if you want to check out drupal7_four_features instead).
Y/n: "

old_stty_cfg=$(stty -g)
stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
if echo "$answer" | grep -iq "^y" ;then
  cd $DEPLOYDIRECTORY
  git clone --recursive https://github.com/alexharries/drupal7_common_features.git drupal7_common_features

  echo "

  ---

  Symlinking sites/all/modules/features to $DEPLOYDIRECTORY/drupal7_common_features:"

  ln -s $DEPLOYDIRECTORY/drupal7_common_features $DEPLOYDIRECTORY/drupal7_core/www/sites/all/modules/features
else

  echo -n "

  ---

  Check out drupal7_four_features? Y/n: "

  old_stty_cfg=$(stty -g)
  stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
  if echo "$answer" | grep -iq "^y" ;then
    cd $DEPLOYDIRECTORY
    git clone --recursive https://github.com/fourcommunications/drupal7_four_features.git drupal7_four_features

    echo "

    ---

    Symlinking sites/all/modules/features to $DEPLOYDIRECTORY/drupal7_four_features:"

    ln -s $DEPLOYDIRECTORY/drupal7_four_features $DEPLOYDIRECTORY/drupal7_core/www/sites/all/modules/features
  fi

  echo -n "

  ---

  Check out drupal7_sites_projects? Y/n: "

  old_stty_cfg=$(stty -g)
  stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
  if echo "$answer" | grep -iq "^y" ;then
    cd $DEPLOYDIRECTORY
    git clone --recursive https://github.com/fourcommunications/drupal7_sites_projects.git drupal7_sites_projects
    cd drupal7_sites_projects
    git checkout develop

    if [ ! "x$MULTISITENAME" = "x" ]; then
      MULTISITELOCATION="$DEPLOYDIRECTORY/drupal7_sites_projects/$MULTISITENAME"

      if [ -d "$MULTISITELOCATION" ]; then
        echo "

        ---

        Symlinking $DEPLOYDIRECTORY/drupal7_core/www/sites/$MULTISITENAME to $MULTISITELOCATION:"

        ln -s $MULTISITELOCATION $DEPLOYDIRECTORY/drupal7_core/www/sites/$MULTISITENAME
      else
        echo "Multisite directory $MULTISITELOCATION not found."
      fi

      DRUSHALIASNAME="$MULTISITENAME.aliases.drushrc.php"
      DRUSHALIASLOCATION="$DEPLOYDIRECTORY/drupal7_sites_projects/_drush_aliases/$DRUSHALIASNAME"
      if [ -f "$DRUSHALIASLOCATION" ]; then
        echo "

        ---

        Symlinking $DRUSHALIASLOCATION to $DEPLOYDIRECTORY/drupal7_core/www/sites/all/drush/$DRUSHALIASNAME:"

        if [ -d "$DEPLOYDIRECTORY/drupal7_core/www/sites/all/drush" ]; then
          mkdir "$DEPLOYDIRECTORY/drupal7_core/www/sites/all/drush"
        fi

        ln -s $DRUSHALIASLOCATION $DEPLOYDIRECTORY/drupal7_core/www/sites/all/drush/$DRUSHALIASNAME
      fi

      echo "

      Symlinking $DEPLOYDIRECTORY/drupal7_core/www/sites/$MULTISITENAME/files to $FILESPATH:"

      ln -s $FILESPATH $DEPLOYDIRECTORY/drupal7_core/www/sites/$MULTISITENAME/files

      if [ ! "x$SITEURI" = "x" ]; then
        echo "

        ---

        Creating the settings.this_site_url.info file at $DEPLOYDIRECTORY/drupal7_sites_projects/$MULTISITENAME/settings.this_site_url.info"

        echo "SETTINGS_SITE_URLS[] = $SITEURI" > "$DEPLOYDIRECTORY/drupal7_sites_projects/$MULTISITENAME/settings.this_site_url.info"

        echo "

        Done.

        "
      fi
    fi
  fi
fi

# ---

echo "

---

Symlinking profiles/greyhead to ../profiles/greyhead:"

cd $DEPLOYDIRECTORY/drupal7_core/www/profiles
ln -s $DEPLOYDIRECTORY/drupal7_core/profiles/greyhead


# ---

echo "

---

Copying local_databases.php and local_settings.php to $DEPLOYDIRECTORY/drupal7_core.

You will need to manually configure the database connection as this script
isn't awesome enough to do that for you yet:"

LOCALDATABASESFILEPATH="$DEPLOYDIRECTORY/drupal7_core/local_databases.php"
cp $DEPLOYDIRECTORY/drupal7_multisite_template/local_databases.template.php $LOCALDATABASESFILEPATH

LOCALSETTINGSFILEPATH="$DEPLOYDIRECTORY/drupal7_core/local_settings.php"
cp $DEPLOYDIRECTORY/drupal7_multisite_template/local_settings.template.php $LOCALSETTINGSFILEPATH

# ---

if [ ! "x$MULTISITENAME" = "x" ]; then
  echo -n "

  ---

  Do you know the database connection details? Y/n: "

  old_stty_cfg=$(stty -g)
  stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
  if echo "$answer" | grep -iq "^y" ;then
    # Get DB connection details: DB name, username, password, host, and port.
    until [ ! "x$DBNAME" = "x" ]; do
      echo "What is the database name? (required)"
      read DBNAME
      if [ "x$DBNAME" = "x" ]; then
          echo "Oh no! You need to provide the database name. Please go back and try again."
      fi
    done
    echo "Using: $DBNAME.

    ---"

    until [ ! "x$DBUSERNAME" = "x" ]; do
      echo "What is the database username? (required)"
      read DBUSERNAME
      if [ "x$DBUSERNAME" = "x" ]; then
          echo "Oh no! You need to provide the database username. Please go back and try again."
      fi
    done
    echo "Using: $DBUSERNAME.

    ---"

    until [ ! "x$DBPASSWORD" = "x" ]; do
      echo "What is the database password? (required)"
      read DBPASSWORD
      if [ "x$DBPASSWORD" = "x" ]; then
          echo "Oh no! You need to provide the database password - blank passwords aren't allowed (sorry). Please go back and try again."
      fi
    done
    echo "Using: $DBPASSWORD.

    ---"

    echo "What is the database host? Leave empty for the default: 127.0.0.1"
    read DBHOST
    if [ "x$DBHOST" = "x" ]; then
      DBPORT="127.0.0.1"
    fi
    echo "Using: $DBHOST

    ---"

    echo "What is the database port? Leave empty for the default: 3306"
    read DBPORT
    if [ "x$DBPORT" = "x" ]; then
      DBPORT=3306
    fi
    echo "Using: $DBPORT

    ---"

    perl -pi -e "s/{{MULTISITE_IDENTIFIER}}/$MULTISITENAME/g" $LOCALDATABASESFILEPATH
    perl -pi -e "s/{{DOMAIN}}/$SITEURI/g" $LOCALDATABASESFILEPATH
    perl -pi -e "s/{{DATABASENAME}}/$DBNAME/g" $LOCALDATABASESFILEPATH
    perl -pi -e "s/{{DATABASEUSERNAME}}/$DBUSERNAME/g" $LOCALDATABASESFILEPATH
    perl -pi -e "s/{{DATABASEPASSWORD}}/$DBPASSWORD/g" $LOCALDATABASESFILEPATH
    perl -pi -e "s/3306/$DBPORT/g" $LOCALDATABASESFILEPATH

    echo "

    Done. Please check the output of local_databases.php to make sure it looks okay:

    ****************************************************************************"

    cat $LOCALDATABASESFILEPATH

    echo "
    ****************************************************************************
    "

    echo "Testing database..."

    cd $DEPLOYDIRECTORY/drupal7_core/www/sites/$MULTISITENAME
    drush rr
    drush cc all
    drush status
  fi
else
  echo "You can't set up the database because no multisite directory name has been entered.

  Please manually edit $DEPLOYDIRECTORY/drupal7_core/local_databases.php to set
  the database details.

  "
fi

cd $DEPLOYDIRECTORY
