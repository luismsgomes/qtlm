#! /bin/bash

if test $# != 5; then
    echo "usage: $0 SRCLANG TRGLANG TREESDIR OUTDIR txt" >&2
    echo "usage: $0 SRCLANG TRGLANG TREESDIR OUTPREFIX conll" >&2
    exit 1
fi

src=$1 trg=$2 trees_dir=$3 out=$4 fmt=$5

case $fmt in
    txt)
    treex -L $src -S src \
        Write::LemmatizedBitexts \
            to_language=$trg \
            to_selector=tst \
            path=$out \
        -- $trees_dir/*.treex.gz
    ;;
    conll)
    #tmp=$(tempfile --directory=$trees_dir --prefix=sorted_list --suffix=.txt)
    files=$(ls $trees_dir | grep -P '\.treex.gz$' | sort -g |
            while read base; do echo $trees_dir/$base; done)
    treex \
        Write::CoNLLX \
        language=$src \
        selector=src \
        to=$out.$src.conll \
        Write::CoNLLX \
        language=$trg \
        selector=tst \
        to=$out.$trg.conll \
        -- $files
    # Treex should allow -- @$tmp
    #    perhaps it's a bug?
    #trap "rm -v $tmp" EXIT
    ;;
    *)
    echo "$0: invalid format '$fmt'; use either 'txt' or 'conll'" >&2
    exit 1
    ;;
esac

