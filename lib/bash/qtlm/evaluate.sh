#
# January 2015, Luís Gomes <luismsgomes@gmail.com>
#

function evaluate {
    load_config
    check_src_trg
    check_qtlm_from
    local doing="evaluating ${src^^}->${trg^^} translation of testset $testset"
    log "$doing"
    load_testset_config
    if [ -z $datasets_dir ];
    then
        eval_dir=eval_${lang_pair}_${dataset}_${train_date}_${testset}
    else
        # interpolation
        eval_dir=eval_${lang_pair}_${datasets_dir}_${testset}
    fi
    create_dir $eval_dir
    local remote_path
    for remote_path in $testset_files; do
        local test_file=$(basename $remote_path .$lang1$lang2.gz)
        local local_path=$eval_dir/$(basename $remote_path)
        download_from_share $remote_path $local_path
        if ! test -f $eval_dir/$test_file.$lang1.txt ||
                ! test -f $eval_dir/$test_file.$lang2.txt; then
            zcat $local_path |
            $QTLM_ROOT/tools/prune_unaligned_sentpairs.py |
            tee >(cut -f 1 > $eval_dir/$test_file.$lang1.txt) |
                  cut -f 2 > $eval_dir/$test_file.$lang2.txt
        fi
        check_transfer_models
        if test -f $eval_dir/$test_file.${src}2$trg.cache/.finaltouch \
            && (! is_set QTLM_FROM || test $QTLM_FROM == "t"); then
            translate_from_cached_ttrees $testset $test_file
        elif test -f $eval_dir/$test_file.${src}.final/.finaltouch \
            && (! is_set QTLM_FROM || test $QTLM_FROM != "w"); then
            translate_from_cached_atrees $testset $test_file
        else
            translate_from_scratch $testset $test_file
        fi
        check_num_lines $testset $test_file
        create_html_table $testset $test_file
        create_ngram_summary $testset $test_file
        run_mteval $testset $test_file
    done
    log "finished $doing"
}

