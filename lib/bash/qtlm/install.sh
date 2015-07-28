#
# June 2015, Luís Gomes <luismsgomes@gmail.com>
#

function install {
    local now=$(date '+%Y%m%d_%H%M%S')
    local errors=$(tempfile)
    local missing=$(tempfile)

    # because load_config executes treex, installation of CPAN modules must be
    # done before calling load_config
    while true; do
        $TMT_ROOT/treex/bin/treex \
            $(find -L $QTLM_ROOT/scen -name '*.scen') \
            Util::Eval doc='die;' \
            > /dev/null 2> $errors || true
        perl -ne "/^Can't locate (.*\.pm) in \@INC/ && print \"\$1\n\";" \
            < $errors > $missing
        if ! test -s $missing; then
            break
        fi
        echo "Installing $(cat $missing)" >&2
        xargs -r sudo cpanm < $missing || xargs -r sudo cpanm --force < $missing
    done
    rm -f $errors $missing

    # next steps need configuration variables $moses_dir and $giza_dir
    load_config

    install_symal
    install_giza
}

function get_giza {
    if test -d $giza_dir/.git; then
        log "$giza_dir exists; updating..."
        cd $giza_dir
        git pull
    else
        log "cloning giza-pp into $giza_dir"
        git clone "https://github.com/moses-smt/giza-pp.git" $giza_dir
    fi
    log "$giza_dir is up to date"
}

function get_moses {
    if test -d $moses_dir/.git; then
        log "$moses_dir exists; updating..."
        cd $moses_dir
        git pull
    else
        log "cloning moses into $moses_dir"
        git clone "https://github.com/moses-smt/mosesdecoder.git" $moses_dir
    fi
    log "$moses_dir is up to date"
}

function install_symal {
    local exe=$QTLM_ROOT/tools/$(uname -m)/symal
    if test -x $exe; then
        return
    fi
    get_moses
    log "compiling symal"
    cd $moses_dir/symal
    cc -c cmd.c
    g++ -static -o symal symal.cpp cmd.o
    mkdir -p $(dirname $exe)
    cp symal $exe
    log "installed symal"
}

function install_giza {
    local tool_dir=$QTLM_ROOT/tools/$(uname -m)
    local giza_execs="GIZA++ snt2plain.out plain2snt.out snt2cooc.out"
    local missing=false
    for exe in $giza_execs mkcls; do
        if ! test -x $tool_dir/$exe; then
            missing=true
            break
        fi
    done
    if ! $missing; then
        return
    fi
    get_giza
    cd $giza_dir
    log "compiling $giza_execs and mkcls"
    make
    mkdir -p $tool_dir
    for exe in $giza_execs; do
        cp GIZA++-v2/$exe $tool_dir/$exe
    done
    cp mkcls-v2/mkcls $tool_dir/mkcls
    log "installed $giza_execs and mkcls"
}
