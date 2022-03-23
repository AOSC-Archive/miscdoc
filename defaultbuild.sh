#!/bin/bash

if [[ -z $1 ]]; then
    echo "Usage:"
    echo "    ./defaultbuild.sh   {PROJNAME}"
fi

PROJDIR="$(realpath "$1")"
PROJNAME="$(basename "$PROJDIR")"

if [[ ! -e $PWD/README.md ]]; then
    echo "[ERROR] You may only invoke this script at the root of the repository, where 'README.md' is located. Run './$(basename "$PWD")/build.sh' instead."
    exit 1
fi



PANDOC_LATEX_VARS="
-s
-V papersize:a4
-V geometry=textwidth=39em,tmargin=25mm,bmargin=25mm
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

function _getmetainfo() {
    jq -rM $1 $DIRPATH/info.json
}
function _buildTmpFile() {
    TASKDIR="$1"

    ### Build README.md
    printf "Notes:\n\n" > $TASKDIR/README.md
    printf -- "- This full-text file is generated from the source files and shall not be edited manually.\n" >> $TASKDIR/README.md
    printf -- "- PDF: https://repo.aosc.io/misc/artifacts/miscdoc/$PROJNAME/${DIRNAME}.pdf\n\n\n\n" >> $TASKDIR/README.md
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

    ### Build Footer
    cat "$PWD/.tex/footer.tex" \
        | sed "s|PROJNAMEANDDIRNAME|$PROJNAME/$DIRNAME|g"  \
        | sed "s|BRANCHNAME|$(git branch --show-current)|" \
        > $TMPDIR/footer.tex
}
function _callPandoc() {
    mkdir -p "$PWD/_dist/$PROJNAME"
    PDFPATH="$PWD/_dist/$PROJNAME/$DIRNAME.pdf"
    pandoc "$TMPFN" \
        $PANDOC_LATEX_VARS \
        -V author="$(_getmetainfo .author)" \
        -V date="$(LANG=en_US.UTF-8 date '+%Y-%m-%d (%a)')" \
        -H "$PWD/.tex/header.tex" \
        --include-after-body="$TMPDIR/footer.tex" \
        -o "$PDFPATH"
}
function _buildTarget() {
    DIRPATH="$1"
    DIRNAME="$(basename "$DIRPATH")"
    echo "[INFO] Building document '$DIRNAME'"

    if [[ ! -e $DIRPATH/info.json ]]; then
        echo "[ERROR] Cannot find 'info.json'"
    fi

    TMPDIR="/tmp/aosc-miscdoc-pandoc-tmp-$(uuidgen v4).$PROJNAME.$DIRNAME"
    mkdir -p "$TMPDIR"

    TMPFN="/tmp/.pandocTask--$PROJNAME-$DIRNAME.md"
    _buildTmpFile "$PROJDIR/$DIRNAME"

    ### Start compiling
    mkdir -p "$PWD/_dist/$PROJNAME"
    PDFPATH="$PWD/_dist/$PROJNAME/$DIRNAME.pdf"
    if [[ ! -e $PWD/.DoNotMakePDF ]]; then
        _callPandoc
    fi
    
    du -h "$PDFPATH"
    rm "$TMPFN"
    rm -r "$TMPDIR"
}

for DIRPATH in $PROJDIR/*; do
    if [[ -e $DIRPATH/info.json ]]; then
        _buildTarget "$DIRPATH"
    fi
done

