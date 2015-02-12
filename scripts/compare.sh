#! /bin/bash

if test $# != 6; then
    echo "usage: $0 SRC_LANG TRG_LANG SRC_TEXT REF_TEXT TST1_TEXT TST2_TEXT" >&2
    exit
fi

src_lang=$1
trg_lang=$2
src=$3
ref=$4
tst1=$5
tst2=$6

mydir=$(dirname $0)
treex=$(which treex)

for tst in $tst1 $tst2; do
    if ! test -f $tst.resume; then
        $treex \
            Read::AlignedSentences \
                ${src_lang}_src=$src \
                ${trg_lang}_ref=$ref \
                ${trg_lang}_tst=$tst \
            Print::TranslationResume \
                source_language=$src_lang \
                language=$trg_lang \
                selector=tst \
            > $tst.resume
    fi
done

$mydir/compare_stats.pl $tst1.resume $tst2.resume
