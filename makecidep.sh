#!/bin/bash

### This script is used to prepare CI dependencies.
### After preparing, please run 'pushtomirror.sh' to push them onto 'repo.aosc.io'.

rm -r .cidep
mkdir -p .cidep
cd .cidep


# wget 'https://fonts.google.com/download?family=Inter' -O Inter.zip
# yes | unzip Inter.zip
# rm Inter.zip
# mv static Inter

mkdir -p Inter
rsync -av /usr/share/texmf-dist/fonts/opentype/public/inter Inter/

wget 'https://fonts.google.com/download?family=JetBrains%20Mono' -O JetBrains_Mono.zip
yes | unzip JetBrains_Mono.zip
rm JetBrains_Mono.zip
mv static JetBrains_Mono
