#
# January 2015, Luís Gomes <luismsgomes@gmail.com>
#

function evaluate {
    local doing="evaluating ${src^^}->${trg^^} translation of testset $testset"
    log "$doing"
    load_testset_config
    create_dir eval_$testset
    local remote_path
    for remote_path in $testset_files; do
        local local_path="eval_$testset/$(basename $remote_path)"
        local base="eval_$testset/$(basename $local_path .$lang1$lang2.gz)"
        download_from_share $remote_path $local_path
        if ! test -f "$base.$lang1.txt" || ! test -f "$base.$lang2.txt"; then
            zcat $local_path |
            $QTLEAP_ROOT/tools/prune_unaligned_sentpairs.py |
            tee >(cut -f 1 > $base.$lang1.txt) |
                  cut -f 2 > $base.$lang2.txt
        fi
        #TODO: download transfer models if needed
        if test -f $base.${src}2$trg.cache/.finaltouch; then
            translate_from_cache $base
        else
            translate_from_scratch $base
        fi
        check_num_lines $base
        create_html_table $base
        run_mteval $base
    done
    log "finished $doing"
}

function translate_from_scratch {
    local base=$1 out_base=$1.${src}2${trg}
    local doing="translating $base from scratch"
    log "$doing"
    if test -d "$out_base.cache"; then
        find "$out_base.cache" -type f -name "*.treex.gz" -delete
    fi
    if test -d "$out_base.final"; then
        find "$out_base.final" -type f -name "*.treex.gz" -delete
    fi
    #MEMCACHED_LOCAL=1
        # --cache=5,15 \
    $TMT_ROOT/treex/bin/treex \
        Util::SetGlobal \
            if_missing_bundles=ignore \
            language=$src \
            selector=src \
        Read::Sentences \
            skip_empty=1 \
            lines_per_doc=1 \
        "$QTLEAP_ROOT/scen/$lang1-$lang2/${src}_w2a.scen" \
        "$QTLEAP_ROOT/scen/$lang1-$lang2/${src}_a2t.scen" \
        Util::SetGlobal \
            language=$trg \
            selector=tst \
        T2T::CopyTtree \
            source_language=$src \
            source_selector=src \
        T2T::TrFAddVariants \
            model_dir="data/models/transfer/$src-$trg/$dataset/$train_date/formeme" \
            static_model="static.model.gz" \
            discr_model="maxent.model.gz" \
        T2T::TrLAddVariants \
            model_dir="data/models/transfer/$src-$trg/$dataset/$train_date/lemma" \
            static_model="static.model.gz" \
            discr_model="maxent.model.gz" \
        Write::Treex \
            storable=0 \
            compress=1 \
            to="." \
            substitute="{noname}{$out_base.cache/}" \
        "$QTLEAP_ROOT/scen/$lang1-$lang2/${trg}_t2a.scen" \
        "$QTLEAP_ROOT/scen/$lang1-$lang2/${trg}_a2w.scen" \
        Write::Treex \
            storable=0 \
            compress=1 \
            to="." \
            substitute="{cache}{final}" \
        Write::Sentences \
        < "$base.$src.txt" 2> "$out_base.treexlog" |
    postprocessing > "$base.${trg}_mt.txt"
    ls $out_base.cache |
    sort --general-numeric-sort --key=1,1 --field-separator=. |
    grep -P "\.treex.gz\$" > $out_base.cache/list.txt
    touch $out_base.{cache,final}/.finaltouch
    log "finished $doing"
}

function translate_from_cache {
    local base=$1 out_base=$1.${src}2${trg}
    local doing="translating $base (using cached trees)"
    log "$doing"
    if test -d "$out_base.final"; then
        find "$out_base.final" -type f -name "*.treex.gz" -delete
    fi
        # --cache=5,15 \
    $TMT_ROOT/treex/bin/treex \
        Read::Treex \
            from=@$out_base.cache/list.txt \
        Util::SetGlobal \
            if_missing_bundles=ignore \
            language=$trg \
            selector=tst \
        "$QTLEAP_ROOT/scen/$lang1-$lang2/${trg}_t2a.scen" \
        "$QTLEAP_ROOT/scen/$lang1-$lang2/${trg}_a2w.scen" \
        Write::Treex \
            storable=0 \
            compress=1 \
            to="." \
            substitute='{cache}{final}' \
        Write::Sentences \
        2> "$out_base.treexlog" |
    postprocessing > "$base.${trg}_mt.txt"
    touch $out_base.cache/.finaltouch
    log "finished $doing"
}

