
dataset="$HOME/corpora/europarl/ep.enpt.gz"
workdir="$HOME/qtleap_pilot1/ep"
train_hostname="qtleap-worker"

static_train_opts="\
    --instances 10000 \
    --min_instances 2 \
    --min_per_class 1 \
    --class_coverage 1"
lemma_static_train_opts="$static_train_opts"
formeme_static_train_opts="$static_train_opts"

maxent_train_opts="\
    --instances 10000 \
    --min_instances 10 \
    --min_per_class 2 \
    --class_coverage 1 \
    --feature_column 2 \
    --feature_cut 2 \
    --learner_params 'smooth_sigma 0.99'"
lemma_maxent_train_opts="$maxent_train_opts"
formeme_maxent_train_opts="$maxent_train_opts"
