# Greyhead's Drupal Scripts of Usefulness

A collection of rough-and-ready, probably-broken and certainly work-in-progress scripts for my deployment workflows. Use at your own risk (personally, I wouldn't... ;o).

## build.sh

 Interactive script which builds a copy of a Drupal 7 install. You are prompted to choose whether the build type is local, development, staging or live, and have the choice of which repositories to pull the various components from.

 This script can also set up a new multisite as a project, with a Bootstrap template theme, and can also run the Drupal installer or import a database dump if required.

 If you're building for Four Communications, there is [a detailed build guide on the intranet](https://dev.fourplc.com/webteam/webteam-documentation-index/build-drupal)

 To run using the latest version in Master, copy the following line of commands as a single line and paste into a Bash terminal:

 (Note that your command line Git must be able to authenticate you to Github using your private/public SSH key pair - see this Github article for help on setting this up.)

 ```echo "This script will download and run the Greyhead Drupal build script. If a copy of the script already exists here, you may need to provide your sudo password so it can be deleted."; echo ""; rm build.sh; if [ -f "build.sh" ]; then echo -n "Please enter your sudo password if prompted to remove the existing build script: "; sudo rm build.sh; fi; DATETIMENOW=`date +%Y%m%d-%H%M%S`; curl -o build.sh "https://raw.githubusercontent.com/alexharries/drupal-scripts-of-usefulness/master/build.sh?$DATETIMENOW" && if [ -f "build.sh" ]; then echo ""; echo "Done :)"; echo ""; echo "Running ./build.sh now - you may be prompted for your sudo password to continue"; echo ""; chmod +x build.sh && ./build.sh; else echo "It doesn't look like build.sh downloaded from https://raw.githubusercontent.com/alexharries/drupal-scripts-of-usefulness/master/build.sh - please manually download it, save it as build.sh and then run it by calling:"; echo "chmod +x build.sh && ./build.sh"; fi```

## gitstatus.sh

 This script will loop through all the repos in a build and run a git status. This is useful to quickly get an idea of which projects have uncommitted work.

## checkout-branch.sh

 This script will change the checked-out branch in a build, for example when you have finished development and have committed and pushed, and need to check out the rc branch to merge your work in.

## update.sh

 Updates a Drupal 7 build with changes made to upstream repositories.

## merge.sh

 Merges the Git repositories in a build into the current branch.

 You should run this command after committing all your work, e.g. to 'develop', and then running ./checkout-branch.sh to switch to the next branch.

## live-deploy.sh

 This script is used to deploy a tagged Drupal 7 release. It uses a tag archive created by using the build.sh script to create a live build.

 If you're building for Four Communications, there is [a detailed deployment guide on the intranet](https://dev.fourplc.com/webteam/webteam-documentation-index/live-release-process-existing-sites).

 _**Important: this script is very much an alpha release and may not work on some strangely-configured servers, and also won't work for Drupal deployments which aren't based on the Drupal 7 Product. You MUST understand the commands in the script and how it works before using it, and always have a backup and a plan in mind of how to roll back if you're updating an active live site, especially if it's for a big client! :)**_

 Copy the following commands as a single line and paste into a Bash terminal:

 ```echo "This script will download and run the Greyhead Drupal live deployment script. If a copy of the script already exists here, you may need to provide your sudo password so it can be deleted."; echo ""; rm live-deploy-greyhead.sh; if [ -f "live-deploy-greyhead.sh" ]; then echo -n "Please enter your sudo password if prompted to remove the existing deployment script: "; sudo rm live-deploy-greyhead.sh; fi; DATETIMENOW=`date +%Y%m%d-%H%M%S`; curl -o live-deploy-greyhead.sh "https://raw.githubusercontent.com/alexharries/drupal-scripts-of-usefulness/master/live-deploy.sh?$DATETIMENOW" && if [ -f "live-deploy-greyhead.sh" ]; then echo ""; echo "Done :)"; echo ""; echo "Running ./live-deploy-greyhead.sh now - you will be prompted for your sudo password to continue"; echo ""; sudo chmod +x live-deploy-greyhead.sh && sudo ./live-deploy-greyhead.sh; else echo "It doesn't look like live-deploy.sh downloaded from https://raw.githubusercontent.com/alexharries/drupal-scripts-of-usefulness/master/live-deploy.sh - please manually download it, save it as live-deploy-greyhead.sh and then run it by calling:"; echo "sudo chmod +x live-deploy-greyhead.sh && sudo ./live-deploy-greyhead.sh"; fi```

 You will then be asked a series of questions about the locations of the tag archive, the webroot location, and so on. Once the script has enough information to perform the deployment, you are asked to confirm twice that you want to go ahead with the deployment.

 A database backup is made before the deployment is performed, and in the event of a failed deployment, you will be given the option to roll back to the previous database and code.

## drush-rebuild-registry.sh

 This script will rebuild the Drupal registry and forcibly flush caches.

 It takes the following parameters:

 --buildpath: the ABSOLUTE path to the build directory (i.e. the directory which contains the core/ directory). This must not end in a slash. If you provide this, you must also provide --multisitename.

 --multisitename: the multisite directory name e.g. --multisitename=manbo - if you provide this, you must also provide --buildpath.

 --uri: the site's URI, e.g. manbo.4com.local

## enable-development-settings.sh

 This script is used to turn off the Production Settings feature,
 enable the Development Settings feature, and revert those settings.

 Parameters:

 --uri: the site's URI, e.g. manbo.4com.local
