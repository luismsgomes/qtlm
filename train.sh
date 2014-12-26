#! /bin/bash

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
	set -u # abort if trying to use uninitialized variable
	set -e # abort on error
	progname=$0
	mydir=$(cd $(dirname $0); pwd)
	test $# == 1 || fatal "please give the configuration filename as argument"
	test -f "$1" || fatal "config file '$1' does not exist"
	configfile=$1
	source "$1"
	map check_config_variable workdir treexdir treexsharedir \
		lang1 lang2 corpus num_procs rm_giza_files
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
	test -f corpus/parts.txt && return 0
	stderr "$(date) get_corpus started"
	corpusf1=${corpus/\{lang\}/$lang1}
	corpusf2=${corpus/\{lang\}/$lang2}
	test -f "$corpusf1" || fatal "corpus file '$corpusf1' does not exist"
	test -f "$corpusf2" || fatal "corpus file '$corpusf2' does not exist"
	create_dir batches corpus/{$lang1,$lang2}
	
	SPLITOPTS="-d -a 8 -l 200 --additional-suffix .txt"
	paste <(zcat "$corpusf1") <(zcat "$corpusf2") |
	gawk '$1 !~ /^\s*$/ && $2 !~ /^\s*$/' FS=$'\t' |
	tee >(cut -f 1 | split $SPLITOPTS - corpus/$lang1/part_) |
	      cut -f 2 | split $SPLITOPTS - corpus/$lang2/part_

	find corpus/$lang1 -name 'part_*.txt' -printf '%f\n' | sed 's/\.txt$//' |
	sort > corpus/parts.txt
	stderr "$(date) get_corpus finished"
}

function w2m {
	create_dir mtrees lemmas
	batches=$(todo w2m)
	changed=false
	if test -n "$batches"; then
		stderr "$(date) w2m started"
		for batch in $batches; do
			test -s batches/$batch || continue
			changed=true
			sed -i 's/\.streex$/\.txt/' batches/$batch
			ln -f batches/$batch corpus/$lang1/batch_$batch.txt
			ln -f batches/$batch corpus/$lang2/batch_$batch.txt
			$treexdir/bin/treex \
				Read::AlignedSentences \
					${lang1}_src=@corpus/$lang1/batch_$batch.txt \
					${lang2}_src=@corpus/$lang2/batch_$batch.txt \
				"$mydir/scen/${lang1}_w2m.scen" \
				"$mydir/scen/${lang2}_w2m.scen" \
				Write::Treex \
					storable=1 \
					substitute='{^.*/([^\/]*)\.streex}{mtrees/$1.streex}' \
				Write::LemmatizedBitexts \
					selector=src \
					language=$lang1 \
					to='.' \
					to_selector=src \
					to_language=$lang2 \
					substitute='{^.*/([^\/]*)}{lemmas/$1.txt}' \
				&> logs/$batch.log &
		done
		wait
		for batch in $batches; do
			rm -f corpus/{$lang1,$lang2}/batch_$batch.txt
		done
		stderr "$(date) w2m ended"
	fi
	if $changed || ! test -f lemmas.gz; then
		stderr $(date) "gzipping lemmas ..."
		find lemmas -name '*.txt' | sort | xargs cat | gzip > lemmas.gz
		stderr $(date) "gzipping lemmas finished"
	fi
}

function align {
	test -f lemmas.gz || fatal "$workdir/lemmas.gz does not exist"
	test lemmas.gz -nt alignments.gz || return 0
	stderr "$(date) align started"
	create_dir align_tmp
	$treexdir/devel/qtleap/bin/gizawrapper.pl \
		--tempdir=align_tmp \
		--bindir=$gizadir \
		lemmas.gz \
		--lcol=1 \
		--rcol=2 \
		--keep \
		--dirsym=gdfa,int,left,right,revgdfa \
		2> logs/align.log |
	paste <(zcat lemmas.gz | cut -f 1 | sed 's|^.*/|mtrees/|;s|\.txt|.streex|') - |
	gzip > alignments.gz
	if $rm_giza_files; then
		rm -rf align_tmp
	fi
	stderr "$(date) align ended"
}

function m2a {
	create_dir atrees
	batches=$(todo m2a)
	if test -n "$batches"; then
		stderr "$(date) m2a started"
		for batch in $batches; do
			test -s batches/$batch || continue
			ln -f batches/$batch mtrees/batch_$batch.txt
			$treexdir/bin/treex \
				Read::Treex \
					from=@mtrees/batch_$batch.txt \
				"$mydir/scen/${lang1}_m2a.scen" \
				"$mydir/scen/${lang2}_m2a.scen" \
				Align::A::InsertAlignmentFromFile \
					from=alignments.gz \
					inputcols=gdfa_int_left_right_revgdfa_therescore_backscore \
					selector=src \
					language=$lang1 \
					to_selector=src \
					to_language=$lang2 \
				Align::ReverseAlignment2 \
					language=$lang1 \
					layer=a \
				Write::Treex \
					storable=1 \
					substitute='{mtrees}{atrees}' \
				&> logs/$batch.log &
		done
		wait
		for batch in $batches; do
			rm -f mtrees/batch_$batch.txt
		done
		stderr "$(date) m2a ended"
	fi
}

function a2t {
	create_dir ttrees $lang1-$lang2/v $lang2-$lang1/v
	batches=$(todo a2t)
	if test -n "$batches"; then
		stderr "$(date) a2t started"
		for batch in $batches; do
			test -s batches/$batch || continue
			ln -f batches/$batch atrees/batch_$batch.txt
			$treexdir/bin/treex \
				Read::Treex \
					from=@atrees/batch_$batch.txt \
				"$mydir/scen/${lang1}_a2t.scen" \
				"$mydir/scen/${lang2}_a2t.scen" \
				Align::T::CopyAlignmentFromAlayer \
					selector=src \
					language=$lang1 \
					to_selector=src \
					to_language=$lang2 \
				Align::T::CopyAlignmentFromAlayer \
					selector=src \
					language=$lang2 \
					to_selector=src \
					to_language=$lang1 \
				Write::Treex \
					storable=1 \
					substitute='{atrees}{ttrees}' \
				Print::VectorsForTM \
					language=$lang2 \
					selector=src \
					trg_lang=$lang1 \
					compress=1 \
					substitute="{ttrees}{$lang2-$lang1/v}" \
				Print::VectorsForTM \
					language=$lang1 \
					selector=src \
					trg_lang=$lang2 \
					compress=1 \
					substitute="{$lang2-$lang1}{$lang1-$lang2}" \
				&> logs/$batch.log &
		done
		wait
		for batch in $batches; do
			rm -f atrees/batch_$batch.txt
		done
		stderr "$(date) a2t ended"
	fi
}

function train {
	stderr "$(date) train started"
	stderr "$(date) train ended"
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
	rm -f todo.$step
	comm -23 \
		<(sed 's/$/.streex/' corpus/parts.txt) \
		<(find $trees -name '*.streex' -printf '%f\n' | sort) \
		> todo.$step
	if test -s todo.$step; then
		split -d -a 1 -n l/$num_procs todo.$step batches/${step}_
		rm -f todo.$step
	fi
	find batches -name "${step}_*" -printf '%f\n'
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

