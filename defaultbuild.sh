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
        | sed "s|PROJNAMEANDDIRNAME|$PROJNAME/$DIRNAME|g"  \
        > $TMPDIR/footer.tex
}

function _callPandoc() {
    mkdir -p "$PWD/_dist/$PROJNAME"
    PDFPATH="$PWD/_dist/$PROJNAME/$DIRNAME.pdf"

    ### Which writing system?
    DOC_PROP_SCRIPT="$(_getmetainfo .script)"
    if [[ $DOC_PROP_SCRIPT != latin ]]; then
        EXTRA_SCRIPT_TAG="-$DOC_PROP_SCRIPT"
    fi

    ### Actually compile PDF
    pandoc "$TMPFN" \
        $PANDOC_LATEX_VARS \
        -V author="$(_getmetainfo .author)" \
        -V date="$(LANG=en_US.UTF-8 date '+%Y-%m-%d (%a)')" \
        -H "$TMPDIR/header.tex" \
        --include-after-body="$TMPDIR/footer.tex" \
        -o "$PDFPATH"
}

function _buildTarget() {
    DIRPATH="$(realpath "$1")"
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
    for DIRPATH in $PROJDIR/*; do
        if [[ -e $DIRPATH/info.json ]]; then
            _buildTarget "$DIRPATH"
        fi
    done
fi


if [[ " $@ " == *" --push "* ]] || [[ " $@ " == *" -p "* ]]; then
    ./pushtomirror.sh
fi
