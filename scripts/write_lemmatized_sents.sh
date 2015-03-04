#! /bin/bash

if test $# != 4; then
    echo "usage: $0 SRCLANG TRGLANG TREESDIR OUTDIR" >&2
    exit 1
fi

src=$1 trg=$2 trees_dir=$3 out_dir=$4

treex -L $src -S src \
    Write::LemmatizedBitexts \
        to_language=$trg \
        to_selector=tst \
        path=$out_dir \
    -- $trees_dir/*.treex.gz

