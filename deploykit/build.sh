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
-V geometry=textwidth=38em,tmargin=25mm,bmargin=32mm
-V hyperrefoptions=colorlinks=false,pdfpagemode=FullScreen
-V fontsize=11pt
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

    ### Build README.md
    printf "Notes:\n\n" > $TASKDIR/README.md
    printf -- "- This full-text file is generated from the source files and shall not be edited manually.\n" >> $TASKDIR/README.md
    printf -- "- PDF: https://neruthesgithubdistweb.vercel.app/miscdoc/$PROJNAME/${DIRNAME}.pdf\n\n\n\n" >> $TASKDIR/README.md
    cat $TASKDIR/*-*.md >> $TASKDIR/README.md

    ### Build TMPFN
    printf "" > $TMPFN
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
    sed "s|PROJNAMEANDDIRNAME|$PROJNAME/$DIRNAME|g" "$PWD/.tex/footer.tex" \
        | sed 's|CONTRIBUTORSLIST|$(getmetainfo .contributors)|' \
        >> $TMPFN
}

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
        mkdir -p "$PWD/_dist/$PROJNAME"
        PDFPATH="$PWD/_dist/$PROJNAME/$DIRNAME.pdf"
        pandoc "$TMPFN" \
            $PANDOC_LATEX_VARS \
            -H "$PWD/.tex/header.tex" \
            -V author="$(getmetainfo .author)" \
            -V date="$(LANG=en_US.UTF-8 date '+%Y-%m-%d (%a)')" \
            -o "$PDFPATH"
        
        du -h "$PDFPATH"
        rm "$TMPFN"
    fi
done

