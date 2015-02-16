
#                     QTLEAP-SPECIFIC AUXILIARY FUNCTIONS

function check_config {
    check_required_variables QTLEAP_CONF QTLEAP_ROOT
    lang_pair=${QTLEAP_CONF%/*/*}
    lang1=${lang_pair%-*}
    lang2=${lang_pair#*-}
    if test "$lang1" > "$lang2"; then
        fatal "\$lang1 and \$lang2 should be lexicographically ordered; please use $lang2-$lang1 instead."
    fi
    if test "$lang1" == "$lang2"; then
        fatal "\$lang1 and \$lang2 must be different"
    fi
    dataset_and_train_date=${QTLEAP_CONF#*-*/} # dataset/train_date
    dataset=${dataset_and_train_date%/*}
    train_date=${dataset_and_train_date#*/}

    # Sharing configuration
    source $QTLEAP_ROOT/conf/sharing.sh
    check_required_variables download_http_{base_url,user,password}
    check_required_variables upload_ssh_{user,host,port,path}

    # Host configuration
    if test -f $QTLEAP_ROOT/conf/hosts/$(hostname).sh; then
        source $QTLEAP_ROOT/conf/hosts/$(hostname).sh
    else
        source $QTLEAP_ROOT/conf/hosts/default.sh
    fi
    check_required_variables num_procs sort_mem big_machine giza_dir

    # Dataset configuration
    if ! test -f $QTLEAP_ROOT/conf/datasets/$lang1-$lang2/$dataset.sh; then
        fatal "$QTLEAP_ROOT/conf/datasets/$lang1-$lang2/$dataset.sh does not exist"
    fi
    source $QTLEAP_ROOT/conf/datasets/$lang1-$lang2/$dataset.sh
    check_required_variables dataset_files train_hostname rm_giza_files \
        lemma_static_train_opts lemma_maxent_train_opts \
        formeme_static_train_opts formeme_maxent_train_opts

}

function get_treex_share_dir {
    perl -e 'use Treex::Core::Config; my ($d) = Treex::Core::Config->resource_path(); print "$d\n";'
}

function check_src_trg_variables {
    check_required_variables src trg
    # lowercase language names
    src=${src,,}
    trg=${trg,,}

    if test "$src" != "$lang1" -a "$src" != "$lang2"; then
        fatal "invalid \$src ($src); expected either $lang1 or $lang2"
    fi
    if test "$trg" != "$lang1" -a "$trg" != "$lang2"; then
        fatal "invalid \$trg ($trg); expected either $lang1 or $lang2"
    fi
    if test "$src" == "$trg"; then
        fatal "\$src and \$trg must be different"
    fi
}

function save_code_snapshot {
    work_dir=$PWD
    pushd $QTLEAP_ROOT 2> /dev/null
    hg id   > "$work_dir/qtleap.id"
    hg stat > "$work_dir/qtleap.stat"
    hg diff > "$work_dir/qtleap.diff"
    popd
    pushd $TMT_ROOT 2> /dev/null
    svn id   > "$work_dir/tectomt.id"
    svn stat > "$work_dir/tectomt.stat"
    svn diff > "$work_dir/tectomt.diff"
    popd
}