function translate_from_scratch {
    local testset=$1 test_file=$2
    local doing="translating $eval_dir/$test_file from scratch"
    log "$doing"
    if test -d "$eval_dir/$test_file.${src}2${trg}.cache"; then
        find -L "$eval_dir/$test_file.${src}2${trg}.cache" -type f -name "*.treex.gz" -delete
    else
        create_dir "$eval_dir/$test_file.${src}2${trg}.cache"
    fi
    if test -d "$eval_dir/$test_file.${src}2${trg}.final.new"; then
        find -L "$eval_dir/$test_file.${src}2${trg}.final.new" -type f -name "*.treex.gz" -delete
    else
        create_dir "$eval_dir/$test_file.${src}2${trg}.final.new"
    fi
    $TMT_ROOT/treex/bin/treex --dump_scenario \
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
        Write::Treex \
            storable=0 \
            compress=1 \
            file_stem="" \
            path=$eval_dir/$test_file.$src.final.new \
        Util::SetGlobal \
            language=$trg \
            selector=tst \
        T2T::CopyTtree \
            source_language=$src \
            source_selector=src \
        "$QTLM_ROOT/scen/$lang1-$lang2/${src}${trg}_t2t.scen" \
        > $eval_dir/$test_file.${src}2${trg}.from_scratch.new.scen

    if [ -z $datasets_dir ];
    then
        $TMT_ROOT/treex/bin/treex --dump_scenario \
            T2T::TrFAddVariants \
                model_dir=data/models/transfer/$dataset/$train_date/$src-$trg/formeme \
                static_model=static.model.gz \
                discr_model=maxent.model.gz \
            T2T::TrLAddVariants \
                model_dir=data/models/transfer/$dataset/$train_date/$src-$trg/lemma \
                static_model=static.model.gz \
                discr_model=maxent.model.gz \
        >> $eval_dir/$test_file.${src}2${trg}.from_scratch.new.scen
    else
        # interpolation
        n=0
        TFORMEME_TMS=""
        TLEMMA_TMS=""
        for dt in "${datasets[@]}"
        do
            TFORMEME_TMS="${TFORMEME_TMS}static ${formeme_maxent_weight[$n]} data/models/transfer/$dt/$src-$trg/formeme/static.model.gz maxent ${formeme_static_weight[$n]} data/models/transfer/$dt/$src-$trg/formeme/maxent.model.gz "
            TLEMMA_TMS="${TLEMMA_TMS}static ${lemma_maxent_weight[$n]} data/models/transfer/$dt/$src-$trg/lemma/static.model.gz maxent ${lemma_static_weight[$n]} data/models/transfer/$dt/$src-$trg/lemma/maxent.model.gz "
        done

        $TMT_ROOT/treex/bin/treex --dump_scenario \
            T2T::TrFAddVariantsInterpol \
                model_dir= \
                models="$TFORMEME_TMS" \
            T2T::TrLAddVariantsInterpol \
                model_dir= \
                models="$TLEMMA_TMS" \
        >> $eval_dir/$test_file.${src}2${trg}.from_scratch.new.scen

    fi
    $TMT_ROOT/treex/bin/treex --dump_scenario \
        Write::Treex \
            storable=0 \
            compress=1 \
            path=$eval_dir/$test_file.${src}2${trg}.cache \
        "$QTLM_ROOT/scen/$lang1-$lang2/${trg}_t2w.scen" \
        Misc::JoinBundles \
        Write::Treex \
            storable=0 \
            compress=1 \
            path=$eval_dir/$test_file.${src}2${trg}.final.new \
        Write::Sentences \
	   >> $eval_dir/$test_file.${src}2${trg}.from_scratch.new.scen

    $TMT_ROOT/treex/bin/treex $eval_dir/$test_file.${src}2${trg}.from_scratch.new.scen \
        < "$eval_dir/$test_file.$src.txt" 2> "$eval_dir/$test_file.${src}2${trg}.treexlog.new" |
    postprocessing > "$eval_dir/$test_file.${trg}_mt.new.txt"
    ls $eval_dir/$test_file.${src}2${trg}.cache |
    sort --general-numeric-sort --key=1,1 --field-separator=. |
    grep -P "\.treex.gz\$" |
    tee   $eval_dir/$test_file.$src.final.new/list.txt \
        > $eval_dir/$test_file.${src}2${trg}.cache/list.txt
    touch $eval_dir/$test_file.${src}2${trg}.{cache,final.new}/.finaltouch
    touch $eval_dir/$test_file.$src.final.new/.finaltouch

    rotate_new_old $eval_dir/$test_file.${src}2${trg}.from_scratch scen
    rotate_new_old $eval_dir/$test_file.${trg}_mt txt
    rotate_new_old $eval_dir/$test_file.${src}2${trg}.treexlog
    rotate_new_old $eval_dir/$test_file.${src}2${trg}.final
    rotate_new_old $eval_dir/$test_file.$src.final

    log "finished $doing"
}

