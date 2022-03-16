#!/bin/bash

PROJDIR="$(dirname $(realpath "$0"))"
PROJNAME="$(basename "$PROJDIR")"
echo $PROJNAME
# exit 0

if [[ ! -e $PWD/README.md ]]; then
    echo "[ERROR] You may only invoke this script at the root of the repository, where 'README.md' is located. Run './$(basename $PWD)/build.sh' instead."
    exit 1
fi



PANDOC_LATEX_VARS="
-s
-V papersize:a4
-V geometry=textwidth=36em,tmargin=25mm,bmargin=32mm
-V hyperrefoptions=colorlinks=false,pdfpagemode=FullScreen
-V fontsize=12pt
-f markdown
-t pdf
--number-sections
--toc-depth=2
--shift-heading-level-by=-1
--pdf-engine=xelatex
--toc
"

mkdir -p "$PWD/_dist"
for DIRPATH in $PROJDIR/*; do
    if [[ -d $DIRPATH ]]; then
        DIRNAME="$(basename "$DIRPATH")"
        echo "[INFO] Building document $DIRPATH"
        if [[ ! -e $DIRPATH/info.json ]]; then
            echo "[ERROR] Cannot find 'info.json'"
        fi
        info_AUTHOR="$(jq -rM .author $DIRPATH/info.json)"
        cat \
            "$PROJDIR/$DIRNAME"/*.md \
            "$PWD/.tex/footer.tex" \
        | pandoc \
            $PANDOC_LATEX_VARS \
            -V mainfont='Libertinus Serif' \
            -V monofont='JetBrains Mono NL' \
            -V author="$info_AUTHOR" \
            -V date="$(date +%Y-%m-%d)" \
            -o "$PROJDIR/$DIRNAME.pdf"
        mkdir -p "$PWD/_dist/$PROJNAME"
        cp -af "$PROJDIR/$DIRNAME.pdf" "$PWD/_dist/$PROJNAME/$DIRNAME.pdf"
    fi
done

