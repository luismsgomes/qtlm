Easier QTLeap
=============

The purpose of these scripts is to make life easier for developers
working on QTLeap.

Comments and suggestions for improvement are very welcome
(luis.gomes@di.fc.ul.pt).

Usage Examples
--------------

For all the following commands the $QTLEAP_CONF variable must be defined
in the environment. This value in this variable has three components
separated by a forward slash (/):

1.  the language pair (in the form of L1-L2);
2.  the training dataset name;
3.  a date formatted as YYYY-MM-DD

Example: QTLEAP_CONF=en-pt/ep/2015-02-12

The two languages must be lexicographically ordered (en-pt is OK, pt-en
is not). The same configuration file is used for both translation
directions. According to the $QTLEAP_CONF variable defined above, the
file $QTLEAP_ROOT/conf/datasets/en-pt/ep.sh must exist (see Dataset
Configuration section below for further details). The date suffix (in
this case 2015-02-12) indicates when the transfer models were trained.

Training

Training transfer models (both translation directions are trained in
parallel):

    qtleap_train

The training process will create several files and sub-directories
within the current directory, so generally you want to run this command
on a newly created directory. For example, when training models for
English-Portuguese, the following files and directories are created:

    .
    ├── [*] about.txt    # contains versioning information and $QTLEAP_CONF
    ├── [*] qtleap.stat  # output of "hg stat" on $QTLEAP_ROOT repository
    ├── [*] qtleap.diff  # unified diff of the $QTLEAP_ROOT repository
    ├── [*] tectomt.stat # output of "svn stat" on the $TMT_ROOT repository
    ├── [*] tectomt.diff # unified diff of the $TMT_ROOT repository
    ├── dataset_files/   # downloaded from central share server
    ├── corpus/          # plain text split into chunks of 200 sentences
    ├── lemmas.gz        # GIZA input files
    ├── giza/            # GIZA itermediate files
    ├── alignments.gz    # GIZA final alignments
    ├── en2pt/           # models for EN to PT transfer
    │   ├── formemes/
    │   │   ├── [*] maxent.model.gz
    │   │   └── [*] static.model.gz
    │   ├── lemmas/
    │   │   ├── [*] maxent.model.gz
    │   │   └── [*] static.model.gz
    │   └── vectors/     # input for machine learning
    ├── pt2en/           # models for PT to EN transfer
    │   ├── formemes/
    │   │   ├── [*] maxent.model.gz
    │   │   └── [*] static.model.gz
    │   ├── lemmas/
    │   │   ├── [*] maxent.model.gz
    │   │   └── [*] static.model.gz
    │   └── vectors/     # input for machine learning
    ├── atrees/          # analytical-level trees
    └── ttrees/          # tectogrammatical-level trees

Here’s the contents of about.txt:

    QTLEAP_CONF=en-pt/ep/2015-02-12
    QTLEAP_ROOT_REV=139:f0dc245ff992
    TMT_ROOT_REV=14390
    LXSUITE_REV=143:e55fc226cb4d

When training is finished, the files prefixed with [*] in the above tree
are automatically uploaded to the share server into the directory
$upload_ssh_path/$QTLEAP_CONF. See Sharing Configuration section for
details about $upload_ssh_path and related variables.

Translation

Translating from English to Portuguese (reads one sentence per line from
STDIN and writes one sentence per line on STDOUT):

    qtleap_translate en pt

If you want to save the trees of each translated sentence (for debugging
purposes for example), then give a directory name as argument:

    qtleap_translate en pt trees_dir

This will read from STDIN and write to STDOUT as previously, but it will
also create a file named trees_dir/###.treex.gz for each input line (###
is replaced by the number of the line, starting with 001).

Evaluation

Evaluating the current pipeline on a specific evaluation set (in this
example qtleap_2a):

    qtleap_evaluate en pt qtleap_2a

For this command to succeed the file
$QTLEAP_ROOT/conf/testsets/en-pt/qtleap_2a.sh must exist and define a
variable named testset_files as described below in Testset Configuration
section.

A new directory eval_qtleap_2a will be created in the current directory
with the following structure:

    .
    └── eval_qtleap_2a
        ├── about.txt               #
        ├── qtleap_2a.en2pt.bleu    # output of `mteval-v13a.pl`
        ├── qtleap_2a.en2pt.cache.treex.gz # trees before synthesis stage
        ├── qtleap_2a.en2pt.final.treex.gz # final trees
        ├── qtleap_2a.en2pt.html    # original, reference and MT side by side
        ├── qtleap_2a.en2pt.ngrams  #
        ├── qtleap_2a.en2pt.resume  # output of Print::TranslationResume
        ├── qtleap_2a.en.txt        # original English text
        ├── qtleap_2a.en.xml        # idem but in XML format for mteval-v13a.pl
        ├── qtleap_2a.pt_mt.txt     # machine translated (English to Portuguese)
        ├── qtleap_2a.pt_mt.xml     # idem but in XML format for mteval-v13a.pl
        ├── qtleap_2a.pt.txt        # original Portuguese text
        └── qtleap_2a.pt.xml        # idem but in XML format for mteval-v13a.pl