function translate_from_cached_atrees {
    local testset=$1 test_file=$2
    local doing="translating $eval_dir/$test_file (using cached a-trees)"
    log "$doing"
    if test -d "$eval_dir/$test_file.${src}2${trg}.final.new"; then
        find -L "$eval_dir/$test_file.${src}2${trg}.final.new" -type f -name "*.treex.gz" -delete
    else
        create_dir "$eval_dir/$test_file.${src}2${trg}.final.new"
    fi
    $TMT_ROOT/treex/bin/treex --dump_scenario \
        Read::Treex \
            from=@$eval_dir/$test_file.${src}.final/list.txt \
        Util::SetGlobal \
            if_missing_bundles=ignore \
            language=$trg \
            selector=tst \
        T2T::CopyTtree \
            source_language=$src \
            source_selector=src \
        "$QTLM_ROOT/scen/$lang1-$lang2/${src}${trg}_t2t.scen" \
        T2T::TrFAddVariants \
            model_dir=data/models/transfer/$dataset/$train_date/$src-$trg/formeme \
            static_model=static.model.gz \
            discr_model=maxent.model.gz \
        T2T::TrLAddVariants \
            model_dir=data/models/transfer/$dataset/$train_date/$src-$trg/lemma \
            static_model=static.model.gz \
            discr_model=maxent.model.gz \
        Write::Treex \
            storable=0 \
            compress=1 \
            path=$eval_dir/$test_file.${src}2${trg}.cache \
        "$QTLM_ROOT/scen/$lang1-$lang2/${trg}_t2w.scen" \
        Misc::JoinBundles \
        Write::Treex \
            storable=0 \
            compress=1 \
            path="$eval_dir/$test_file.${src}2${trg}.final.new" \
        Write::Sentences > $eval_dir/$test_file.${src}2${trg}.from_cached_atrees.new.scen

    $TMT_ROOT/treex/bin/treex $eval_dir/$test_file.${src}2${trg}.from_cached_atrees.new.scen \
        2> "$eval_dir/$test_file.${src}2${trg}.treexlog.new" |
    postprocessing > "$eval_dir/$test_file.${trg}_mt.new.txt"
    touch $eval_dir/$test_file.${src}2${trg}.{cache,final.new}/.finaltouch

    rotate_new_old $eval_dir/$test_file.${src}2${trg}.from_cached_atrees scen
    rotate_new_old $eval_dir/$test_file.${trg}_mt txt
    rotate_new_old $eval_dir/$test_file.${src}2${trg}.treexlog
    rotate_new_old $eval_dir/$test_file.${src}2${trg}.final

    log "finished $doing"
}

function translate_from_cached_ttrees {
    local testset=$1 test_file=$2
    local doing="translating $eval_dir/$test_file (using cached t-trees)"
    log "$doing"
    if test -d "$eval_dir/$test_file.${src}2${trg}.final.new"; then
        find -L "$eval_dir/$test_file.${src}2${trg}.final.new" -type f -name "*.treex.gz" -delete
    else
        create_dir "$eval_dir/$test_file.${src}2${trg}.final.new"
    fi
    $TMT_ROOT/treex/bin/treex --dump_scenario \
        Read::Treex \
            from=@$eval_dir/$test_file.${src}2${trg}.cache/list.txt \
        Util::SetGlobal \
            if_missing_bundles=ignore \
            language=$trg \
            selector=tst \
        "$QTLM_ROOT/scen/$lang1-$lang2/${trg}_t2w.scen" \
        Misc::JoinBundles \
        Write::Treex \
            storable=0 \
            compress=1 \
            path="$eval_dir/$test_file.${src}2${trg}.final.new" \
        Write::Sentences > $eval_dir/$test_file.${src}2${trg}.from_cached_ttrees.new.scen

    $TMT_ROOT/treex/bin/treex $eval_dir/$test_file.${src}2${trg}.from_cached_ttrees.new.scen \
        2> "$eval_dir/$test_file.${src}2${trg}.treexlog.new" |
    postprocessing > "$eval_dir/$test_file.${trg}_mt.new.txt"
    touch $eval_dir/$test_file.${src}2${trg}.final.new/.finaltouch

    rotate_new_old $eval_dir/$test_file.${src}2${trg}.from_cached_ttrees scen
    rotate_new_old $eval_dir/$test_file.${trg}_mt txt
    rotate_new_old $eval_dir/$test_file.${src}2${trg}.treexlog
    rotate_new_old $eval_dir/$test_file.${src}2${trg}.final

    log "finished $doing"
}

