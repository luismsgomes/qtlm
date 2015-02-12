#! /usr/bin/env python3

import sys

for line in sys.stdin:
    line = line.rstrip("\n")
    cols = line.split("\t")
    cols = [col.strip() for col in cols]
    if len(cols) == 2 and all(cols):
        print(*cols, sep="\t")
