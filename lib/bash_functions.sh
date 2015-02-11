
#                     GENERAL AUXILIARY FUNCTIONS

function stderr {
    echo "$progname: $@" >&2
}

function log {
    stderr "[$(date)] $@"
}

function fatal {
    stderr "$@; aborting"
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
            mkdir -vp "$d" >&2
            test -d "$d" || fatal "failed to create '$d'"
        fi
    done
}

function is_set {
    eval "test \"\${$1+x}\" == 'x'"
}

is_set progname || progname="$0"

function check_required_variables {
    ret=0
    for var in $@; do
        if ! is_set $var; then
            stderr "variable \"\$$var\" is not set"
            ret=1
        fi
    done
    return $ret
}

function set_pedantic_bash_options {
    set -u # abort if using unset variable
    set -e # abort if command exits with non-zero status
    trap 'stderr \"$BASH_COMMAND\" exited with code $?' ERR
}

#                     QTLEAP-SPECIFIC AUXILIARY FUNCTIONS

function get_treex_share_dir {
    perl -e 'use Treex::Core::Config; my ($d) = Treex::Core::Config->resource_path(); print "$d\n";'
}

function check_lang1_lang2_variables {
    check_required_variables lang1 lang2
    # lowercase language names
    lang1=${lang1,,}
    lang2=${lang2,,}

    if test "$lang1" > "$lang2"; then
        fatal "\$lang1 and \$lang2 should be lexicographically ordered; please set \$lang1=$lang2 and \$lang2=$lang1 instead."
    fi
    if test "$lang1" == "$lang2"; then
        fatal "\$lang1 and \$lang2 must be different"
    fi
}

function check_src_trg_variables {
    check_required_variables src trg
    # lowercase language names
    src=${src,,}
    trg=${trg,,}

    if test "$src" != "$lang1" -a "$src" != "$lang2"; then
        fatal "invalid \$src ($src); expected either $lang1 or $lang2"
    fi
    if test "$trg" != "$lang1" -a "$trg" != "$lang2"; then
        fatal "invalid \$trg ($trg); expected either $lang1 or $lang2"
    fi
    if test "$src" == "$trg"; then
        fatal "\$src and \$trg must be different"
    fi
}