function check_num_lines {
    local testset=$1 test_file=$2
    # first let's check if translation went OK and we got as many lines at the
    # output as there are in the input
    local num_lines_in=$(wc -l < "$eval_dir/$test_file.$src.txt")
    local num_lines_out=0
    if test -f "$eval_dir/$test_file.${trg}_mt.txt"; then
        num_lines_out=$(wc -l < "$eval_dir/$test_file.${trg}_mt.txt")
    fi
    if ! test $num_lines_in -eq $num_lines_out; then
        rm -f "$eval_dir/$test_file.${trg}_mt.txt"
        fatal "translation failed; check Treex output at $eval_dir/$test_file.${src}2${trg}.treexlog"
    fi
}

function create_html_table {
    local testset=$1 test_file=$2
    # now let's create an HTML table showing the source, reference and machine
    #  translated sentences being evaluated
    paste $eval_dir/$test_file.{$src,$trg,${trg}_mt}.txt |
    $QTLM_ROOT/tools/tsv_to_html.py \
        "${testset} testset (${src^^}-${trg^^}) side by side with ${trg^^}/MT output ($dataset/$train_date)" \
        "$test_file.${src}2${trg}.final/{id1:03}.treex.gz" \
        > $eval_dir/$test_file.${src}2${trg}.$src-$trg-mt_$trg.new.html
    rotate_new_old $eval_dir/$test_file.${src}2${trg}.$src-$trg-mt_$trg html
}

function create_ngram_summary {
    local testset=$1 test_file=$2
    $QTLM_ROOT/tools/comparegrams.py $eval_dir/$test_file.{$trg,${trg}_mt}.txt \
        > $eval_dir/$test_file.${src}2${trg}.new.ngrams
    rotate_new_old $eval_dir/$test_file.${src}2${trg} ngrams
}

function run_mteval {
    local testset=$1 test_file=$2
    if test -f $eval_dir/$test_file.${src}2${trg}.bleu && \
            test $eval_dir/$test_file.${src}2${trg}.bleu -nt $eval_dir/$test_file.${trg}_mt.txt; then
        log "evaluation is up-to-date; skipping mteval"
        return
    fi
    local doing="running mteval-v13a.pl on translation of $eval_dir/$test_file"
    log "$doing"
    local json="{\
        \"srclang\":\"$src\",\
        \"trglang\":\"$trg\",\
        \"setid\":\"$testset\",\
        \"sysid\":\"qtleap:$QTLM_CONF\",\
        \"refid\":\"human\"}"
    $QTLM_ROOT/tools/txt_to_mteval_xml.py src "$json" "(.*)\.$src\.txt" \
        $eval_dir/$test_file.$src.txt > $eval_dir/$test_file.${src}2${trg}.src.xml
    $QTLM_ROOT/tools/txt_to_mteval_xml.py ref "$json" "(.*)\.$trg\.txt" \
        $eval_dir/$test_file.$trg.txt > $eval_dir/$test_file.${src}2${trg}.ref.xml
    $QTLM_ROOT/tools/txt_to_mteval_xml.py tst "$json" "(.*)\.${trg}_mt\.txt" \
        $eval_dir/$test_file.${trg}_mt.txt > $eval_dir/$test_file.${src}2${trg}.tst.xml
    $QTLM_ROOT/tools/mteval-v13a.pl \
            -s $eval_dir/$test_file.${src}2${trg}.src.xml \
            -r $eval_dir/$test_file.${src}2${trg}.ref.xml \
            -t $eval_dir/$test_file.${src}2${trg}.tst.xml \
        > $eval_dir/$test_file.${src}2${trg}.bleu.new
    rm -f $eval_dir/$test_file.${src}2${trg}.{src,ref,tst}.xml
    rotate_new_old $eval_dir/$test_file.${src}2${trg}.bleu
    log "finished $doing"
}

