#! /bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."

pandoc --standalone --smart --toc --css doc/pandoc.css --self-contained \
    --from markdown --to html5 --output doc/ReadMe.html < doc/ReadMe.md

pandoc --smart --toc --from markdown --to plain --output doc/ReadMe.txt \
    < doc/ReadMe.md

# Word format is not looking good in some places:
#pandoc --smart --toc --from markdown --to docx --output doc/ReadMe.docx \
#    < doc/ReadMe.md

