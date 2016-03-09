# Greyhead's Drupal Scripts of Usefulness

A collection of rough-and-ready, probably-broken and certainly work-in-progress scripts for my deployment workflows. Use at your own risk (personally, I wouldn't... ;o).

## live-deploy.sh

This script is used to deploy a tagged Project Drupal7 release.

**WARNING: this script is very much an alpha release and may not work on some strangely-configured servers, and also won't work for Drupal deployments which aren't based on Project Drupal 7. You MUST understand the commands in the script and how it works before using it, and always have a backup and a plan in mind of how to roll back if you're updating an active live site! :)**

To run using the latest version in Master, copy the following line of commands as a single line and paste into a Bash terminal:

    SCRIPTURL="https://raw.githubusercontent.com/alexharries/drupal-scripts-of-usefulness/master/live-deploy.sh"; echo "This script will download and run the Greyhead Drupal live deployment script. If a copy of the script already exists here, you may need to provide your sudo password so it can be deleted."; echo ""; if [ -f "live-deploy.sh" ]; then echo -n "Please enter your sudo password if prompted to remove the existing deployment script: "; sudo rm live-deploy.sh; fi;  curl -O $SCRIPTURL && if [ -f "live-deploy.sh" ]; then echo ""; echo "Done :)"; echo ""; echo "Running ./live-deploy.sh now - you will be prompted for your sudo password to continue"; echo ""; sudo chmod +x live-deploy.sh && sudo ./live-deploy.sh; else echo "It doesn't look like live-deploy.sh downloaded - please manually download it, and then run it by calling:"; echo "sudo chmod +x live-deploy.sh && sudo ./live-deploy.sh"; fi

You will then be asked a series of questions about the locations of the tag archive, the webroot location, and so on. Once the script has enough information to perform the deployment, you are asked to confirm twice that you want to go ahead with the deployment.

A database backup is made before the deployment is performed, and in the event of a failed deployment, you will be given the option to roll back to the previous database and code.

### Using a script from another URL

To use a deployment script from another location - e.g. a different branch or repository - change the value of SCRIPTURL, e.g.:

    SCRIPTURL="https://www.example.com/path/to/script.sh"; echo "This script will download and run the Greyhead Drupal live deployment script. If a copy of the script already exists here, you may need to provide your sudo password so it can be deleted."; echo ""; if [ -f "live-deploy.sh" ]; then echo -n "Please enter your sudo password if prompted to remove the existing deployment script: "; sudo rm live-deploy.sh; fi;  curl -O $SCRIPTURL && if [ -f "live-deploy.sh" ]; then echo ""; echo "Done :)"; echo ""; echo "Running ./live-deploy.sh now - you will be prompted for your sudo password to continue"; echo ""; sudo chmod +x live-deploy.sh && sudo ./live-deploy.sh; else echo "It doesn't look like live-deploy.sh downloaded - please manually download it, and then run it by calling:"; echo "sudo chmod +x live-deploy.sh && sudo ./live-deploy.sh"; fi

### Where is this script from?

You can view the script and fork a copy of its repo from here:

https://github.com/alexharries/drupal-scripts-of-usefulness/blob/master/live-deploy.sh
