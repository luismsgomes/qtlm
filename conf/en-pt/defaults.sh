lang1='en'
lang2='pt'

treexdir='/home/luis/code/tectomt/treex'
gizadir='/home/luis/code/tectomt/share/installed_tools/giza'
num_procs=16
rm_giza_files=false
sort_mem=50%

running_on_a_big_machine=true

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