function load_testset_config {
    local testset_config_file="$QTLM_ROOT/conf/testsets/$lang_pair/$testset.sh"
    if ! test -f "$testset_config_file"; then
        fatal "testset configuration file \"$testset_config_file\" does not exist"
    fi
    source "$testset_config_file"
    if ! check_required_variables testset_files; then
        fatal "please fix $testset_config_file"
    fi
    # let's check if testset_files contains a proper list of files
    #local num_files=$(wc -w <<< $testset_files)
    #local unique_basenames=$(map basename $testset_files | sort -u)
    #local num_unique_basenames=$(wc -w <<< $unique_basenames)
    #if test $num_files -ne $num_unique_basenames; then
    #    fatal "check testset configuration \"$testset\": some files have the same basename"
    #fi
    #local num_matched=$(grep -cP "\.$lang1$lang2\.gz\$" <<< $unique_basenames)
    #if test $num_matched -ne $num_unique_basenames; then
    #    fatal "check testset configuration \"$testset\": some files don't have $lang1$lang2.gz suffix"
    #fi
}

function list_all_testsets {
    local dir="$QTLM_ROOT/conf/testsets/$lang_pair"
    if test -d "$dir"; then
        ls "$dir" | sed "s/\\.sh$//"
    else
        fatal "directory \"$dir\" does not exist."
    fi
}

function list_scores {
    local file_regex='^\.\/[^\/]*\/([^:]*)\.bleu:'
    local nist_regex='NIST score = ([0-9]*.[0-9]*)'
    local bleu_regex='BLEU score = ([0-9]*.[0-9]*)'
    local system_regex='for system "(.*)"$'
    find -L . -maxdepth 2 -name '*.bleu' |
    xargs --no-run-if-empty grep --with-filename 'BLEU score' |
    perl -pe "s/$file_regex\s*$nist_regex\s*$bleu_regex\s*$system_regex/\1\t\2\t\3\t\4/g" |
    sort -n -r -k 2 | # sort by NIST
    sort -n -r -k 3 -s | # sort by BLEU with option -s (same BLEU => keep NIST ordering)
    cat <(echo -e "TESTSET\tNIST\tBLEU\tSYSTEM") - |
    column -t
}

function create_new_snapshot_id {
    local params="action=create&user=$USER&host=$(hostname)"
    params="$params&eval_date=$eval_date&testset=$testset"
    params="$params&lang1=$lang1&lang2=$lang2"
    params="$params&dataset=$dataset&train_date=$train_date"

    local curl=$(which curl)
    if test -z "$curl"; then
        fatal "curl is not installed"
    fi
    echo $curl --user "$download_http_user:$download_http_password" \
                      --url "$download_http_base_url/snapshot.php?$params" \
                      --silent --fail --show-error >&2
    local out=$($curl --user "$download_http_user:$download_http_password" \
                      --url "$download_http_base_url/snapshot.php?$params" \
                      --silent --fail --show-error)
    if [[ "$out" == snapshot_id=* ]]; then
        echo ${out#snapshot_id=}
    else
        fatal "could not get new snapshot ID from the server"
    fi
}

function save {
    doing="saving snapshot of current $testset evaluation"
    log "$doing"
    snapshot_id=$(create_new_snapshot_id)
    create_dir "snapshots/$snapshot_id"
    exit
    save_code_snapshot "snapshots/$snapshot_id"
    save_eval_snapshot "snapshots/$snapshot_id"
    upload_snapshot "snapshots/$snapshot_id"
    log "finished $doing"
}

function clean {
    doing="cleaning testset $testset"
    log "$doing"
    load_testset_config
    for remote_path in $testset_files; do
        local test_file=$(basename $remote_path .$lang1$lang2.gz)
        if test -d $eval_dir/$test_file.${src}2${trg}.cache; then
            rm -rvf $eval_dir/$test_file.${src}2${trg}.cache
        fi
        if test -d $eval_dir/$test_file.${src}2${trg}.final; then
            rm -rvf $eval_dir/$test_file.${src}2${trg}.final
        fi
        if test -d $eval_dir/$test_file.${src}.final; then
            rm -rvf $eval_dir/$test_file.${src}.final
        fi
    done
    log "finished $doing"
}
