#! /bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."

pandoc --from markdown --to html5 \
    --smart --toc --standalone --self-contained --css doc/pandoc.css \
    --output doc/ReadMe.html < doc/ReadMe.md

pandoc --from markdown --to plain \
    --smart --toc \
    --output doc/ReadMe.txt < doc/ReadMe.md

