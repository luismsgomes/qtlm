#! /bin/bash

if [ $# != 1 ]; then
    echo "usage: $0 TREEXFILE" >&2
    exit 1
fi

treex -e DEBUG -L pt -S src Read::Sentences $QTLM_ROOT/scen/en-pt/pt_w2a.scen Write::Treex to="$1"
