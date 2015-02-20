#! /bin/bash
#
#  February 2015, Luís Gomes <luismsgomes@gmail.com>
#
#

function train {
    if [[ "$(hostname)" != $train_hostname ]]; then
        fatal "dataset '$dataset/$lang1-$lang2' must be trained on '$train_hostname'"
    fi
    doing="training $(show_vars QTLEAP_CONF)"
    log "$doing"
    local train_dir=train_${lang_pair}_${dataset}_${train_date}
    create_dir $train_dir/logs
    save_code_snapshot $train_dir
    get_corpus $train_dir
    w2a $train_dir

    false

    align $train_dir
    a2t $train_dir
    train_transfer_models $train_dir
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
    $QTLEAP_ROOT/tools/prune_unaligned_sentpairs.py |
    tee >(cut -f 1 | split $SPLITOPTS - $train_dir/corpus/$lang1/part_) |
          cut -f 2 | split $SPLITOPTS - $train_dir/corpus/$lang2/part_
    find $train_dir/corpus/$lang1 -name 'part_*.txt' -printf '%f\n' |
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
    local doing="analysing parallel data (w2a)"
    log "$doing"
    create_dir $train_dir/{atrees,lemmas,batches,scens}
    find $train_dir/batches -name "w2a_*" -delete
    rm -f $train_dir/todo.w2a
    comm -23 \
        <(sed 's/$/.streex/' $train_dir/corpus/parts.txt) \
        <(find $train_dir/atrees -name '*.streex' -printf '%f\n' | sort) \
        > $train_dir/todo.w2a
    if test -s $train_dir/todo.w2a; then
        split -d -a 3 -n l/$num_procs $train_dir/todo.w2a \
            $train_dir/batches/w2a_
        rm -f $train_dir/todo.w2a
    fi
    local batches=$(find $train_dir/batches -name "w2a_*" -printf '%f\n')

    local changed=false
    if test -n "$batches"; then
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
                "$QTLEAP_ROOT/scen/$lang1-$lang2/${lang1}_w2a.scen" \
                "$QTLEAP_ROOT/scen/$lang1-$lang2/${lang2}_w2a.scen" \
                Write::Treex \
                    storable=1 \
                    path=$train_dir/atrees \
                Write::LemmatizedBitexts \
                    selector=src \
                    language=$lang1 \
                    to='.' \
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
    fi
    if $changed || ! test -f $train_dir/lemmas.gz; then
        log "gzipping lemmas"
        find $train_dir/lemmas -name '*.txt' | sort | xargs cat |
        gzip > $train_dir/lemmas.gz
        log "finished gzipping lemmas"
    fi
    log "finished $doing"
}

function align {
    test -f lemmas.gz || fatal "$work_dir/lemmas.gz does not exist"
    test lemmas.gz -nt alignments.gz || return 0
    stderr "$(date '+%F %T')  started align"
    create_dir align_tmp
    $treexdir/devel/qtleap/bin/gizawrapper.pl \
        --tempdir=align_tmp \
        --bindir=$gizadir \
        lemmas.gz \
        --lcol=1 \
        --rcol=2 \
        --keep \
        --dirsym=gdfa,int,left,right,revgdfa \
        2> logs/align.log |
    paste <(zcat lemmas.gz | cut -f 1 | sed 's|^.*/|atrees/|;s|\.txt|.streex|') - |
    gzip > alignments.gz
    if $rm_giza_files; then
        rm -rf align_tmp
    fi
    stderr "$(date '+%F %T') finished align"
}

