#
# January 2015, Luís Gomes <luismsgomes@gmail.com>
#

function translate {
    load_config
    check_src_trg
    local now=$(date '+%Y%m%d_%H%M%S')
    local write_treex=""
    if is_set save_trees; then
        write_treex="Write::Treex storable=0 compress=1 file_stem= path='$save_trees'"
        create_dir "$save_trees"
    fi

    check_transfer_models

    $TMT_ROOT/treex/bin/treex \
        Util::SetGlobal \
            if_missing_bundles=ignore \
            language=$src \
            selector=src \
        Read::Sentences \
            skip_empty=1 \
            lines_per_doc=1 \
            _file_number_width=6 \
        W2A::ResegmentSentences \
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
        Misc::JoinBundles \
        $write_treex \
        Write::Sentences |
    postprocessing
}

