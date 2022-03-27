#!/bin/bash

if [[ -z $1 ]]; then
    echo "Usage:"
    echo "    Build entire directory:       $  ./defaultbuild.sh   PROJNAME"
    echo "    Build single document:        $  ./defaultbuild.sh   PROJNAME/DOCNAME"
fi

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




### Compatibility layer
function _du() {
    if [[ -z "$GITHUB_ACTIONS" ]]; then
        du $@
    fi
}




### Core functions
function _getmetainfo() {
    jq -rM $1 $DOCDIRPATH/info.json
}

function _buildTmpFile() {
    TASKDIR="$1"

    ### Build README.md
    printf "Notes:\n\n" > $TASKDIR/README.md
    printf -- "- This full-text file is generated from the source files and shall not be edited manually.\n" >> $TASKDIR/README.md
    printf -- "- PDF: https://repo.aosc.io/misc/artifacts/miscdoc/$PROJNAME/${DOCNAME}.pdf\n\n\n\n" >> $TASKDIR/README.md
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

    ### Build Header
    cat "$PWD/.tex/header.tex" > $TMPDIR/header.tex
    if [[ "$(_getmetainfo .latex_features)" == "" ]]; then
        echo "[INFO] Empty 'latex_features' property."
    else
        echo "[INFO] Applying features: '$(_getmetainfo .latex_features)'"
        for FEAT in $(_getmetainfo .latex_features); do
            cat "$PWD/.tex/feat-$FEAT.tex" >> $TMPDIR/header.tex
        done
    fi
    ### Build Footer
    cat "$PWD/.tex/footer.tex" \
        | sed "s|PROJNAMEANDDOCNAME|$PROJNAME/$DOCNAME|g"  \
        > $TMPDIR/footer.tex
}

function _callPandoc() {
    mkdir -p "$PWD/_dist/$PROJNAME"
    PDFPATH="$PWD/_dist/$PROJNAME/$DOCNAME.pdf"

    ### GitHub Actions
    if [[ "$GITHUBCI" == y ]]; then
        PDFPATH="$PWD/_dist/$PROJNAME/${PROJNAME}__${DOCNAME}.pdf"
    fi

    ### Other info
    DOCLANG=en_US
    if [[ "$(_getmetainfo .lang)" != "" ]]; then
        DOCLANG="$(_getmetainfo .lang)"
    fi

    ### Actually compile PDF
    pandoc "$TMPFN" \
        $PANDOC_LATEX_VARS \
        -V author="$(_getmetainfo .author)" \
        -V date="$(TZ=UTC LANG=$DOCLANG.UTF-8 date '+%Y-%m-%d (%a)')" \
        -H "$TMPDIR/header.tex" \
        --include-after-body="$TMPDIR/footer.tex" \
        -o "$PDFPATH"
}

function _buildTarget() {
    DOCDIRPATH="$(realpath "$1")"
    DOCNAME="$(basename "$DOCDIRPATH")"
    echo "[INFO] Building document '$DOCNAME'"

    if [[ ! -e $DOCDIRPATH/info.json ]]; then
        echo "[ERROR] Cannot find 'info.json'"
    fi

    TMPDIR="/tmp/aosc-miscdoc-pandoc-tmp-$(uuidgen v4).$PROJNAME.$DOCNAME"
    mkdir -p "$TMPDIR"

    TMPFN="/tmp/.pandocTask--$PROJNAME-$DOCNAME.md"
    _buildTmpFile "$PROJDIR/$DOCNAME"

    ### Start compiling
    mkdir -p "$PWD/_dist/$PROJNAME"
    PDFPATH="$PWD/_dist/$PROJNAME/$DOCNAME.pdf"
    if [[ ! -e $PWD/.DoNotMakePDF ]]; then
        _callPandoc
    fi
    
    _du -h "$PDFPATH"
    rm "$TMPFN"
    # echo "[INFO] Remember to clear temporary files."
    rm -r "$TMPDIR"
}


if [[ "$PWD" == "$(dirname "$(dirname "$(realpath "$1")")")" ]]; then
    ### Is a single document
    echo "[INFO] Building single document"
    DOCDIR="$(realpath "$1")"
    PROJDIR="$(dirname "$DOCDIR")"
    PROJNAME="$(basename "$PROJDIR")"
    _buildTarget "$(realpath $1)"
else
    ### Is not a single document
    echo "[INFO] Building entire directory"
    PROJDIR="$(realpath "$1")"
    PROJNAME="$(basename "$PROJDIR")"
    for DOCDIRPATH in $PROJDIR/*; do
        if [[ -e $DOCDIRPATH/info.json ]]; then
            _buildTarget "$DOCDIRPATH"
        fi
    done
fi


if [[ " $@ " == *" --push "* ]] || [[ " $@ " == *" -p "* ]]; then
    ./pushtomirror.sh
fi
