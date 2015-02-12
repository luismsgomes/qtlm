#! /bin/bash
#
# January 2015, Luís Gomes <luismsgomes@gmail.com>
#
#

usage=<<END
usage:
    $0
    $0 clean
    $0 save "some description"
END

function main {
    init "$@"
    evaluate_all
}

function init {
    mydir=$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)
    source "$mydir/lib/bash_functions.sh"
    set_pedantic_bash_options
    check_lang1_lang2_variables
    check_src_trg_variables
    if test -f "conf/defaults.sh"; then
        source "conf/defaults.sh"
    else
        stderr "config file 'conf/defaults.sh' does not exist; skipping"
    fi
    if test -f "conf/$lang1-$lang2/defaults.sh"; then
        source "conf/$lang1-$lang2/defaults.sh"
    else
        stderr "config file 'conf/$lang1-$lang2/defaults.sh' does not exist; skipping"
    fi
    if test -f "conf/$lang1-$lang2/$conf.sh"; then
        source "conf/$conf.sh"
    else
        fatal "config file 'conf/$lang1-$lang2/$conf.sh' does not exist"
    fi
    check_required_variables treexdir workdir num_procs eval_sets running_on_a_big_machine
    share_dir=$(get_treex_share_dir)
    create_dir "$workdir"
    if test $# == 0; then
        cmd=evaluate_all
    elif test $# == 1 && test "$1" == "clean"; then
        cmd=clean
    elif test $# == 2 && test "$1" == "save"; then
        cmd=save
        description=$2
    else
        echo "$usage" >&2
        exit 1
    fi
}

function clean {

}

function evaluate_all {
    if $new_session; then
        now=$(date '+%Y%m%d_%H%M%S')
        session_dir="$workdir/evaluations/$src-$trg/$now"
        create_dir "$session_dir"
        pushd "$workdir/evaluations/$src-$trg" >&2
            if test -L last; then
                previous=$(readlink last)
                pushd "$now" >&2
                    ln -sT ../$previous previous
                popd >&2
                rm -f last
            fi
            ln -sT "$now" last
        popd >&2
    else
        session_dir="$workdir/evaluations/$src-$trg/last"
    fi

    for eval_set in $eval_sets; do
        evaluate $eval_set &
        $running_on_a_big_machine || wait
    done
    wait
}

function evaluate {
    echo "evaluating $1"
    eval_set=$1
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
        pushd $mydir >&2
            t_session_dir=$session_dir/$set_name.$trg.mt.details
            create_dir $t_session_dir
            session_dir=$t_session_dir ./translate.sh \
                $configfile $src $trg \
                < $session_dir/$set_name.$src \
                > $session_dir/$set_name.$trg.mt

            ls $t_session_dir |
            grep -P '^[0-9]+\.s?treex(\.gz)?$' \
                > $t_session_dir/list.txt

            paste $session_dir/$set_name.{$src,$trg,$trg.mt} |
            $mydir/bin/tsv_to_html.py \
                > $session_dir/$set_name.$src-$trg-mt_$trg.html
        popd >&2
        numlinesout=$(wc -l < $session_dir/$set_name.$trg.mt)
    fi
    paste $session_dir/$set_name.{$src,$trg,$trg.mt} |
    $mydir/bin/tsv_to_html.py \
        > $session_dir/$set_name.$src-$trg-mt_$trg.html
    if test $numlinesin != $numlinesout; then
        fatal "translation output has different number of lines than input"
    fi
    CONFIG_JSON="{\"srclang\":\"$src\",\"trglang\":\"$trg\",\"setid\":\"$set_name\",\"sysid\":\"qtleap-$conf-$src-$trg\",\"refid\":\"human\"}"
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
        -t $session_dir/$set_name.$trg.mt.xml \
    > $session_dir/$set_name.$src-$trg.eval.txt
    echo $session_dir/$set_name.$src-$trg.eval.txt

    if test -L $session_dir/previous &&
            test -f $session_dir/previous/$set_name.$trg.mt; then
        $mydir/bin/compare.sh $src $trg \
            $session_dir/previous/$set_name.{$src,$trg,$trg.mt} \
            $session_dir/$set_name.$trg.mt \
            > $session_dir/$set_name.$trg.mt.inc
        $mydir/bin/comparegrams.py $session_dir/$set_name.{$trg,$trg.mt} \
            > $session_dir/$set_name.$trg.mt.ngrams

    fi
    echo $session_dir/$set_name.$trg.mt.inc
}

main "$@"
