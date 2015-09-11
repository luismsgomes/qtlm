#! /bin/bash
#
#  February 2015, Luís Gomes <luismsgomes@gmail.com>
#
#

function adapt {
    load_config
    check_required_variables out_domain_train_dir in_domain_train_dir
    doing="creating domain adapted models $(show_vars QTLM_CONF)"
    log "$doing"
    local train_dir=train_${lang_pair}_${dataset}_${train_date}
    create_dir $train_dir/logs
    train_adapted_transfer_models $train_dir $in_domain_train_dir $out_domain_train_dir
    upload_transfer_models $train_dir
    log "finished $doing"
}

function train_adapted_transfer_models {
    local train_dir=$1
    local in_domain_train_dir=$2
    local out_domain_train_dir=$3
    get_domain_vectors $train_dir $in_domain_train_dir/ttrees true
    get_domain_vectors $train_dir $out_domain_train_dir/ttrees false
    train_transfer_models_direction $train_dir $lang1 $lang2 &
    if ! test $big_machine; then
        wait
    fi
    train_transfer_models_direction $train_dir $lang2 $lang1 &
    wait
}

function get_domain_vectors {
    local train_dir=$1
    local ttrees_dir=$2
    local in_domain=$3
    local doing="creating vectors for training models"
    log "$doing"
    mkdir -p $train_dir/batches
    find -L $train_dir/batches -name "t2v_*" -delete
    rm -f $train_dir/todo.t2v
    find -L $ttrees_dir -name '*.streex' -printf '%f\n' | sort \
        > $train_dir/todo.t2v
    if test -s $train_dir/todo.t2v; then
        split -d -a 3 -n l/$num_procs $train_dir/todo.t2v $train_dir/batches/t2v_
        #rm -f $train_dir/todo.t2v
    fi
    mkdir -p $train_dir/vectors/{$lang1-$lang2,$lang2-$lang1}
    batches=$(find -L $train_dir/batches -name "t2v_*" -printf '%f\n')
    for batch in $batches; do
        test -s $train_dir/batches/$batch || continue
        ln -vf $train_dir/batches/$batch $ttrees_dir/batch_$batch.txt
        $TMT_ROOT/treex/bin/treex \
            Util::SetGlobal \
                selector=src \
            Read::Treex \
                from=@$ttrees_dir/batch_$batch.txt \
            Util::Eval \
                document="\$document->wild->{in_domain}=$($in_domain && echo 1 || echo 0);" \
            Print::VectorsForTM \
                language=$lang2 \
                selector=src \
                trg_lang=$lang1 \
                compress=1 \
                path=$train_dir/vectors/$lang2-$lang1 \
                stem_suffix=$($in_domain && echo _in_domain || echo _out_domain) \
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
        rm -f $ttrees_dir/batch_$batch.txt
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