If you then evaluate on the other direction (Portuguese to English):

    qtleap_evaluate pt en qtleap_2a

The following files will be added to the directory:

    .
    └── eval_qtleap_2a
        ...
        ├── qtleap_2a.en_mt.txt     # machine translated (Portuguese to English)
        ├── qtleap_2a.en_mt.xml     # idem but in XML format for mteval-v13a.pl
        ├── qtleap_2a.pt2en.bleu    # output of `mteval-v13a.pl`
        ├── qtleap_2a.pt2en.cache.treex.gz # trees before synthesis stage
        ├── qtleap_2a.pt2en.final.treex.gz # final trees
        ├── qtleap_2a.pt2en.html    # original, reference and MT side by side
        ├── qtleap_2a.pt2en.ngrams  #
        └── qtleap_2a.pt2en.resume  # output of Print::TranslationResume

To evaluate the current pipeline on all evaluation sets listed in
$QTLEAP_ROOT/conf/testsets/en-pt just omit the evalset name:

    qtleap_evaluate en pt

Cleaning cached intermediate trees

If you are developing the synthesis and you want to re-evaluate the
pipeline you just repeat the above commands to re-synthesize the
translations.

The re-runs will be much faster than the first evaluation because
qtleap_evaluate will reuse the previously created *.cache.treex.gz files
(which contain the trees after analysis and transfer), and only the
synthesis step is done.

However, if you have changed the analysis or transfer steps, then you
should remove the cached trees by running:

    qtleap_evaluate clean

This will clean the cached trees for all configured testsets that have
been already evaluated in the current directory.

Snapshots

A snapshot is a bundle of current evaluations together with all
information needed to recover the exact state of the current pipeline.

Creating a snapshot

To create a snapshot first you must ensure that all configured testsets
have been evaluated using the current $QTLEAP_CONF. Then you may run:

    qtleap_snapshot save "brief description of what changed since last snapshot"

This command will create a new directory snapshots/YYYY-MM-DDL (year,
month, day, and a letter) within the current directory and it will copy
all current evaluations into it.

The value of the $QTLEAP_CONF variable is saved into about.txt within
the snapshot directory, as well as the current mercurial and SVN
revision numbers of $QTLEAP_ROOT and $TMT_ROOT respectively, and the
current revision of the remote lxsuite service.

Furthermore, uncommited changes to the $QTLEAP_ROOT and $TMT_ROOT
repositories are also saved in the form of a unified diff (qtleap.diff
and tectomt.diff), allowing us to recover the current source code in
full extent.

WARNING: only files already tracked by mercurial and SVN will be
included in the unified diff of every snapshot, ie, all files appearing
with a question mark when you issue the commands hg status or svn status
WILL NOT be included in the diff.

The snapshot is also uploaded to the configured share server, making it
readily available for comparison and analysis to other users. The URL of
a snapshot is
$download_http_base_url/snapshots/LANGPAIR/DATASET/YYYY-MM-DDL, where
$download_http_base_url is a configuration variable described in Sharing
Configuration, and LANGPAIR and DATASET are the first two components of
$QTLEAP_CONF.

Listing snapshots

Listing all saved snapshots, from the most recent to the oldest:

    qtleap_snapshot list

This will fetch an updated list of snapshots from the share server for
the current $QTLEAP_CONF. The list is presented as follows:

    ------------------------------------------------------------------------
     Snapshot      | en2pt | pt2en | Description
    ---------------|-------|-------|----------------------------------------
     * 2015-02-09a | 12.81 |  6.27 | added some exceptions to the rules
       2015-02-02a |  9.56 |  4.69 | some reordering rules for noun phrases
    ------------------------------------------------------------------------

Columns en2pt and pt2en show the average BLEU scores for the respective
translation directions. Snapshots marked with an asterisk (*) exist both
locally and on the server. Unmarked snapshots exist only on the server.

Comparing snapshots

To compare current translations/evaluations with the ones from last
snapshot:

    qtleap_snapshot compare

To compare current translations/evaluations with a specific snapshot (in
this case 2015-01-20):

    qtleap_snapshot compare 2015-01-20

Note: if the specified snapshot does not exist locally (ie, it does not
appear marked with an asterisk in the list of snapshots), then the
comparison will take longer because the snapshot will be automatically
downloaded from the server.

Configuration
-------------

All configuration files are kept in directory $QTLEAP_ROOT/conf.

Environment Configuration

The shell environment is configured by sourcing
$QTLEAP_ROOT/conf/env/default.sh from your ~/.bashrc as follows:

    source $HOME/code/qtleap/conf/env/default.sh

This file defines and exports the following variables: QTLEAP_ROOT,
TMT_ROOT, TREEX_CONFIG, PATH, and PERL5LIB. If you installed the qtleap
and tectomt repositories into the recommended place (~/code/qtleap and
~/code/tectomt), then you don’t have to change this file. Else, you
should create a file with your username ($QTLEAP_ROOT/conf/env/$USER.sh)
and source it from your ~/.bashrc like this:

    source $QTLEAP_ROOT/conf/env/$USER.sh

