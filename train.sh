#! /bin/bash

function main {
	init "$@"
	get_corpus
	w2a
	align
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
	configname=$(basename $configfile .conf)
	source "$1"
	map check_config_variable workdir treexdir treexsharedir \
		lang1 lang2 corpus num_procs rm_giza_files running_on_a_big_machine \
		sort_mem static_train_opts maxent_train_opts
	
	for lang in $lang1 $lang2; do
		for step in w2a a2t; do
			scen="$mydir/scen/${lang}_${step}.scen"
			test -f "$scen" ||
				fatal "missing ${step^^} scenario for ${lang^^}: $scen"
		done
	done
	create_dir "$workdir"
	pushd "$workdir"
	create_dir logs
	treex_share=$(perl -e 'use Treex::Core::Config; my ($d) = Treex::Core::Config->resource_path(); print "$d\n";')
}

function get_corpus {
	test -f corpus/parts.txt && return 0
	stderr "$(date '+%F %T')  started get_corpus"
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
	stderr "$(date '+%F %T') finished get_corpus"
}

function w2a {
	create_dir atrees lemmas
	batches=$(todo w2a)
	changed=false
	if test -n "$batches"; then
		stderr "$(date '+%F %T')  started w2a"
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
				"$mydir/scen/${lang1}_w2a.scen" \
				"$mydir/scen/${lang2}_w2a.scen" \
				Write::Treex \
					storable=1 \
					substitute='{^.*/([^\/]*)\.streex}{atrees/$1.streex}' \
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
		stderr "$(date '+%F %T') finished w2a"
	fi
	if $changed || ! test -f lemmas.gz; then
		stderr "$(date '+%F %T')  started gzipping lemmas"
		find lemmas -name '*.txt' | sort | xargs cat | gzip > lemmas.gz
		stderr "$(date '+%F %T') finished gzipping lemmas"
	fi
}

function align {
	test -f lemmas.gz || fatal "$workdir/lemmas.gz does not exist"
	test lemmas.gz -nt alignments.gz || return 0
	stderr "$(date '+%F %T')  started align"
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
	paste <(zcat lemmas.gz | cut -f 1 | sed 's|^.*/|atrees/|;s|\.txt|.streex|') - |
	gzip > alignments.gz
	if $rm_giza_files; then
		rm -rf align_tmp
	fi
	stderr "$(date '+%F %T') finished align"
}

function a2t {
	create_dir ttrees $lang1-$lang2/v $lang2-$lang1/v
	batches=$(todo a2t)
	if test -n "$batches"; then
		stderr "$(date '+%F %T')  started a2t"
		for batch in $batches; do
			test -s batches/$batch || continue
			ln -f batches/$batch atrees/batch_$batch.txt
			$treexdir/bin/treex \
				Read::Treex \
					from=@atrees/batch_$batch.txt \
				Align::A::InsertAlignmentFromFile \
					from=alignments.gz \
					inputcols=gdfa_int_left_right_revgdfa_therescore_backscore \
					selector=src \
					language=$lang1 \
					to_selector=src \
					to_language=$lang2 \
				Align::ReverseAlignment2 \
					selector=src \
					language=$lang1 \
					layer=a \
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
					to='.' \
					substitute="{ttrees}{$lang2-$lang1/v}" \
				Print::VectorsForTM \
					language=$lang1 \
					selector=src \
					trg_lang=$lang2 \
					compress=1 \
					to='.' \
					substitute="{$lang2-$lang1}{$lang1-$lang2}" \
				&> logs/$batch.log &
		done
		wait
		for batch in $batches; do
			rm -f atrees/batch_$batch.txt
		done
		stderr "$(date '+%F %T') finished a2t"
	fi
}

function train {
	train_langpair $lang1 $lang2 &
	$running_on_a_big_machine || wait
	train_langpair $lang2 $lang1 &
	wait
}

function train_langpair {
	src=$1
	trg=$2
	stderr "$(date '+%F %T')  started train $src-$trg"
	create_dir $src-$trg/{lemma,formeme}

	stderr "$(date '+%F %T')  started sorting $src-$trg vectors by $src lemmas"
	find $src-$trg/v -name "part_*.gz" |
	sort |
	xargs zcat |
	cut -f1,2,5 |
	sort -k1,1 --buffer-size $sort_mem --parallel=$num_procs |
	gzip > $src-$trg/lemma/train.gz
	stderr "$(date '+%F %T') finished sorting $src-$trg vectors by $src lemmas"

	stderr "$(date '+%F %T')  started sorting $src-$trg vectors by $src formemes"
	find $src-$trg/v -name "part_*.gz" |
	sort |
	xargs zcat |
	cut -f3,4,5 |
	sort -k1,1 --buffer-size $sort_mem --parallel=$num_procs |
	gzip > $src-$trg/formeme/train.gz
	stderr "$(date '+%F %T') finished sorting $src-$trg vectors by $src formemes"

	for modeltype in static maxent; do
		train_lemma $src $trg $modeltype &
		$running_on_a_big_machine || wait
		train_formeme $src $trg $modeltype &
		$running_on_a_big_machine || wait
	done
	wait
	for factor in lemma formeme; do
		d="$treex_share/data/models/transfer/$src-$trg/$configname/$factor"
		create_dir "$d"
		pushd $treex_share/models/$configname/$src-$trg/$factor
			ln -fs "$d/static.model.gz"
			ln -fs "$d/maxent.model.gz"
		popd
	done
	stderr "$(date '+%F %T') finished train $src-$trg"
}

function train_lemma {
	src=$1
	trg=$2
	modeltype=$3
	stderr "$(date '+%F %T')  started training $modeltype $src-$trg lemmas transfer model"
	eval "train_opts=\$lemma_${modeltype}_train_opts"
	zcat $src-$trg/lemma/train.gz |
	eval $treexdir/training/mt/transl_models/train.pl \
		$modeltype $train_opts $src-$trg/lemma/$modeltype.model.gz \
		>& logs/train_${src}-${trg}_lemma_$modeltype.log
	stderr "$(date '+%F %T') finished training $modeltype $src-$trg lemmas transfer model"
}

function train_formeme {
	src=$1
	trg=$2
	modeltype=$3
	stderr "$(date '+%F %T')  started training $modeltype $src-$trg formemes transfer model"
	eval "train_opts=\$formeme_${modeltype}_train_opts"
	zcat $src-$trg/formeme/train.gz |
	eval $treexdir/training/mt/transl_models/train.pl \
		$modeltype $train_opts $src-$trg/formeme/$modeltype.model.gz \
		>& logs/train_${src}-${trg}_formeme_$modeltype.log
	stderr "$(date '+%F %T') finished training $modeltype $src-$trg formemes transfer model"
}

# -------------- Aux functions ----------------

function todo {
	create_dir batches
	step=$1
	case $1 in
		w2a) trees=atrees ;;
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
		split -d -a 3 -n l/$num_procs todo.$step batches/${step}_
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

