#!/bin/bash

rm miscdoc.tar.xz 2>/dev/null
cat README.md > _dist/README.md

### Create directories
mkdir -p _dist/_Markdown
for PROJ in $(cat projlist); do
    mkdir -p "_dist/_Markdown/$PROJ"
done

### Save Markdown files
for READMEMDPATH in */*/README.md; do
    DOCNAMEDIR="$(dirname "$READMEMDPATH")"
    DESTPATH="_dist/_Markdown/$DOCNAMEDIR.md"
    # echo "Saving '$READMEMDPATH' to '$DESTPATH'"
    cat "$READMEMDPATH" > "$DESTPATH"
done

### Generate tarball
tar --xz -cf miscdoc.tar.xz _dist

### Final notes
echo "Created release file 'miscdoc.tar.xz'"
echo "The release version should be '$(date +'%Y%m%d')'"
realpath miscdoc.tar.xz
