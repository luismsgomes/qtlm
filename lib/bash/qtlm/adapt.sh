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
    get_domain_vectors $train_dir $in_domain_train_dir/ttrees true
    get_domain_vectors $train_dir $out_domain_train_dir/ttrees false
    train_transfer_models_direction $train_dir $lang1 $lang2 &
    if ! test $big_machine; then
        wait
    fi
    train_transfer_models_direction $train_dir $lang2 $lang1 &
    wait
    upload_transfer_models $train_dir
    log "finished $doing"
}

function get_domain_vectors {
    local train_dir=$1
    local ttrees_dir=$2
    local in_domain=$3
    local doing="creating vectors for training domain-adapted models"
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
