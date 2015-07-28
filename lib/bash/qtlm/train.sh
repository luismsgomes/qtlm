#! /bin/bash
#
#  February 2015, Luís Gomes <luismsgomes@gmail.com>
#
#

function train {
    load_config
    check_qtlm_from
    if [[ "$(hostname)" != $train_hostname ]]; then
        fatal "dataset '$dataset/$lang1-$lang2' must be trained on '$train_hostname'"
    fi
    doing="training $(show_vars QTLM_CONF)"
    log "$doing"
    local train_dir=train_${lang_pair}_${dataset}_${train_date}
    create_dir $train_dir/logs
    #save_code_snapshot $train_dir # TODO fix this
    get_corpus $train_dir
    w2a $train_dir
    align $train_dir
    a2t $train_dir
    train_transfer_models $train_dir
    upload_transfer_models $train_dir
    log "finished $doing"
}

function get_corpus {
    local train_dir=$1
    if test -f $train_dir/corpus/.finaltouch; then
        log "corpus is ready"
        return 0
    fi
    local doing="preparing corpus"
    log "$doing"
    local file
    check_dataset_files_config
    create_dir $train_dir/{dataset_files,corpus/{$lang1,$lang2}}
    for file in $dataset_files; do
        local local_path="$train_dir/dataset_files/$(basename $file)"
        download_from_share $file $local_path
    done
    SPLITOPTS="-d -a 8 -l 200 --additional-suffix .txt"
    for file in $dataset_files; do
        zcat "$train_dir/dataset_files/$(basename $file)"
    done |
    $QTLM_ROOT/tools/prune_unaligned_sentpairs.py |
    tee >(cut -f 1 | split $SPLITOPTS - $train_dir/corpus/$lang1/part_) |
          cut -f 2 | split $SPLITOPTS - $train_dir/corpus/$lang2/part_
    find -L $train_dir/corpus/$lang1 -name 'part_*.txt' -printf '%f\n' |
    sed 's/\.txt$//' |
    sort > $train_dir/corpus/parts.txt
    touch $train_dir/corpus/.finaltouch
    log "finished $doing"
}

function check_dataset_files_config {
    # let's check if dataset_files contains a proper list of files
    local num_files=$(gawk "{print NF}" <<< $dataset_files)
    local unique_basenames=$(map basename $dataset_files | sort -u)
    local num_unique_basenames=$(gawk "{print NF}" <<< $unique_basenames)
    if test $num_files -ne $num_unique_basenames; then
        fatal "check dataset configuration \"$dataset\": some files have the same basename"
    fi
    local num_matched=$(map echo $unique_basenames | grep -cP "\.$lang1$lang2\.gz\$")
    if test $num_matched -ne $num_unique_basenames; then
        fatal "check dataset configuration \"$dataset\": some files don't have $lang1$lang2.gz suffix"
    fi
}

