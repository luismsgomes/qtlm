#! /bin/bash

if test $# != 3; then
    echo "usage: $0 LANG SELECTOR TREESDIR" >&2
    exit 1
fi

lang=$1 sel=$2 treesdir=$3

files=$(find $treesdir | grep -P '\.streex$' | sort -g | head -n 2)
treex -L $lang -S $sel \
    Write::ToWSD path=$treesdir.wsd.$lang.$sel.in \
    -- $files


for f in $(ls $treesdir.wsd.$lang.$sel.in); do
    ukb_work_dir=$treesdir.wsd.$lang.$sel.in/$f.ukb
    mkdir $ukb_work_dir

    $QTLM_ROOT/tools/lx-wsd-module-v1.5/lx-wsd-doc-module.sh \
        $QTLM_ROOT/tools/lx-wsd-module-v1.5/UKB \
        $ukb_work_dir \
        $lang \
        $treesdir.$lang.$sel.wsd.in
done