Host Configuration

The file $QTLEAP_ROOT/conf/hosts/$(hostname).sh will be used if it
exists, else the file $QTLEAP_ROOT/conf/hosts/default.sh is used
instead. Either of these files must define the following variables:

$num_procs

The maximum number of concurrent processes that should be executed.
Specify a number lower than the number of available processors in your
machine. (default: 2)

$sort_mem

How much memory can we use for sorting? (default: 50%)

$big_machine

Set this to true only if your machine has enough memory to run several
concurrent analysis pipelines (for example a machine with 32 cores and
256 GB RAM). (default: false)

$giza_dir

Where GIZA++ has been installed. (default:
"$TMT_ROOT/share/installed_tools/giza")

Sharing Configuration

Corpora and transfer models are downloaded/uploaded automatically,
without user intervention. All data is stored in a central server, which
is configured in $QTLEAP_ROOT/conf/sharing.sh:

$upload_ssh_*

These variables configure SSH access for automatic uploading of transfer
models after training. Example:

    upload_ssh_user="lgomes"
    upload_ssh_host="nlx-server.di.fc.ul.pt"
    upload_ssh_port=22
    upload_ssh_path="public_html/qtleap/share"

$download_http_*

These variables configure HTTP access for automatic downloading of
datasets, testsets, and transfer models as needed. Example:

    download_http_base_url="http://nlx-server.di.fc.ul.pt/~lgomes/qtleap/share"
    download_http_user="qtleap"
    download_http_password="paeltqtleap"

Dataset Configuration

A dataset is a combination of parallel corpora that is used to train the
transfer models. For each DATASET we must create a respective file
$QTLEAP_ROOT/conf/datasets/L1-L2/DATASET.sh and it must define the
following variables:

$dataset_files

A space-separated list of files (may be gzipped), each containing
tab-separated pairs of human translated sentences. The file paths
specfied here must be relative to $download_base_url configured in
$QTLEAP_ROOT/conf/sharing.sh.

Example: dataset_files="corpora/europarl/ep.enpt.gz"

$train_hostname

The hostname of the machine where the transfer models are to be trained.
This must be the exact string returned by the hostname command. It is
used as a safety guard to prevent training on an under-resourced
machine. You may use an * to allow training of this dataset on any
machine.

$*_train_opts

These are the options affecting the behaviour of the machine learning
algorithm for training each transfer model. Four variables must be
defined: $lemma_static_train_opts, $lemma_maxent_train_opts,
$formeme_static_train_opts, and $formeme_maxent_train_opts. Refer to
$TMT_ROOT/treex/training/mt/transl_models/train.pl for further details.
Example:

    static_train_opts="--instances 10000 \
        --min_instances 2 \
        --min_per_class 1 \
        --class_coverage 1"

    maxent_train_opts="--instances 10000 \
        --min_instances 10 \
        --min_per_class 2 \
        --class_coverage 1 \
        --feature_column 2 \
        --feature_cut 2 \
        --learner_params 'smooth_sigma 0.99'"

    lemma_static_train_opts="$static_train_opts"
    formeme_static_train_opts="$static_train_opts"

    lemma_maxent_train_opts="$maxent_train_opts"
    formeme_maxent_train_opts="$maxent_train_opts"

$rm_giza_files

If true then GIZA models are removed after the aligment is produced.

Testset Configuration

A testset is a combination of parallel corpora that is used to test the
whole pipeline. For each TESTSET we must create a respective file
$QTLEAP_ROOT/conf/datasets/L1-L2/TESTSET.sh and it must define the
following variables:

$testset_files

A space-separated list of files (may be gzipped), each containing
tab-separated pairs of human translated sentences. The file paths
specfied here must be relative to $download_base_url configured in
$QTLEAP_ROOT/conf/sharing.sh.

Example: testset="corpora/qtleap/qtleap_1a.gz"

Treex Configuration

Treex configuration for each user is kept in
$QTLEAP_ROOT/conf/treex/$USER/config.yaml. If you wonder why we don’t
simply use $QTLEAP_ROOT/conf/treex/$USER.yaml, it is because Treex
expects its configuration file to be named exactly config.yaml.

Here’s my Treex configuration ($QTLEAP_ROOT/conf/treex/luis/config.yaml)
for guidance:

    ---
    resource_path:
      - /home/luis/code/tectomt/share
    share_dir: /home/luis/code/tectomt/share
    share_url: http://ufallab.ms.mff.cuni.cz/tectomt/share
    tmp_dir: /tmp
    pml_schema_dir: /home/luis/code/tectomt/treex/lib/Treex/Core/share/tred_extension/treex/resources
    tred_dir: /home/luis/tred
    tred_extension_dir: /home/luis/code/tectomt/treex/lib/Treex/Core/share/tred_extension
