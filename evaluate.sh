#! /bin/bash
#
# January 2015, Luís Gomes <luismsgomes@gmail.com>
#
#

function main {
    init "$@"
    evaluate
}

function init {
    set -u # abort if trying to use uninitialized variable
    set -e # abort on error
    progname=$0
    mydir=$(cd $(dirname $0); pwd)
    . $mydir/lib/bash_functions.sh
    test $# == 3 || fatal "usage: $0 CONFIGURATION SRC_LANG TRG_LANG"
    test -f "$1" || fatal "config file '$1' does not exist"
    configfile=$1
    src=${2,,}
    trg=${3,,}
    configname=$(perl -pe 's{(?:.*/)?([^\.]*)(?:\..*)?}{\1}' <<< $configfile)
    source "$configfile"
    lang1=${lang1,,}
    lang2=${lang2,,}
    map check_config_variable workdir lang1 lang2 eval_sets
    if test "$src" != "$lang1" -a "$src" != "$lang2"; then
        fatal "invalid SRC_LANG ($src); expected either ${^^lang1} or ${lang2^^}"
    fi
    if test "$trg" != "$lang1" -a "$trg" != "$lang2"; then
        fatal "invalid SRC_LANG ($trg); expected either ${^^lang1} or ${lang2^^}"
    fi
    if test "$src" == "$trg"; then
        fatal "SRC_LANG and TRG_LANG must be different"
    fi
    share_dir=$(perl -e 'use Treex::Core::Config; my ($d) = Treex::Core::Config->resource_path(); print "$d\n";')
    create_dir "$workdir"
    pushd "$workdir"
}

function evaluate {
    # TODO:  parallelize translation and evaluation
    if $new_session; then
        now=$(date '+%Y%m%d_%H%M%S')
        session_dir="$workdir/evaluations/$src-$trg/$now"
        create_dir "$session_dir"
        pushd "$workdir/evaluations/$src-$trg"
            ln -sfT "$now" last
        popd
    else
        session_dir="$workdir/evaluations/$src-$trg/last"
    fi

    for eval_set in $eval_sets; do
        set_name=$(basename $eval_set .$lang1$lang2.gz)
        if ! test -f $session_dir/$set_name.$src ||
             test -f $session_dir/$set_name.$trg; then
            zcat $eval_set |
            $mydir/bin/prune_unaligned_sentpairs.py |
            tee >(cut -f 1 > $session_dir/$set_name.$lang1) |
                  cut -f 2 > $session_dir/$set_name.$lang2
        fi
        numlinesin=$(wc -l < $session_dir/$set_name.$src)
        numlinesout=0
        if test -f $session_dir/$set_name.$trg.mt; then
            numlinesout=$(wc -l < $session_dir/$set_name.$trg.mt)
        fi
        if test $numlinesin != $numlinesout; then
            pushd $mydir
                ./translate.sh $configfile $src $trg \
                    < $session_dir/$set_name.$src \
                    > $session_dir/$set_name.$trg.mt
                    paste $session_dir/$set_name.{$src,$trg,$trg.mt} |
                    $mydir/bin/tsv_to_html.py \
                        > $session_dir/$set_name.$src-$trg-mt_$trg.html
            popd
            numlinesout=$(wc -l < $session_dir/$set_name.$trg.mt)
        fi
        paste $session_dir/$set_name.{$src,$trg,$trg.mt} |
        $mydir/bin/tsv_to_html.py \
            > $session_dir/$set_name.$src-$trg-mt_$trg.html
        if test $numlinesin != $numlinesout; then
            fatal "translation output has different number of lines than input"
        fi
        CONFIG_JSON="{\"srclang\":\"$src\",\"trglang\":\"$trg\",\"setid\":\"$set_name\",\"sysid\":\"qtleap-$configname-$src-$trg\",\"refid\":\"human\"}"
        DOCID_REGEX=".*($set_name).*"
        $mydir/bin/txt_to_mteval_xml.py src "$CONFIG_JSON" "$DOCID_REGEX" \
            $session_dir/$set_name.$src > $session_dir/$set_name.$src.xml
        $mydir/bin/txt_to_mteval_xml.py ref "$CONFIG_JSON" "$DOCID_REGEX" \
            $session_dir/$set_name.$trg > $session_dir/$set_name.$trg.xml
        $mydir/bin/txt_to_mteval_xml.py tst "$CONFIG_JSON" "$DOCID_REGEX" \
            $session_dir/$set_name.$trg.mt > $session_dir/$set_name.$trg.mt.xml
        $mydir/bin/mteval-v13a.pl \
            -s $session_dir/$set_name.$src.xml \
            -r $session_dir/$set_name.$trg.xml \
            -t $session_dir/$set_name.$trg.mt.xml |
        tee $session_dir/$set_name.$src-$trg.eval.txt
    done
}

main "$@"
