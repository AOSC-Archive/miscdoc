#!/bin/bash

echo "[INFO] Starting full rebuild..."

PROJLIST="$(cat projlist)"
for i in $PROJLIST; do
    echo "[INFO] Working in '$i'..."
    if [[ -e $i/build.sh ]]; then
        bash $i/build.sh
    else
        bash defaultbuild.sh $i
    fi
done

echo "[INFO] Completed full rebuild."