function w2a {
    local train_dir=$1
    if test $train_dir/atrees/.finaltouch -nt $train_dir/corpus/.finaltouch \
        && ( ! is_set QTLM_FROM || test "$QTLM_FROM" != "w" ); then
        log "a-trees are up-to-date"
        return
    fi
    create_dir $train_dir/{atrees,lemmas,batches,scens}
    find -L $train_dir/batches -name "w2a_*" -delete
    rm -f $train_dir/todo.w2a
    comm -23 \
        <(sed 's/$/.streex/' $train_dir/corpus/parts.txt) \
        <(find -L $train_dir/atrees -name '*.streex' -printf '%f\n' | sort) \
        > $train_dir/todo.w2a
    if test -s $train_dir/todo.w2a; then
        split -d -a 3 -n l/$num_procs $train_dir/todo.w2a \
            $train_dir/batches/w2a_
        rm -f $train_dir/todo.w2a
    fi
    local batches=$(find -L $train_dir/batches -name "w2a_*" -printf '%f\n')

    local changed=false
    if test -n "$batches"; then
        local doing="analysing parallel data (w2a)"
        log "$doing"
        for batch in $batches; do
            test -s $train_dir/batches/$batch || continue
            changed=true
            sed -i 's/\.streex$/\.txt/' $train_dir/batches/$batch
            ln -f $train_dir/batches/$batch $train_dir/corpus/$lang1/batch_$batch.txt
            ln -f $train_dir/batches/$batch $train_dir/corpus/$lang2/batch_$batch.txt
            $TMT_ROOT/treex/bin/treex --dump_scenario \
                Util::SetGlobal \
                    selector=src \
                Read::AlignedSentences \
                    ${lang1}_src=@$train_dir/corpus/$lang1/batch_$batch.txt \
                    ${lang2}_src=@$train_dir/corpus/$lang2/batch_$batch.txt \
                W2A::ResegmentSentences remove=diff \
                "$QTLM_ROOT/scen/$lang1-$lang2/${lang1}_w2a.scen" \
                "$QTLM_ROOT/scen/$lang1-$lang2/${lang2}_w2a.scen" \
                Write::Treex \
                    storable=1 \
                    path=$train_dir/atrees \
                Write::LemmatizedBitexts \
                    selector=src \
                    language=$lang1 \
                    to_selector=src \
                    to_language=$lang2 \
                    path=$train_dir/lemmas \
                > $train_dir/scens/$batch.scen

            $TMT_ROOT/treex/bin/treex $train_dir/scens/$batch.scen \
                &> $train_dir/logs/$batch.log &
        done
        wait
        for batch in $batches; do
            rm -f $train_dir/corpus/{$lang1,$lang2}/batch_$batch.txt
        done
        touch $train_dir/atrees/.finaltouch
        log "finished $doing"
    else
        log "a-trees are up-to-date"
    fi
    if $changed || ! test -f $train_dir/lemmas.gz; then
        log "gzipping lemmas"
        find -L $train_dir/lemmas -name 'part_*' | sort | xargs cat |
        gzip > $train_dir/lemmas.gz
        log "finished gzipping lemmas"
    fi
}

function align {
    local train_dir=$1
    if ! test -f $train_dir/lemmas.gz; then
        fatal "$train_dir/lemmas.gz does not exist"
    fi
    if test $train_dir/alignments.gz -nt $train_dir/lemmas.gz; then
        log "alignments are up-to-date; skipping alignment."
        return 0
    fi
    local doing="aligning parallel data"
    log "$doing"
    create_dir $train_dir/giza
    $QTLM_ROOT/tools/gizawrapper.pl \
        --tempdir=$train_dir/giza \
        --bindir=$QTLM_ROOT/tools/$(uname -m) \
        $train_dir/lemmas.gz \
        --lcol=1 \
        --rcol=2 \
        --keep \
        --dirsym=gdfa,int,left,right,revgdfa \
        2> $train_dir/logs/giza.log |
    paste <(zcat $train_dir/lemmas.gz | cut -f 1 |
            sed 's|^[^,]*,||;s|/corpus/../|/atrees/|;s|\.txt|.streex|') - |
    gzip > $train_dir/alignments.gz
    if $rm_giza_files; then
        rm -rf $train_dir/giza
    fi
    log "finished $doing"
}

