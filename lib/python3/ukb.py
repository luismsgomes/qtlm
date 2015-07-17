"""
Wrapper for UKB word sense disambiguation tool.

2015 Luís Gomes <luismsgomes@gmail.com>
"""

import collections
import os
import os.path
import re
import subprocess
import tempfile

import tsv

assert os.path.isdir(os.environ["QTLM_ROOT"])

libshare = os.path.join(os.environ["QTLM_ROOT"], "lib", "share", "ukb")
executable = os.path.join(os.environ["QTLM_ROOT"], "tools", "ukb_wsd")
config = {
    "en": {
        "kb": "extendedGraph.bin",
        "dic": "wnet30_dict.txt",
        "super": "index.sense",
        "tags": {
            "n": ["NN", "NNS", "NNP", "NNPS"],
            "v": ["VB", "VBD", "VBG", "VBN", "VBP", "VBZ"],
            "a": ["JJ", "JJR", "JJS"],
            "r": ["RB", "RBR", "RBS"],
        }
    },
    "pt": {
        "kb": "extendedGraph.bin",
        "dic": "mwnpt30verified-true_dict.txt",
        "super": "index.sense",
        "tags": {
            "n": ["CN"],
            "v": ["V", "INF", "VAUX", "VAUXINF", "VAUXGER", "GER", "PPT"],
            "a": ["ADJ"],
            "r": ["ADV"],
            "p": ["PPA"],
        }
    }
}

for lang in config:
    for ftype in "kb", "dic", "super":
        config[lang][ftype] = os.path.join(libshare, config[lang][ftype])
    config[lang]["ukb_tags"] = {
        tag: ukb_tag for ukb_tag in config[lang]["tags"]
        for tag in config[lang]["tags"][ukb_tag]
    }

_ssense_indexes = dict()

def get_ssense_index(lang):
    if lang in _ssense_indexes:
        return _ssense_indexes[lang]
    index = dict()
    with open(config[lang]["super"]) as lines:
        for linenum, line in enumerate(lines, start=1):
            m = re.match(r".*:(\d+):.*:.*:.*\s+(\d+)\s+.+\s+.+", line)
            if m:
                index[m.group(2)] = m.group(1)
            else:
                print("line", linenum, "has unexpected format:", line, 
                      end="", file=sys.stderr)
    _ssense_indexes[lang] = index
    return index

def escape_lemma(lemma):
    return re.sub(r"\W", "_", lemma)

def wsd(lang, sentences, debugfile=None):
    if lang not in config:
        raise ValueError("Sorry, language "+lang+
                         "is not supported or configured")
    ukb_tags = config[lang]["ukb_tags"]
    ssense_index = get_ssense_index(lang)
    with tempfile.NamedTemporaryFile("wt", delete=False) as f:
        ukb_input_fname = f.name
        if debugfile:
            print(ukb_input_fname, file=debugfile)
        for sent_id, sentence in enumerate(sentences):
            words = [
                "{}#{}#w{}#1".format(escape_lemma(tok.lemma.lower()),
                                     ukb_tags[tok.pos], word_id)
                for word_id, tok in enumerate(sentence)
                if tok.lemma != "_" and tok.pos in ukb_tags
            ]
            if words:
                print("ctx_{}".format(sent_id), file=f)
                print(*words, file=f)
                print(file=f)
    argv = [executable, "--ppr", "-K", config[lang]["kb"],
        "-D", config[lang]["dic"], ukb_input_fname]
    if debugfile:
        print(" ".join(argv), file=debugfile)
    try:
        stderr = subprocess.DEVNULL if debugfile is None else debugfile
        ukb_output = subprocess.check_output(argv, universal_newlines=True,
                                             stderr=stderr)
    finally:
        if debugfile:
            print("LEAVING UKB INPUT FILE FOR INSPECTION: "+ukb_input_fname,
                  file=debugfile)
        else:
            os.remove(ukb_input_fname)
        pass
    for line in map(str.strip, ukb_output.split("\n")):
        if not line or line.startswith("!!"):
            continue
        line, _, lemma = line.rpartition("!!")
        #lemma = lemma.strip()
        ctx_id, w_id, *synsetids = line.strip().split()
        if not synsetids:
            continue
        synsetids = [synsetid[:-2] if re.match(".+-.", synsetid) else synsetid
                     for synsetid in synsetids]
        supersenses = [ssense_index[synsetid] for synsetid in synsetids]
        assert re.match("ctx_\d+", ctx_id)
        assert re.match("w\d+", w_id)
        ctx_id = int(ctx_id[4:])
        w_id = int(w_id[1:])
        sentences[ctx_id][w_id].synsetids = " ".join(synsetids)
        sentences[ctx_id][w_id].supersenses = " ".join(supersenses)
    return sentences


if __name__ == "__main__":
    import sys
    
    if len(sys.argv) != 2:
        exit("usage: {} LANG < TEXT > OUTPUT".format(sys.argv[0]))
    lang = sys.argv[1]

    class TokenObject:
        def __init__(self, **attrs): 
            self.__dict__.update(attrs)

    sentences = list(tsv.read_namedtuples("token", group=True))

    if sentences:
        for sentence in sentences:
            for tok in sentence:
                input_fields = tok._fields
                break
            else:
                continue
            break
        else:
            exit("document is empty (no tokens)!")

        TokenTuple = collections.namedtuple("token", input_fields + ("synsetids", "supersenses"))
        sentences = [ # convert namedtuples to objects
            [TokenObject(synsetids=None, supersenses=None, **token._asdict()) for token in sentence]
            for sentence in sentences
        ]
        sentences = wsd(lang, sentences)
        sentences = [ # convert objects to namedtuples
            [TokenTuple(**token.__dict__) for token in sentence]
            for sentence in sentences
        ]
        tsv.write_namedtuples(sentences, group=True)

