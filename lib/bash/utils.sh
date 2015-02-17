
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

is_set progname || progname=$(basename "$0")

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

function show_vars {
    map show_var "$@" | tr $'\n' " "
}

function show_var {
    eval "echo \"$1='\${$1}'\""
}
