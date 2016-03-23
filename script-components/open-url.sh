#!/bin/bash

URL=$1

echo "URL: $URL"

if which xdg-open > /dev/null
then
  xdg-open $URL
elif which gnome-open > /dev/null
then
  gnome-open $URL
else
  open $URL
fi