function check_num_lines {
    local base=$1 out_base=$1.${src}2${trg}
    # first let's check if translation went OK and we got as many lines at the
    # output as there are in the input
    local num_lines_in=$(wc -l < "$base.$src.txt")
    local num_lines_out=0
    if test -f "$base.${trg}_mt.txt"; then
        num_lines_out=$(wc -l < "$base.${trg}_mt.txt")
    fi
    if ! test $num_lines_in -eq $num_lines_out; then
        rm -f "$base.${trg}_mt.txt"
        fatal "translation failed; check Treex output at $out_base.treexlog"
    fi
}

function create_html_table {
    local base=$1 out_base=$1.${src}2${trg}
    # now let's create an HTML table showing the source, reference and machine
    #  translated sentences being evaluated
    paste $base.{$src,$trg,${trg}_mt}.txt |
    $QTLEAP_ROOT/tools/tsv_to_html.py > $out_base.$src-$trg-mt_$trg.html
}

function run_mteval {
    local base=$1 out_base=$1.${src}2${trg}
    if test -f $out_base.bleu && \
            test $out_base.bleu -nt $base.${trg}_mt.txt; then
        log "evaluation is up-to-date; skipping mteval"
        return
    fi
    local doing="running mteval-v13a.pl on translation of $base"
    log "$doing"
    local json="{\
        \"srclang\":\"$src\",\
        \"trglang\":\"$trg\",\
        \"setid\":\"$testset\",\
        \"sysid\":\"qtleap:$QTLEAP_CONF\",\
        \"refid\":\"human\"}"
    $QTLEAP_ROOT/tools/txt_to_mteval_xml.py src "$json" "(.*)\.$src\.txt" \
        $base.$src.txt > $out_base.src.xml
    $QTLEAP_ROOT/tools/txt_to_mteval_xml.py ref "$json" "(.*)\.$trg\.txt" \
        $base.$trg.txt > $out_base.ref.xml
    $QTLEAP_ROOT/tools/txt_to_mteval_xml.py tst "$json" "(.*)\.${trg}_mt\.txt" \
        $base.${trg}_mt.txt > $out_base.tst.xml
    $QTLEAP_ROOT/tools/mteval-v13a.pl \
            -s $out_base.src.xml \
            -r $out_base.ref.xml \
            -t $out_base.tst.xml \
        > $out_base.bleu
    rm -f $out_base.{src,ref,tst}.xml
    log "finished $doing"
}

function evaluate_all {
    for testset in $(list_all_testsets); do
        evaluate
    done
}

function load_testset_config {
    local testset_config_file="$QTLEAP_ROOT/conf/testsets/$lang_pair/$testset.sh"
    if ! test -f "$testset_config_file"; then
        fatal "testset configuration file \"$testset_config_file\" does not exist"
    fi
    source "$testset_config_file"
    if ! check_required_variables testset_files; then
        fatal "please fix $testset_config_file"
    fi
    # let's check if testset_files contains a proper list of files
    local num_files=$(wc -w <<< $testset_files)
    local unique_basenames=$(map basename $testset_files | sort -u)
    local num_unique_basenames=$(wc -w <<< $unique_basenames)
    if test $num_files -ne $num_unique_basenames; then
        fatal "check testset configuration \"$testset\": some files have the same basename"
    fi
    local num_matched=$(grep -cP "\.$lang1$lang2\.gz\$" <<< $unique_basenames)
    if test $num_matched -ne $num_unique_basenames; then
        fatal "check testset configuration \"$testset\": some files don't have $lang1$lang2.gz suffix"
    fi
}

function list_all_testsets {
    local dir="$QTLEAP_ROOT/conf/testsets/$lang_pair"
    if test -d "$dir"; then
        ls "$dir" | grep -vP "^_" | sed "s/\\.sh$//"
    else
        fatal "directory \"$dir\" does not exist."
    fi
}

function save {
    doing="saving snapshot $(show_vars QTLEAP_CONF snapshot_description)"
    log "$doing"
    snapshot_id=$(create_new_snapshot_id)
    create_dir "snapshots/$snapshot_id"
    save_code_snapshot "snapshots/$snapshot_id"
    save_eval_snapshot "snapshots/$snapshot_id"
    upload_snapshot "snapshots/$snapshot_id"
    log "finished $doing"
}

function clean {
    doing="removing previous translations $(show_vars QTLEAP_CONF)"
    log "$doing"
    local testset
    for testset in $(list_all_testsets); do
        if test -d eval_$testset; then
            log "cleaning eval_$testset"
            find eval_$testset -type f \( \
                -name '*.treex.gz' \
                -o -name '*.treexlog' \
                -o -name '.finaltouch' \
                -o -name 'list.txt' \
                -o -name '*.bleu' \
                -o -name '*_mt.txt' \
                -o -name '*_mt.html' \) \
                -print -delete
        fi
    done
    log "finished $doing"
}
