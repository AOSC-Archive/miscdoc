#!/bin/bash

PROJDIR="$(dirname $(realpath "$0"))"
PROJNAME="$(basename "$PROJDIR")"

if [[ ! -e $PWD/README.md ]]; then
    echo "[ERROR] You may only invoke this script at the root of the repository, where 'README.md' is located. Run './$(basename $PWD)/build.sh' instead."
    exit 1
fi



PANDOC_LATEX_VARS="
-s
-V papersize:a4
-V geometry=textwidth=35em,tmargin=25mm,bmargin=32mm
-V hyperrefoptions=colorlinks=false,pdfpagemode=FullScreen
-V fontsize=12pt
-f markdown
-t pdf
--listings
--number-sections
--toc-depth=2
--shift-heading-level-by=-1
--pdf-engine=xelatex
--toc
"

function getmetainfo() {
    jq -rM $1 $DIRPATH/info.json
}
function buildTmpFile() {
    TASKDIR="$1"
    printf "" > $TMPFN
    TOTALCOUNT="$(ls $TASKDIR/*.md | wc -l)"
    CURRENTCOUNT=1
    for MDFILE in $(ls $TASKDIR/*.md); do
        cat $MDFILE >> $TMPFN
        if [[ $CURRENTCOUNT != $TOTALCOUNT ]]; then
            printf "\n\n\pagebreak\n\n" >> $TMPFN
        fi
        CURRENTCOUNT="$((CURRENTCOUNT+1))"
    done
    sed "s|PROJNAME|$PROJNAME/$DIRNAME|g" "$PWD/.tex/footer.tex" >> $TMPFN
}

mkdir -p "$PWD/_dist"
for DIRPATH in $PROJDIR/*; do
    if [[ -d $DIRPATH ]]; then
        DIRNAME="$(basename "$DIRPATH")"
        echo "[INFO] Building document $DIRPATH"

        if [[ ! -e $DIRPATH/info.json ]]; then
            echo "[ERROR] Cannot find 'info.json'"
        fi

        TMPFN=/tmp/.pandocTask--$PROJNAME-$DIRNAME.md
        buildTmpFile "$PROJDIR/$DIRNAME"

        ### Start compiling
        pandoc $TMPFN \
            $PANDOC_LATEX_VARS \
            -H "$PWD/.tex/header.tex" \
            -V mainfont='Libertinus Serif' \
            -V sansfont='Inter' \
            -V monofont='JetBrains Mono NL' \
            -V author="$(getmetainfo .author)" \
            -V date="$(date +%Y-%m-%d)" \
            -o "$PROJDIR/$DIRNAME.pdf" 

        ### Send to destination
        mkdir -p "$PWD/_dist/$PROJNAME"
        cp -af "$PROJDIR/$DIRNAME.pdf" "$PWD/_dist/$PROJNAME/$DIRNAME.pdf"

        rm $TMPFN
    fi
done

