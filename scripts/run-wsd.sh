#! /bin/bash

set -u # abort if using unset variable
set -e # abort if command exits with non-zero status

if test $# != 3; then
    echo "usage: $0 LANG SELECTOR TREESDIR" >&2
    exit 1
fi

lang=$1 sel=$2 treesdir=${3%/}

# files=$(find $treesdir | grep -P '\.streex$' | sort -g)
# treex -L $lang -S $sel \
#     Write::ToWSD fmt=tsv path=$treesdir.wsd.$lang.$sel.in \
#     -- $files

export PYTHONPATH=$QTLM_ROOT/lib/python3

find $treesdir-wsd-$lang-$sel -name '*.wsd-input' |
while read f; do
	python3 -m ukb $lang < $f > ${f/wsd-input/wsd-output}

    # ukb_work_dir=$f-ukb
    # mkdir -vp $ukb_work_dir

    # $QTLM_ROOT/tools/lx-wsd-module-v1.5/lx-wsd-doc-module.sh \
    #     $QTLM_ROOT/tools/lx-wsd-module-v1.5/UKB \
    #     $ukb_work_dir $lang $f
done

