#! /usr/bin/env python3

import http.client
import json
import sys
import urllib.parse

host = "194.117.45.194"
port = 8081

if len(sys.argv) != 3:
    exit("usage: {} sourceLang targetLang < original.txt > translation.txt".format(sys.argv[0]))

sourceLang, targetLang = sys.argv[1:]

# http://194.117.45.194:8081/rpc
# action=translate
# sourceLang=en
# targetLang=pt
# text=Hello
# detokenize=true
# alignmentInfo=true
# nBestSize=2

conn = http.client.HTTPConnection(host, port=port)
for num, line in enumerate(sys.stdin, start=1):
    line = line.strip()
    if not line:
        print()
        continue
    params = urllib.parse.urlencode({
        "sourceLang": sourceLang,
        "targetLang": targetLang,
        "text": line,
        "detokenize": "true",
        #"alignmentInfo": "true",
        #"nBestSize": 2
    })
    sys.stderr.write("{}: translating sentence {}  ({} tokens)... ".format(
        sys.argv[0], num, len(line.split())))
    sys.stderr.flush()
    conn.request("GET", "/rpc?"+params)
    response = conn.getresponse()
    sys.stderr.write("done.\n")
    sys.stderr.flush()
    if response.status != 200:
        exit("{}: got status {} {} from server, aborting".format(sys.argv[0], response.status, response.reason))
    result = json.loads(response.read().decode("utf-8"))
    if result["errorCode"] != 0:
        print("{}: translation of sentence {} failed: {}".format(
              sys.argv[0], num, result["errorMessage"]), file=sys.stderr)
        print()
        continue
    for translation in result["translation"]:
        chunks = []
        for translated in translation["translated"]:
            chunks.append(translated["text"])
        print(" ".join(chunks))
        break
conn.close()
