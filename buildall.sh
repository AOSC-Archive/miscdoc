#!/bin/bash

BRANCH_NAME="$(git branch --show-current)"

if [[ " $@ " == *" --force "* ]]; then
    f_FORCE_ALL=y
    echo "[INFO] Starting full rebuild under '--force' parameter..."
else
    echo "[INFO] Building for the current branch '$BRANCH_NAME'..."
fi


function _tryBuildProj() {
    PROJNAME="$1"
    ### The current branch must start with the PROJNAME
    if [[ $f_FORCE_ALL != y ]] && [[ $PROJNAME != $BRANCH_NAME ]] && [[ $PROJNAME/* != $BRANCH_NAME ]]; then
        echo "[INFO] Skipping '$PROJNAME' due to branch mismatch..."
        return 0
    fi
    printf "\n"
    echo "[INFO] Working in '$PROJNAME'..."
    if [[ -e $PROJNAME/build.sh ]]; then
        bash $PROJNAME/build.sh
    else
        bash defaultbuild.sh $PROJNAME
    fi
}

PROJLIST="$(cat projlist)"
for PROJNAME in $PROJLIST; do
    _tryBuildProj "$PROJNAME"
done

printf "\n"
echo "[INFO] Completed full rebuild."
