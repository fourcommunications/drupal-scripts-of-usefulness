#!/bin/sh

# Script from http://stackoverflow.com/a/3278427 with love :)

LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse @{u})
BASE=$(git merge-base @ @{u})

if [ "$LOCAL" = "$REMOTE" ]; then
    echo "Up-to-date"
elif [ "$LOCAL" = "$BASE" ]; then
    echo "Need to pull"
elif [ "$REMOTE" = "$BASE" ]; then
    echo "Need to push"
else
    echo "Diverged"
fi