function a2t {
    local train_dir=$1
    if test $train_dir/ttrees/.finaltouch -nt $train_dir/atrees/.finaltouch \
        && ( ! is_set QTLM_FROM || test "$QTLM_FROM" == "t" ); then
        log "t-trees are up-to-date"
        return
    fi
    create_dir $train_dir/{ttrees,batches,vectors/{$lang1-$lang2,$lang2-$lang1}}
    find -L $train_dir/batches -name "a2t_*" -delete
    rm -f $train_dir/todo.a2t
    comm -23 \
        <(find -L $train_dir/atrees -name '*.streex' -printf '%f\n' | sort) \
        <(find -L $train_dir/ttrees -name '*.streex' -printf '%f\n' | sort) \
        > $train_dir/todo.a2t
    if test -s $train_dir/todo.a2t; then
        split -d -a 3 -n l/$num_procs $train_dir/todo.a2t $train_dir/batches/a2t_
        rm -f $train_dir/todo.a2t
    fi
    batches=$(find -L $train_dir/batches -name "a2t_*" -printf '%f\n')
    if test -n "$batches"; then
        local doing="analysing parallel data (a2t)"
        log "$doing"
        for batch in $batches; do
            test -s $train_dir/batches/$batch || continue
            ln -vf $train_dir/batches/$batch $train_dir/atrees/batch_$batch.txt
            $TMT_ROOT/treex/bin/treex \
                Util::SetGlobal \
                    selector=src \
                Read::Treex \
                    from=@$train_dir/atrees/batch_$batch.txt \
                Align::A::InsertAlignmentFromFile \
                    from=$train_dir/alignments.gz \
                    inputcols=gdfa_int_left_right_revgdfa_therescore_backscore \
                    selector=src \
                    language=$lang1 \
                    to_selector=src \
                    to_language=$lang2 \
                Align::ReverseAlignment \
                    reverse_align_type=1 \
                    selector=src \
                    language=$lang1 \
                    layer=a \
                "$QTLM_ROOT/scen/$lang1-$lang2/${lang1}_a2t.scen" \
                "$QTLM_ROOT/scen/$lang1-$lang2/${lang2}_a2t.scen" \
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
                    path=$train_dir/ttrees \
                Print::VectorsForTM \
                    language=$lang2 \
                    selector=src \
                    trg_lang=$lang1 \
                    compress=1 \
                    path=$train_dir/vectors/$lang2-$lang1 \
                Print::VectorsForTM \
                    language=$lang1 \
                    selector=src \
                    trg_lang=$lang2 \
                    compress=1 \
                    path=$train_dir/vectors/$lang1-$lang2 \
                &> $train_dir/logs/$batch.log &
        done
        wait
        for batch in $batches; do
            rm -f $train_dir/atrees/batch_$batch.txt
        done
        touch $train_dir/ttrees/.finaltouch
        log "finished $doing"
    else
        log "t-trees are up-to-date"
    fi
}

function train_transfer_models {
    local train_dir=$1
    get_vectors $train_dir
    train_transfer_models_direction $train_dir $lang1 $lang2 &
    if ! test $big_machine; then
        wait
    fi
    train_transfer_models_direction $train_dir $lang2 $lang1 &
    wait
}

function get_vectors {
    local train_dir=$1
    if test $train_dir/vectors/.finaltouch -nt $train_dir/ttrees/.finaltouch \
            && ! is_set QTLM_FROM; then
        return
    fi
    local doing="creating vectors for training models"
    log "$doing"
    mkdir -p $train_dir/batches
    find -L $train_dir/batches -name "t2v_*" -delete
    rm -f $train_dir/todo.t2v
    find -L $train_dir/ttrees -name '*.streex' -printf '%f\n' | sort \
        > $train_dir/todo.t2v
    if test -s $train_dir/todo.t2v; then
        split -d -a 3 -n l/$num_procs $train_dir/todo.t2v $train_dir/batches/t2v_
        #rm -f $train_dir/todo.t2v
    fi
    mkdir -p $train_dir/vectors/{$lang1-$lang2,$lang2-$lang1}
    batches=$(find -L $train_dir/batches -name "t2v_*" -printf '%f\n')
    for batch in $batches; do
        test -s $train_dir/batches/$batch || continue
        ln -vf $train_dir/batches/$batch $train_dir/ttrees/batch_$batch.txt
        $TMT_ROOT/treex/bin/treex \
            Util::SetGlobal \
                selector=src \
            Read::Treex \
                from=@$train_dir/ttrees/batch_$batch.txt \
            Print::VectorsForTM \
                language=$lang2 \
                selector=src \
                trg_lang=$lang1 \
                compress=1 \
                path=$train_dir/vectors/$lang2-$lang1 \
            Print::VectorsForTM \
                language=$lang1 \
                selector=src \
                trg_lang=$lang2 \
                compress=1 \
                path=$train_dir/vectors/$lang1-$lang2 \
            &> $train_dir/logs/$batch.log &
    done
    wait
    for batch in $batches; do
        rm -f $train_dir/ttrees/batch_$batch.txt
    done
    touch $train_dir/vectors/.finaltouch
    log "finished $doing"
}