function a2t {
    create_dir ttrees $lang1-$lang2/v $lang2-$lang1/v batches
    find batches -name "a2t_*" -delete
    rm -f todo.a2t
    comm -23 \
        <(find atrees -name '*.streex' -printf '%f\n' | sort) \
        <(find ttrees -name '*.streex' -printf '%f\n' | sort) \
        > todo.a2t
    if test -s todo.a2t; then
        split -d -a 3 -n l/$num_procs todo.a2t batches/a2t_
        rm -f todo.a2t
    fi
    batches=$(find batches -name "a2t_*" -printf '%f\n')
    if test -n "$batches"; then
        stderr "$(date '+%F %T')  started a2t"
        for batch in $batches; do
            test -s batches/$batch || continue
            ln -f batches/$batch atrees/batch_$batch.txt
            $treexdir/bin/treex \
                Read::Treex \
                    from=@atrees/batch_$batch.txt \
                Align::A::InsertAlignmentFromFile \
                    from=alignments.gz \
                    inputcols=gdfa_int_left_right_revgdfa_therescore_backscore \
                    selector=src \
                    language=$lang1 \
                    to_selector=src \
                    to_language=$lang2 \
                Align::ReverseAlignment \
                    selector=src \
                    language=$lang1 \
                    layer=a \
                "$QTLEAP_ROOT/scen/$lang1-$lang2/${lang1}_a2t.scen" \
                "$QTLEAP_ROOT/scen/$lang1-$lang2/${lang2}_a2t.scen" \
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
                    substitute='{atrees}{ttrees}' \
                Print::VectorsForTM \
                    language=$lang2 \
                    selector=src \
                    trg_lang=$lang1 \
                    compress=1 \
                    to='.' \
                    substitute="{ttrees}{$lang2-$lang1/v}" \
                Print::VectorsForTM \
                    language=$lang1 \
                    selector=src \
                    trg_lang=$lang2 \
                    compress=1 \
                    to='.' \
                    substitute="{$lang2-$lang1}{$lang1-$lang2}" \
                &> logs/$batch.log &
        done
        wait
        for batch in $batches; do
            rm -f atrees/batch_$batch.txt
        done
        stderr "$(date '+%F %T') finished a2t"
    fi
}

function train_transfer_models {
    train_transfer_models_direction $lang1 $lang2 &
    $running_on_a_big_machine || wait
    train_transfer_models_direction $lang2 $lang1 &
    wait
}

function train_transfer_models_direction {
    src=$1
    trg=$2
    stderr "$(date '+%F %T')  started train $src-$trg"
    create_dir $src-$trg/{lemma,formeme}

    stderr "$(date '+%F %T')  started sorting $src-$trg vectors by $src lemmas"
    find $src-$trg/v -name "part_*.gz" |
    sort |
    xargs zcat |
    cut -f1,2,5 |
    sort -k1,1 --buffer-size $sort_mem --parallel=$num_procs |
    gzip > $src-$trg/lemma/train.gz
    stderr "$(date '+%F %T') finished sorting $src-$trg vectors by $src lemmas"

    stderr "$(date '+%F %T')  started sorting $src-$trg vectors by $src formemes"
    find $src-$trg/v -name "part_*.gz" |
    sort |
    xargs zcat |
    cut -f3,4,5 |
    sort -k1,1 --buffer-size $sort_mem --parallel=$num_procs |
    gzip > $src-$trg/formeme/train.gz
    stderr "$(date '+%F %T') finished sorting $src-$trg vectors by $src formemes"

    for modeltype in static maxent; do
        train_lemma $src $trg $modeltype &
        $running_on_a_big_machine || wait
        train_formeme $src $trg $modeltype &
        $running_on_a_big_machine || wait
    done
    wait
    create_model_symlinks
    stderr "$(date '+%F %T') finished train $src-$trg"
}

function train_lemma {
    src=$1
    trg=$2
    modeltype=$3
    stderr "$(date '+%F %T')  started training $modeltype $src-$trg lemmas transfer model"
    eval "train_opts=\$lemma_${modeltype}_train_opts"
    zcat $src-$trg/lemma/train.gz |
    eval $treexdir/training/mt/transl_models/train.pl \
        $modeltype $train_opts $src-$trg/lemma/$modeltype.model.gz \
        >& logs/train_${src}-${trg}_lemma_$modeltype.log
    stderr "$(date '+%F %T') finished training $modeltype $src-$trg lemmas transfer model"
}

function train_formeme {
    src=$1
    trg=$2
    modeltype=$3
    stderr "$(date '+%F %T')  started training $modeltype $src-$trg formemes transfer model"
    eval "train_opts=\$formeme_${modeltype}_train_opts"
    zcat $src-$trg/formeme/train.gz |
    eval $treexdir/training/mt/transl_models/train.pl \
        $modeltype $train_opts $src-$trg/formeme/$modeltype.model.gz \
        >& logs/train_${src}-${trg}_formeme_$modeltype.log
    stderr "$(date '+%F %T') finished training $modeltype $src-$trg formemes transfer model"
}

function create_model_symlinks {
    for factor in lemma formeme; do
        for langpair in $lang1-$lang2 $lang2-$lang1; do
            file="data/models/transfer/$langpair-$conf-$factor-static.model.gz"
            share_ssh_dir
            d="$HOME//data/models/transfer/$langpair/$conf/$factor"
                scp -P "$share_ssh_port" \
                    "$work_dir/$file" \
                    "$share_ssh_user@$share_ssh_host:$share_ssh_path/data/models/transfer/$langpair/$conf/$factor/static.model.gz"
                ln -fs "$work_dir/$langpair/$factor/maxent.model.gz"
            popd >&2
        done
    done
}
