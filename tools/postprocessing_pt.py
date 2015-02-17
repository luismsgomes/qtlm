#! /usr/bin/env python3
#
# January 2015, Luís Gomes <luismsgomes@gmail.com>
#
#

import re, sys

_contractions = '''
a_ a à
a_ à à
a_ aquela àquela
a_ aquelas àquelas
a_ aquele àquele
a_ aqueles àqueles
a_ aquilo àquilo
a_ as às
a_ o ao
a_ onde aonde
a_ os aos
com_ mim comigo
com_ nós connosco
com_ si consigo
com_ ti contigo
com_ vós convosco
de_ a da
de_ aí daí
de_ alguma nalguma
de_ algumas nalgumas
de_ algum nalgum
de_ alguns nalguns
de_ ali dali
de_ antes dantes
de_ aquela daquela
de_ aquelas daquelas
de_ aquele daquele
de_ aqueles daqueles
de_ aquêles daquêles
de_ aqueloutros daqueloutros
de_ aqui daqui
de_ aquilo daquilo
de_ as das
de_ ela dela
de_ elas delas
de_ ele dele
de_ êle dêle
de_ eles deles
de_ èles dèles
de_ êles dêles
de_ entre dentre
de_ essa dessa
de_ essas dessas
de_ esse desse
de_ êsse dêsse
de_ esses desses
de_ êsses dêsses
de_ esta desta
de_ estas destas
de_ este deste
de_ êste dêste
de_ estes destes
de_ êstes dêstes
de_ isso disso
de_ isto disto
de_ o do
de_ onde donde
de_ os dos
de_ outra doutra
de_ outras doutras
de_ outro doutro
de_ outros doutros
de_ uma duma
de_ umas dumas
de_ um dum
de_ uns duns
em_ aa naa
em_ alguma nalguma
em_ algumas nalgumas
em_ algum nalgum
em_ alguns nalguns
em_ a na
em_ aquela naquela
em_ aquelas naquelas
em_ aquele naquele
em_ aqueles naqueles
em_ aquilo naquilo
em_ as nas
em_ ela nela
em_ elas nelas
em_ ele nele
em_ êle nêle
em_ eles neles
em_ êles nêles
em_ essa nessa
em_ essas nessas
em_ esse nesse
em_ esses nesses
em_ esta nesta
em_ estas nestas
em_ este neste
em_ estes nestes
em_ isso nisso
em_ isto nisto
em_ o no
em_ os nos
em_ outra noutra
em_ outras noutras
em_ outro noutro
em_ outros noutros
em_ uma numa
em_ umas numas
em_ um num
em_ uns nuns
esta_ outra estoutra
-lhe_ -a -lha
lhe_ a lha
-lhe_ -as -lhas
lhe_ as lhas
-lhe_ -o -lho
lhe_ o lho
-lhe_ -os -lhos
lhe_ os lhos
-me_ -a -ma
me_ a ma
-me_ -as -mas
me_ as mas
-me_ -o -mo
me_ o mo
-me_ -os -mos
me_ os mos
por_ a pela
por_ as pelas
por_ o pelo
por_ os pelos
-te_ -as -tas
te_ as tas
-te_ -a -ta
te_ a ta
-te_ -os -tos
te_ os tos
-te_ -o -to
te_ o to
de_ outrem doutrem
aquele_ outro aqueloutro
aqueles_ outros aqueloutros
aquela_ outra aqueloutra
aquelas_ outras aqueloutras
para_ a prà
para_ as pràs
para_ o prò
para_ os pròs
-em_ as -nas
'''

_contractions = dict(entry.rsplit(None, 1)
	for entry in _contractions.strip().split('\n'))

_contractions_regex = re.compile('\\b({})\\b'.format('|'.join(map(re.escape, _contractions))), re.I)

def _contractions_sub_callback(matchobj):
	s = matchobj.group(0)
	r = _contractions.get(s.lower(), None)
	return r if s.islower() else r.upper() if s.isupper() else r.capitalize()

def redo_contractions(text):
	return _contractions_regex.subn(_contractions_sub_callback, text)[0]

_extrawhitespace_regex = re.compile(r'''[‘“«({\[] | [,\.:;?!\]})»”’…]''')

def _extrawhitespace_sub_callback(matchobj):
	return matchobj.group(0).strip()

_doublequotes_regex = re.compile(r'''(^| )" ([^"]+) "( |$)''')
_doublequotes_replace = r'\1"\2"\3'

_singlequotes_regex = re.compile(r'''(^| )' (.+) '( |$)''')
_singlequotes_replace = r"\1'\2'\3"

_numbers_regex = re.compile(r'''([0-9]+) ([%ºª]|\.[oa]s?\.?|°)''', re.I)
_numbers_replace = r'\1\2'

_mesoclisis_regex = re.compile(r'(\w+)-CL-(\w+)\s+-(\w+)')
_mesoclisis_replace = r'\1-\3-\2'

_enclisis_regex = re.compile(r'(\w+)#?\s+(-\w+)')
_enclisis_replace = r'\1\2'

def untokenize(text):
	text = _extrawhitespace_regex.subn(_extrawhitespace_sub_callback, text)[0]
	text = _singlequotes_regex.subn(_singlequotes_replace, text)[0]
	text = _doublequotes_regex.subn(_doublequotes_replace, text)[0]
	text = _numbers_regex.subn(_numbers_replace, text)[0]
	text = _mesoclisis_regex.subn(_mesoclisis_replace, text)[0]
	text = _enclisis_regex.subn(_enclisis_replace, text)[0]
	return text

if __name__ == '__main__':
	for line in sys.stdin:
		sys.stdout.write(untokenize(redo_contractions(line)))
		sys.stdout.flush()
