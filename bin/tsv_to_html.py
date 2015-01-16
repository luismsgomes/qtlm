#! /usr/bin/env python3
#
#  2013, Luís Gomes <luismsgomes@gmail.com>
#

import cgi
import sys

print('''<html>
<head>
<meta http-equiv="Content-Type" content="text/html;charset=UTF-8">
<style>
body { background-color: ghostwhite; font-family: arial, sans-serif; }
table { table-layout: fixed; width: 100%;
        border: none; border-collapse: collapse; }
td { font-size: 88%; border-bottom: 1px solid cadetblue; padding: .6em; }
b { color: lightgray; }
</style>
</head>
<body>
<table>''')

clean = lambda sent: cgi.escape(sent).replace('\\n', '<b>&para;</b>')
for line in sys.stdin:
    cols = line.rstrip('\n').split('\t')
    print('<tr>', *[clean(col) for col in cols], sep='<td>')

print('''</table>
</body>
</html>''')

