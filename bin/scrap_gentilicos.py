#! /usr/bin/env python3

from lxml import html
from urllib.request import urlopen

for letter in 'abcdefghijklmnopqrstuvwxyz':
    url = 'http://www.portaldalinguaportuguesa.org/index.php?action=toponyms&action=toponyms&act=list&letter='+letter
    with urlopen(url) as f:
        tree = html.fromstring(f.read().decode('utf-8'))
        gentilicos = tree.xpath('//td[@title="gentílico"]/a/text()')
        for g in gentilicos:
            print(g)

