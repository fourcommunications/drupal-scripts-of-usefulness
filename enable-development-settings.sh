#!/bin/bash
# This script is used to turn off the Production Settings feature,
# enable the Development Settings feature, and revert those settings.
echo "Disabling production_settings, boost_config, and advagg settings,"
echo "and enabling development_settings, and reverting the"
echo "development_settings feature."
echo ""
drush dis production_settings advanced_aggregation_settings advagg boost_config boost -y
echo "."
drush en development_settings -y
echo "."
drush fr development_settings -y
echo "."
drush cc all
echo "All done."
