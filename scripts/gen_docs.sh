#! /bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."

pandoc --from markdown --to html5 \
    --smart --toc --standalone --self-contained --css doc/pandoc.css \
    --output doc/ReadMe.html < doc/ReadMe.md

pandoc --from markdown --to html5 \
    --smart --standalone --self-contained --css doc/pandoc.css \
    --output doc/ToDo.html < doc/ToDo.md

sed -i 's/<nav id="TOC">/<h1>Table of Contents<\/h1>\n<nav id="TOC">/' \
    doc/ReadMe.html

pandoc --from markdown --to plain \
    --smart --toc \
    --output doc/ReadMe.txt < doc/ReadMe.md

pandoc --from markdown --to latex \
    --smart --standalone \
    --output doc/ReadMe.tex < doc/ReadMe.md

tools/search_replace.py '==>' '|||' \
    '\begin{document}==>
\makeatletter
\newcommand{\verbatimfont}[1]{\renewcommand{\verbatim@font}{\ttfamily#1}}
\makeatother
\begin{document}
\verbatimfont{\small}%
' doc/ReadMe.tex

{
    cd doc
    pdflatex ReadMe > ReadMe.pdflatex 2>&1
}
