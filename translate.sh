#! /bin/bash

function main {
	init "$@"
	translate
}

function init {
	set -u # abort if trying to use uninitialized variable
	set -e # abort on error
	progname=$0
	mydir=$(cd $(dirname $0); pwd)
	test $# == 3 || fatal "usage: $0 CONFIGURATION SRC_LANG TRG_LANG"
	test -f "$1" || fatal "config file '$1' does not exist"
	configfile=$1
	configname=$(basename $configfile .conf)
	src=${2,,}
	trg=${3,,}
	source "$1"
	lang1=${lang1,,}
	lang2=${lang2,,}
	map check_config_variable workdir treexdir treexsharedir \
		lang1 lang2 corpus num_procs running_on_a_big_machine
	if test "$src" != "$lang1" -a "$src" != "$lang2"; then
		fatal "invalid SRC_LANG ($src); expected either ${^^lang1} or ${lang2^^}"
	fi
	if test "$trg" != "$lang1" -a "$trg" != "$lang2"; then
		fatal "invalid SRC_LANG ($trg); expected either ${^^lang1} or ${lang2^^}"
	fi
	if test "$src" == "$trg"; then
		fatal "SRC_LANG and TRG_LANG must be different"
	fi
	for step in w2a a2t; do
		scen="$mydir/scen/${src}_${step}.scen"
		test -f "$scen" ||
			fatal "missing ${step^^} scenario for ${src^^}: $scen"
	done
	for step in t2a a2w; do
		scen="$mydir/scen/${trg}_${step}.scen"
		test -f "$scen" ||
			fatal "missing ${step^^} scenario for ${trg^^}: $scen"
	done
	test -d "$workdir" || fatal "directory $workdir does not exist"
	pushd "$workdir"
}

function translate {
	create_dir translated
	session="$(date '+%F_%T')_${src}-${trg}"
	treex_out="$workdir/translated/$session"
	$treexdir/bin/treex \
		Util::SetGlobal if_missing_bundles=ignore \
		Read::Sentences \
			skip_empty=1 \
			lines_per_doc=1 \
			language=$src \
			selector=src \
		"$mydir/scen/${src}_w2a.scen" \
		"$mydir/scen/${src}_a2t.scen" \
		Util::SetGlobal \
			language=$trg \
			selector=trg \
		T2T::CopyTtree \
			source_language=$src \
			source_selector=src \
		T2T::TrFAddVariants \
			model_dir="data/models/${configname}/${src}-${trg}/formeme" \
			static_model="static.model.gz" \
			discr_model="maxent.model.gz" \
		T2T::TrLAddVariants \
			model_dir="data/models/${configname}/${src}-${trg}/lemma" \
			static_model="static.model.gz" \
			discr_model="maxent.model.gz" \
		"$mydir/scen/${trg}_t2a.scen" \
		"$mydir/scen/${trg}_a2w.scen" \
		Write::Treex \
			storable=1 \
			to="." \
			substitute="{noname}{$treex_out/}" \
		Write::Sentences \
			selector=trg \
			language=$trg 2> "translated/$session.stderr"
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

