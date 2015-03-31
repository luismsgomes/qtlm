#
# March 2015, Luís Gomes <luismsgomes@gmail.com>
#

function serve {
    src=$lang1 trg=$lang2 serve__start
    src=$lang2 trg=$lang1 serve__start
}

function serve__start {
    eval "socket_server_port=\$treex_socket_server_port_$src$trg"
    local doing="starting ${src^^}->${trg^^} treex socket server on $socket_server_port"
    log "$doing"

    $TMT_ROOT/treex/bin/treex --dump_scenario \
        Util::SetGlobal \
            if_missing_bundles=ignore \
            language=$src \
            selector=src \
        "$QTLM_ROOT/scen/$lang1-$lang2/${src}_w2a.scen" \
        "$QTLM_ROOT/scen/$lang1-$lang2/${src}_a2t.scen" \
        Util::SetGlobal \
            language=$trg \
            selector=tst \
        T2T::CopyTtree \
            source_language=$src \
            source_selector=src \
        T2T::TrFAddVariants \
            model_dir=data/models/transfer/$dataset/$train_date/$src-$trg/formeme \
            static_model=static.model.gz \
            discr_model=maxent.model.gz \
        T2T::TrLAddVariants \
            model_dir=data/models/transfer/$dataset/$train_date/$src-$trg/lemma \
            static_model=static.model.gz \
            discr_model=maxent.model.gz \
        "$QTLM_ROOT/scen/$lang1-$lang2/${trg}_t2w.scen" \
        > treex-socket-server.${src}2${trg}.scen

    if
    local socket_server=$TMT_ROOT/treex/bin/treex-socket-server.pl
    if ! test -x $socket_server; then # we may be using an older tectomt revision
        socket_server=$QTLM_ROOT/tool/treex-socket-server.pl
    fi
    $socket_server \
        --detail \
        --port=$socket_server_port \
        --source_zone=$src:src \
        --target_zone=$trg:tst \
        --scenario=treex-socket-server.${src}2${trg}.scen \
        > treex-socket-server.${src}2${trg}.log 2>&1 &
    echo $! > treex-socket-server.${src}2${trg}.pid
    log "treex-socket-server pid is $(cat treex-socket-server.${src}2${trg}.pid)"
    sleep 2

    eval "mtmworker_port=\$treex_mtmworker_port_$src$trg"
    local doing="starting ${src^^}->${trg^^} mtmworker on $mtmworker_port"
    log "$doing"

    local mtmworker=$TMT_ROOT/treex/bin/treex-mtmworker.pl
    if ! test -x $mtmworker; then # we may be using an older tectomt revision
        mtmworker=$QTLM_ROOT/tools/treex-mtmworker.pl
    fi
    $mtmworker \
        -p $mtmworker_port \
        -s $socket_server_port \
        > treex-mtmworker.${src}2${trg}.log 2>&1 &
    echo $! > treex-mtmworker.${src}2${trg}.pid
    log "treex-mtmworker pid is $(cat treex-mtmworker.${src}2${trg}.pid)"
    sleep 1
}

