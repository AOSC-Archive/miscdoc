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
    cat $TASKDIR/*-*.md > $TASKDIR/_FullText.md
    TOTALCOUNT="$(ls $TASKDIR/*-*.md | wc -l)"
    CURRENTCOUNT=1
    for MDFILE in $(ls $TASKDIR/*-*.md); do
        cat $MDFILE >> $TMPFN
        if [[ $CURRENTCOUNT != $TOTALCOUNT ]]; then
            printf "\n\n\clearpage\n\n" >> $TMPFN
        fi
        CURRENTCOUNT="$((CURRENTCOUNT+1))"
    done
    if [[ -e $TASKDIR/999-appendix.tex ]]; then
        printf "\n\n\clearpage\n\n" >> $TMPFN
        cat $TASKDIR/999-appendix.tex >> $TMPFN
    fi
    sed "s|PROJNAME|$PROJNAME/$DIRNAME|g" "$PWD/.tex/footer.tex" \
        | sed 's|CONTRIBUTORSLIST|$(getmetainfo .contributors)|' \
        >> $TMPFN
}

mkdir -p "$PWD/_dist"
for DIRPATH in $PROJDIR/*; do
    if [[ -d $DIRPATH ]]; then
        DIRNAME="$(basename "$DIRPATH")"
        echo "[INFO] Building document '$DIRNAME'"

        if [[ ! -e $DIRPATH/info.json ]]; then
            echo "[ERROR] Cannot find 'info.json'"
        fi

        TMPFN="/tmp/.pandocTask--$PROJNAME-$DIRNAME.md"
        buildTmpFile "$PROJDIR/$DIRNAME"

        ### Start compiling
        pandoc "$TMPFN" \
            $PANDOC_LATEX_VARS \
            -H "$PWD/.tex/header.tex" \
            -V author="$(getmetainfo .author)" \
            -V date="$(LANG=en_US.UTF-8 date '+%Y-%m-%d (%a)')" \
            -o "$PROJDIR/$DIRNAME.pdf" 

        ### Send to destination
        mkdir -p "$PWD/_dist/$PROJNAME"
        mv "$PROJDIR/$DIRNAME.pdf" "$PWD/_dist/$PROJNAME/$DIRNAME.pdf"

        rm "$TMPFN"
    fi
done

