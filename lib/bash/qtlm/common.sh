
function load_config {
    if ! check_required_variables QTLM_CONF QTLM_ROOT; then
        exit 1
    fi
  
    qtlm_conf_list=(${QTLM_CONF//,/ })
    datasets_dir=""
    datasets=()
    for conf in "${qtlm_conf_list[@]}"
    do
        # explodes items at the slash
        # ex.:  en-pt/ep/2015-01-01/1.0/0.5
        #       conf_item[0] = en-pt
        #       conf_item[1] = ep
        conf_item=(${conf//// })

        lang_pair=${conf_item[0]}
        lang1=${lang_pair%-*}
        lang2=${lang_pair#*-}
        if [[ "$lang1" > "$lang2" ]]; then
            fatal "<lang1> and <lang2> should be lexicographically ordered; please use $lang2-$lang1 instead."
        fi
        if test "$lang1" == "$lang2"; then
            fatal "<lang1> and <lang2> must be different"
        fi

        dataset=${conf_item[1]}
        train_date=${conf_item[2]}

        # for QTLM_CONF back-compability 
        # future QTLM_CONF should come with formeme/lemma static/maxent weights
        if [ ${#conf_item[@]} -ge 4 ];
        then
            datasets_dir+="+${dataset}_${train_date}"
            datasets+=("$dataset/$train_date")
            formeme_maxent_weight+=(${conf_item[3]})
            formeme_static_weight+=(${conf_item[4]})
            lemma_maxent_weight+=(${conf_item[5]})
            lemma_static_weight+=(${conf_item[6]})
        fi

        # Sharing configuration
        source $QTLM_ROOT/conf/sharing.sh
        if ! check_required_variables download_http_{base_url,user,password} \
                upload_ssh_{user,host,port,path}; then
            fatal "please fix $QTLM_ROOT/conf/sharing.sh"
        fi

        local host_config_file=$QTLM_ROOT/conf/hosts/$(hostname).sh
        # Host configuration
        if ! test -f $host_config_file; then
            host_config_file=$QTLM_ROOT/conf/hosts/default.sh
        fi
        source $host_config_file
        if ! check_required_variables num_procs sort_mem big_machine giza_dir; then
            fatal "please fix $host_config_file"
        fi

        # Dataset configuration
        local dataset_config_file=$QTLM_ROOT/conf/datasets/$lang1-$lang2/$dataset.sh
        if ! test -f $dataset_config_file; then
            fatal "$dataset_config_file does not exist"
        fi
        source $dataset_config_file
        if ! check_required_variables dataset_files train_hostname rm_giza_files \
                lemma_static_train_opts lemma_maxent_train_opts \
                formeme_static_train_opts formeme_maxent_train_opts; then
            fatal "please fix $dataset_config_file"
        fi

        treex_share_dir=$(perl -e '
            use Treex::Core::Config;
            my ($d) = Treex::Core::Config->resource_path();
            print "$d\n";
        ')

        # let's check if all scenarios exist
        local scen scendir
        scendir=$QTLM_ROOT/scen/$lang1-$lang2
        for scen in $scendir/{{${lang1},${lang2}}_{w2a,a2t,t2w},{${lang1}${lang2},${lang2}${lang1}}_t2t}.scen; do
            if ! test -f "$scen"; then
                fatal "missing scenario $scen"
            fi
        done
        
    done


}

function check_src_trg {
    # lowercase language names
    src=${src,,}
    trg=${trg,,}
    if test "$src" != "$lang1" && test "$src" != "$lang2"; then
        fatal "invalid <src> ($src); expected either $lang1 or $lang2"
    fi
    if test "$trg" != "$lang1" && test "$trg" != "$lang2"; then
        fatal "invalid <trg> ($trg); expected either $lang1 or $lang2"
    fi
    if test "$src" == "$trg"; then
        fatal "<src> and <trg> must be different"
    fi
}

function check_qtlm_from {
    if is_set QTLM_FROM; then
        case "$QTLM_FROM" in
            w|a|t) # OK
            ;;
            *)
            fatal "invalid value for QTLM_FROM; please specify either w, a, or t."
            ;;
        esac
    fi
}

function save_code_snapshot {
    local dest_dir="$1"
    if ! test "${dest_dir:0:1}" == "/"; then
        dest_dir="$PWD/$dest_dir"
    fi
    local doing="saving '$QTLM_ROOT' snapshot to '$dest_dir'"
    log "$doing"
    pushd $QTLM_ROOT > /dev/null
    hg log -r . > "$dest_dir/qtleap.info"
    hg stat     > "$dest_dir/qtleap.stat"
    hg diff     > "$dest_dir/qtleap.diff"
    popd > /dev/null
    log "finished $doing"
    doing="saving '$TMT_ROOT' snapshot to '$dest_dir'"
    log "$doing"
    pushd $TMT_ROOT > /dev/null
    svn info > "$dest_dir/tectomt.info"
    svn stat > "$dest_dir/tectomt.stat"
    svn diff > "$dest_dir/tectomt.diff"
    popd > /dev/null
    log "finished $doing"
}

function download_from_share {
    local url="$download_http_base_url/$1" local_path="$2"
    local curl=$(which curl)
    if test -z "$curl"; then
        fatal "curl is not installed"
    fi
    if ! test -f "$local_path.downloaded"; then
        local doing="downloading $url to $local_path"
        log "$doing"
        $curl --user "$download_http_user:$download_http_password" \
            --url "$url" --output "$local_path" \
            --retry 3 --continue-at -  --silent --fail --show-error
        touch "$local_path.downloaded"
        log "finished $doing"
    fi
}

function postprocessing {
    if test -f $QTLM_ROOT/tools/postprocessing_$trg.py; then
        stdbuf -i0 -o0 $QTLM_ROOT/tools/postprocessing_$trg.py
    else
        cat
    fi
}

function check_transfer_models {
    local model direction local_path remote_path
    for direction in $lang1-$lang2 $lang2-$lang1; do
        for model in {lemma,formeme}/{static,maxent}.model.gz; do
            remote_path=models/transfer/$dataset/$train_date/models/$direction/$model
            local_path=$treex_share_dir/data/models/transfer/$dataset/$train_date/$direction/$model
            if ! test -f $local_path; then
                create_dir $(dirname $local_path)
                download_from_share $remote_path $local_path
            fi
        done
    done
}

function rotate_new_old {
    local base=$1
    if test $# == 2; then
        local ext=$2
        test -e $base.new.$ext ||
                fatal "No such file or directory: $base.new.$ext"
        if test -e $base.old.$ext; then
            rm -vrf $base.old.$ext
        fi
        if test -e $base.$ext; then
            mv -v $base.$ext $base.old.$ext
        fi
        mv -v $base.new.$ext $base.$ext
    else
        test -e $base.new ||
                fatal "No such file or directory: $base.new"
        if test -e $base.old; then
            rm -vrf $base.old
        fi
        if test -e $base; then
            mv -v $base $base.old
        fi
        mv -v $base.new $base
    fi
}
