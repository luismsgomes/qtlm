
dataset_files="
    corpora/europarl/ep_10k.enpt.gz
    corpora/msterm/msterm.enpt.gz
    corpora/libreoffice/terminology.enpt.gz
    corpora/qtleap/v1.1/qtleap_1a.enpt.gz
    corpora/qtleap/v1.1/qtleap_1q.enpt.gz
"

train_hostname="*"

static_train_opts="\
    --instances 10000 \
    --min_instances 1 \
    --min_per_class 1 \
    --class_coverage 1"
lemma_static_train_opts="$static_train_opts"
formeme_static_train_opts="$static_train_opts"

maxent_train_opts="\
    --instances 10000 \
    --min_instances 5 \
    --min_per_class 2 \
    --class_coverage 1 \
    --feature_column 2 \
    --feature_cut 2 \
    --learner_params 'smooth_sigma 0.99'"
lemma_maxent_train_opts="$maxent_train_opts"
formeme_maxent_train_opts="$maxent_train_opts"

rm_giza_files=false
