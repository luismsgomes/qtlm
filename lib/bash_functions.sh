
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
            mkdir -vp "$d" >&2
            test -d "$d" || fatal "failed to create '$d'"
        fi
    done
}

function check_config_variable {
    eval "test \"\${$1+x}\" == 'x' || fatal 'config variable \"\$$1\" is not set'"
}
