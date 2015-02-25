#! /usr/bin/env python3
#
#  2013, Luís Gomes <luismsgomes@gmail.com>
#

import cgi
import sys

if len(sys.argv) == 3:
    title = sys.argv[1]
    url_tpl=sys.argv[2]
    if "{id0" not in url_tpl and "{id1" not in url_tpl:
        exit("{}: invalid URL template: either {id0} or {id1} (or both) must be present")
elif len(sys.argv) == 2:
    title = sys.argv[1]
    url_tpl = ''
else:
    exit("usage: {} TITLE [URL_TPL]".format(sys.argv[0]))


css = '''
body {
    background-color: ghostwhite;
    font-family: arial, sans-serif;
    font-size: 88%;
}
h1 {
    text-align: center;
}
table {
    width: 100%;
    table-layout: fixed;
    border: none;
    border-collapse: collapse;
}
td {
    border-bottom: 1px solid cadetblue;
    padding: .6em;
}
b {
    color: lightgray;
}
'''

preamble = '''<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>{title}</title>
<style>{css}</style>
</head>
<body>
<h1>{title}</h1>
<table>
'''

if url_tpl:
    row = '<tr><th width="30em"><a id="{id1}" href="{url}">{id1}</a></th><td>{cols}</td></tr>'
else:
    row = '<tr><th width="30em"><a id="{id1}">{id1}</a></th><td>{cols}</td></tr>'

postamble = '''
</table>
</body>
</html>
'''

clean = lambda sent: cgi.escape(sent).replace('\\n', '<b>&para;</b>')
print(preamble.format(title=clean(title), css=css))
for id0, line in enumerate(sys.stdin):
    id1 = id0 + 1
    cols = line.rstrip('\n').split('\t')
    cols = '</td><td>'.join([clean(col) for col in cols])
    url = url_tpl.format(id0=id0, id1=id1)
    print(row.format(id1=id1, url=url, cols=cols))
print(postamble)

