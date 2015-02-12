#! /usr/bin/env python3
'''
        © 2013 Luís Gomes <luismsgomes@gmail.com>

Usage: {progname} (src|tst|ref) CONFIG_JSON DOCID_REGEX FILES

Example:

CONFIG_JSON='{{"srclang":"English","trglang":"Portuguese","setid":"example_set","sysid":"example_mt_system","refid":"original"}}'
DOCID_REGEX='(?:src|ref|tst)/([^/]+)\.(?:en|pt)$'

{progname} src "$CONFIG_JSON" "$DOCID_REGEX" src/*.en > src.xml
{progname} ref "$CONFIG_JSON" "$DOCID_REGEX" ref/*.pt > ref.xml
{progname} tst "$CONFIG_JSON" "$DOCID_REGEX" tst/*.pt > tst.xml

'''

import json, re, sys
from xml.sax.saxutils import escape

if len(sys.argv) < 5 or sys.argv[1] not in 'src|tst|ref'.split('|'):
    print(__doc__.format(progname=sys.argv[0]), file=sys.stderr)
    exit(1)

filetype, config_json, regex, *filenames = sys.argv[1:]

config = json.loads(config_json)

if not config:
    exit("invalid CONFIG_JSON")

regex = re.compile(regex)
if not regex:
    exit("invalid DOCID_REGEX")

if regex.groups != 1:
    exit("DOCID_REGEX has {} capturing groups; expected exactly 1".format(regex.groups))

print('<?xml version="1.0" encoding="UTF-8"?>')
print('<!DOCTYPE mteval SYSTEM "ftp://jaguar.ncsl.nist.gov/mt/resources/mteval-xml-v1.3.dtd">')
print('<mteval>')

if filetype == 'src':
    print('<srcset setid="{setid}" srclang="{srclang}">'.format(**config))
    close_set = '</srcset>'

elif filetype == 'tst':
    print('<tstset setid="{setid}" srclang="{srclang}" trglang="{trglang}" sysid="{sysid}">'.format(**config))
    close_set = '</tstset>'

else: # filetype == 'ref'
    print('<refset setid="{setid}" srclang="{srclang}" trglang="{trglang}" refid="{refid}">'.format(**config))
    close_set = '</refset>'

for filename in filenames:
    match = regex.match(filename)
    if not match:
        print("warning: skipping {} because DOCID_REGEX did not match".format(filename), file=sys.stderr)
        continue
    with open(filename) as lines:
        print('<doc docid="{}">'.format(escape(match.group(1))))
        for num, line in enumerate(lines, start=1):
            print('<p>')
            print('<seg id="{}"> {} </seg>'.format(num, escape(line.strip())))
            print('</p>')
        print('</doc>')
print(close_set)
print('</mteval>')
