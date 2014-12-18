#! /bin/bash
set -u # abort if trying to use uninitialized variable
set -e # abort on error

function main {
	init "$@"
	get_corpus
	w2m
	align
	m2a
	a2t
	train
}

function init {
	progname=$0
	mydir=$(cd $(dirname $0); pwd)
	test $# == 1 || fatal "please give the configuration filename as argument"
	test -f "$1" || fatal "config file '$1' does not exist"
	configfile=$1
	source "$1"
	map check_config_variable workdir treexdir lang1 lang2 corpus num_procs
	for lang in $lang1 $lang2; do
		for step in w2m m2a a2t; do
			scen="$mydir/scen/${lang}_${step}.scen"
			test -f "$scen" ||
				fatal "missing ${step^^} scenario for ${lang^^}: $scen"
		done
	done
	create_dir "$workdir"
	pushd "$workdir"
	create_dir logs
}

function get_corpus {
	test -f list.txt && return
	corpusf1=${corpus/\{lang\}/$lang1}
	corpusf2=${corpus/\{lang\}/$lang2}
	test -f "$corpusf1" || fatal "corpus file '$corpusf1' does not exist"
	test -f "$corpusf2" || fatal "corpus file '$corpusf2' does not exist"
	create_dir batches corpus.{$lang1,$lang2}
	
	paste <(zcat "$corpusf1") <(zcat "$corpusf2") |
	gawk '$1 !~ /^\s*$/ && $2 !~ /^\s*$/' FS=$'\t' |
	tee >(cut -f 1 | split -d -a 8 -l 200 - corpus.$lang1/part_) |
	      cut -f 2 | split -d -a 8 -l 200 - corpus.$lang2/part_

	ls corpus.$lang1 | grep -P '^part_[0-9]*' > list.txt
}

function w2m {
	create_dir mtrees lemmas
	todo w2m
	for batch in $(ls batches | grep -P '^w2m_'); do
		ln -f batches/$batch corpus.$lang1/$batch
		ln -f batches/$batch corpus.$lang2/$batch
		$treexdir/bin/treex \
			Read::AlignedSentences \
				${lang1}_src=@corpus.$lang1/$batch \
				${lang2}_src=@corpus.$lang2/$batch \
			"$mydir/scen/${lang1}_w2m.scen" \
			"$mydir/scen/${lang2}_w2m.scen" \
			Write::Treex \
				storable=1 \
				substitute='{^.*/([^\/]*)\.streex}{mtrees/$1.streex}' \
			Write::LemmatizedBitexts \
				selector=src \
				language=$lang1 \
				to_language=$lang2 \
				to_selector=src \
				to='.' \
				substitute='{^.*/([^\/]*)}{lemmas/$1.txt}' \
			&> logs/$batch.log &
	done
	wait
}

function align {
	stderr "align"
}

function m2a {
	stderr "m2a"
}

function a2t {
	stderr "m2a"
}

function train {
	stderr "m2a"
}

# -------------- Aux functions ----------------

function todo {
	create_dir batches
	step=$1
	case $1 in
		w2m) trees=mtrees ;;
		m2a) trees=atrees ;;
		a2t) trees=ttrees ;;
		*) fatal "invalid step '$step'" ;;
	esac
	find batches -name "${step}_*" -delete
	comm -23 \
		list.txt \
		<(ls $trees | grep -oP '^.*\.streex$' | sed 's/.streex$//' | sort) |
	split -d -a 1 -n r/$num_procs - batches/${step}_
}

function stderr {
	echo "$progname: $@" >&2
}

function fatal {
	stderr "$@; aborting" >&2
	exit 1
}

function map {
	test $# -ge 2 ||
		fatal "map function requires at least two arguments; $# given"
	cmd=$1
	shift
	for arg in "$@"; do
		$cmd "$arg"
	done
}

function create_dir {
	for d in "$@"; do
		if ! test -d "$d" ; then
			mkdir -vp "$d"
			test -d "$d" || fatal "failed to create '$d'"
		fi
	done
}

function check_config_variable {
	test -n "$$1" || fatal "config variable '$1' is not set"
}

main "$@"

