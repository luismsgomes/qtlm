lang1="en"
lang2="pt"

treexdir="$HOME/code/tectomt/treex"
gizadir="$HOME/code/tectomt/share/installed_tools/giza"
num_procs=32
rm_giza_files=false
sort_mem=50%

running_on_a_big_machine=true
train_host="qtleap-worker"
share_url="http://194.117.45.198:4062/~luis/qtleap/share"

after_train="create_model_symlinks"

function create_model_symlinks {
    for factor in lemma formeme; do
        for langpair in $lang1-$lang2 $lang2-$lang1; do
            d="$HOME/public_html/qtleap/share/data/models/transfer/$langpair/$configname/$factor"
            mkdir -p "$d"
            pushd "$d"
                ln -fs "$workdir/$langpair/$factor/static.model.gz"
                ln -fs "$workdir/$langpair/$factor/maxent.model.gz"
            popd
        done
    done
}


static_train_opts="--instances 10000 --min_instances 2 --min_per_class 1"
static_train_opts="$static_train_opts --class_coverage 1"

lemma_static_train_opts="$static_train_opts"
formeme_static_train_opts="$static_train_opts"

maxent_train_opts="--instances 10000 --min_instances 10 --min_per_class 2"
maxent_train_opts="$maxent_train_opts --class_coverage 1 --feature_column 2"
maxent_train_opts="$maxent_train_opts --feature_cut 2"
maxent_train_opts="$maxent_train_opts --learner_params 'smooth_sigma 0.99'"

lemma_maxent_train_opts="$maxent_train_opts"
formeme_maxent_train_opts="$maxent_train_opts"
