#! /usr/bin/env python3

import sys

if len(sys.argv) != 5:
    exit("usage: {} SEP PATSEP SEARCH_REPLACE_STRINGS FILE".format(sys.argv[0]))

progname, sep, patsep, pats, fname = sys.argv

with open(fname) as f:
    text = f.read()

for pat in pats.split(patsep):
    if not pat:
        continue
    cols = pat.split(sep)
    if len(cols) != 2:
        exit("{}: invalid pattern: {}".format(progname, pat))
    search, replace = cols
    text = text.replace(search, replace)

with open(fname, "w") as out:
    out.write(text)

