#! /bin/bash
#
# January 2015, Luís Gomes <luismsgomes@gmail.com>
#
#

function main {
	init "$@"
	translate
}

function init {
	set -u # abort if trying to use uninitialized variable
	set -e # abort on error
	progname=$0
	mydir=$(cd $(dirname $0); pwd)
    . $mydir/lib/bash_functions.sh
	test $# == 3 || fatal "usage: $0 CONFIGURATION SRC_LANG TRG_LANG"
	test -f "$1" || fatal "config file '$1' does not exist"
	configfile=$1
	src=${2,,}
	trg=${3,,}
	configname=$(perl -pe 's{(?:.*/)?([^\.]*)(?:\..*)?}{\1}' <<< $configfile)
	source "$configfile"
	lang1=${lang1,,}
	lang2=${lang2,,}
	map check_config_variable workdir treexdir share_url \
		lang1 lang2 corpus num_procs
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
    share_dir=$(perl -e 'use Treex::Core::Config; my ($d) = Treex::Core::Config->resource_path(); print "$d\n";')
    for model in {lemma,formeme}/{static,maxent}; do
        f="data/models/transfer/$src-$trg/$configname/$model.model.gz"
        if ${update_models:-false} && test -f "$share_dir/$f"; then
            rm -f "$share_dir/$f"
        fi
        if ! test -f "$share_dir/$f"; then
            create_dir "$(dirname "$share_dir/$f")"
            create_dir "$workdir/logs"
            stderr "downloading $model model from $share_url/$f"
            wget -a "$workdir/logs/wget.txt" "$share_url/$f" -O "$share_dir/$f"
            stderr "finished"
        fi
    done
    create_dir "$workdir"
	pushd "$workdir" >&2
}

function translate {
    now=$(date '+%Y%m%d_%H%M%S')
    session_dir=${session_dir:-$workdir/translations/$src-$trg/$now}
    if ! test -d "$session_dir"; then
        create_dir "$session_dir"
        if test "$session_dir" == "$workdir/translations/$src-$trg/$now"; then
            pushd "$workdir/translations/$src-$trg" >&2
                ln -sfT "$now" last >&2
            popd >&2
        fi
    fi
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
			model_dir="data/models/transfer/$src-$trg/$configname/formeme" \
			static_model="static.model.gz" \
			discr_model="maxent.model.gz" \
		T2T::TrLAddVariants \
			model_dir="data/models/transfer/$src-$trg/$configname/lemma" \
			static_model="static.model.gz" \
			discr_model="maxent.model.gz" \
		"$mydir/scen/${trg}_t2a.scen" \
		"$mydir/scen/${trg}_a2w.scen" \
		Write::Treex \
			storable=0 \
			to="." \
			substitute="{noname}{$session_dir/}" \
		Write::Sentences \
			selector=trg \
			language=$trg 2> "$session_dir/stderr.txt" |
	postprocessing
}

function postprocessing {
	if test -f $mydir/bin/postprocessing_$trg.py; then
		$mydir/bin/postprocessing_$trg.py
	else
		cat
	fi
}

main "$@"