function train_transfer_models_direction {
    local train_dir=$1
    local src=$2
    local trg=$3
    create_dir $train_dir/models/$src-$trg/{lemma,formeme}
    if test $train_dir/models/$src-$trg/.finaltouch -nt \
            $train_dir/vectors/.finaltouch; then
            log "transfer models for $src-$trg are up-to-date"
        return 0
    fi
    local doing="sorting $src-$trg vectors by $src lemmas"
    log "$doing"
    find -L $train_dir/vectors/$src-$trg -name "part_*.gz" |
    sort |
    xargs zcat |
    cut -f1,2,5 |
    sort -k1,1 --buffer-size $sort_mem --parallel=$num_procs |
    gzip > $train_dir/models/$src-$trg/lemma/train.gz
    log "finished $doing"
    doing="sorting $src-trg vectors for formemes"
    find -L $train_dir/vectors/$src-$trg -name "part_*.gz" |
    sort |
    xargs zcat |
    cut -f3,4,5 |
    sort -k1,1 --buffer-size $sort_mem --parallel=$num_procs |
    gzip > $train_dir/models/$src-$trg/formeme/train.gz
    log "finished $doing"
    for model_type in static maxent; do
        train_lemma $train_dir $src $trg $model_type &
        if ! $big_machine; then
            wait
        fi
        train_formeme $train_dir $src $trg $model_type &
        if ! $big_machine; then
            wait
        fi
    done
    wait
    touch $train_dir/models/$src-$trg/.finaltouch
}

function train_lemma {
    local train_dir=$1
    local src=$2
    local trg=$3
    local model_type=$4
    if test $train_dir/models/$src-$trg/lemma/$model_type.model.gz -nt \
            $train_dir/vectors/.finaltouch; then
            log "$src-$trg lemma $model_type model is up-to-date"
        return 0
    fi
    local doing="training $model_type $src-$trg lemmas transfer model"
    log "$doing"
    eval "local train_opts=\$lemma_${model_type}_train_opts"
    zcat $train_dir/models/$src-$trg/lemma/train.gz |
    eval $QTLM_ROOT/tools/train_transfer_models.pl \
        $model_type $train_opts \
        $train_dir/models/$src-$trg/lemma/$model_type.model.gz \
        >& $train_dir/logs/train_${src}-${trg}_lemma_$model_type.log
    log "finished $doing"
}

function train_formeme {
    local train_dir=$1
    local src=$2
    local trg=$3
    local model_type=$4
    if test $train_dir/models/$src-$trg/formeme/$model_type.model.gz -nt \
            $train_dir/vectors/.finaltouch; then
            log "$src-$trg formeme $model_type model is up-to-date"
        return 0
    fi
    local doing="training $model_type $src-$trg formemes transfer model"
    log "$doing"
    eval "local train_opts=\$formeme_${model_type}_train_opts"
    zcat $train_dir/models/$src-$trg/formeme/train.gz |
    eval $QTLM_ROOT/tools/train_transfer_models.pl \
        $model_type $train_opts \
        $train_dir/models/$src-$trg/formeme/$model_type.model.gz \
        >& $train_dir/logs/train_${src}-${trg}_formeme_$model_type.log
    log "finished $doing"
}

function upload_transfer_models {
    local train_dir=$1
    local remote_dir="$upload_ssh_path/models/transfer/$dataset/$train_date"
    local doing="uploading $train_dir to $upload_ssh_host/$remote_dir"
    log "$doing"
    ssh -p $upload_ssh_port $upload_ssh_user@$upload_ssh_host \
        "mkdir -vp '$remote_dir'"
    rsync --port $upload_ssh_port -av "$train_dir/" \
        --exclude "dataset_files" \
        --exclude "corpus" \
        --exclude "giza" \
        --exclude "batches" \
        --exclude "todo.*" \
        "$upload_ssh_user@$upload_ssh_host:$remote_dir"
    log "finished $doing"
}
