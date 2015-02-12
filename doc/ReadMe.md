# Easier QTLeap

The purpose of these scripts is to make life easier for developers working on QTLeap.

Comments and suggestions for improvement are very welcome (<luis.gomes@di.fc.ul.pt>).

## Usage Examples

For all the following commands the `$QTLEAP_CONF` variable must be defined in
 the environment. This value in this variable has three components separated
 by a forward slash (`/`):

  1. the language pair (in the form of `$L1-$L2`);
  2. the training dataset name;
  3. a date formated as `YYYY-MM-DD`

Example:  `QTLEAP_CONF=en-pt/ep/2015-02-12`

The two languages must be lexicographically ordered (`en-pt` is OK, `pt-en` is
 not). The same configuration file is used for both translation directions.
According to the `$QTLEAP_CONF` variable defined above, the file
 `$QTLEAP_ROOT/conf/datasets/en-pt/ep.sh` must exist (see
 [Dataset Configuration](#dataset-configuration) section below for
 further details). The date suffix (in this case `2015-02-12`) indicates when
 the transfer models were trained.

### Training

Training transfer models (both translation directions are trained in parallel):

    qtleap_train

### Translation

Translating from English to Portuguese (reads one sentence per line from
 `STDIN` and writes one sentence per line on `STDOUT`):

    qtleap_translate en pt

### Evaluation

Evaluating the current pipeline on a specific evaluation set (in this example
 `qtleap_2a`):

    qtleap_evaluate en pt qtleap_2a

For this command to succeed the file
 `$QTLEAP_ROOT/conf/testsets/en-pt/qtleap_2a.sh` must exist and define a
 variable named `testset_files` as described below in
 [Testset Configuration](#testset-configuration) section.

Evaluating the current pipeline on all configured evaluation sets:

    qtleap_evaluate en pt

This will translate and evaluate all testsets configured in files within
 `$QTLEAP_ROOT/conf/en-pt/testsets`.


### Snapshots

Saving a snapshot of all current evaluations, the current mercurial and svn
 revision numbers as well as a patch of the uncommited changes on both
 repositories:

    qtleap_snapshot save "brief description of what changed since last snapshot"

This command will save all current evaluations into a directory, plus a copy of
 the configuration file, a reference (date) to the transfer models and the
 mercurial and svn revision numbers of `$QTLEAP_ROOT` and `$TMT_ROOT` and
 the configured remote lxsuite service.
Furthermore, uncommited changes to the repositories are also saved in the form
 of a unified diff, allowing us to recover the current source code in full
 extent.
*WARNING*: only files already tracked by mercurial and SVN will be included in
 the unified diff of every snapshot, ie, all files appearing with a question
 mark when you issue the commands `hg status` or `svn status` *WILL NOT* be
 included in the diff.

Listing all saved snapshots, from the most recent to the oldest:

    qtleap_snapshot list

Compare current translations and evaluations with last snapshot:

    qtleap_snapshot compare

Compare current translations and evaluations with a specific snapshot (in this
 case 2015-01-20):

    qtleap_snapshot compare 2015-01-20



## Configuration


Configuration files are kept in directory `conf`.

### Environment Configuration

The shell environment is configured by sourcing
 `$QTLEAP_ROOT/conf/env/default.sh` into your from your `~/.bashrc` as follows:

    source $QTLEAP_ROOT/conf/env/default.sh

This file defines and exports the following variables: `PATH`, `PERL5LIB`,
 `TMT_ROOT`, and `TREEX_CONFIG`. If you installed the qtleap and tectomt
 repositories into the recommended place (`~/code/eqtleap` and
 `~/code/tectomt`), then you don't have to change this file. Else, you should
 create a file with your username (`$QTLEAP_ROOT/conf/env/$USER.sh`) and
 source it from your `~/.bashrc` like this:

    source $QTLEAP_ROOT/conf/env/$USER.sh


### Host Configuration
The file `$QTLEAP_ROOT/conf/hosts/$(hostname).sh` will be used if it exists,
else the file `$QTLEAP_ROOT/conf/hosts/default.sh` is used instead.
 Either of these files must define the following variables:

#### \$num_procs
The maximum number of concurrent processes that should be executed. Specify a
number lower than the number of available processors in your machine.
(default: `2`)

#### \$sort_mem
How much memory can we use for sorting? (default: 50%)

#### \$big_machine
Set this to `true` only if your machine has enough memory to run several
concurrent analysis pipelines (for example a machine with 32 cores and 256 GB
RAM).  (default: `false`)

#### \$giza_dir
Where GIZA++ has been installed.
(default: `"$TMT_ROOT/share/installed_tools/giza"`)


### Sharing Configuration

Corpora and transfer models are downloaded/uploaded automatically, without
 user intervention.  All data is stored in a central server, which is
 configured in `$QTLEAP_ROOT/conf/sharing.sh`:

#### \$upload_ssh_*
These variables configure SSH access for automatic uploading of transfer models
after training.
Example:

    upload_ssh_user="lgomes"
    upload_ssh_host="nlx-server.di.fc.ul.pt"
    upload_ssh_port=22
    upload_ssh_path="public_html/qtleap/share"

#### \$download_http_*
These variables configure HTTP access for automatic downloading of datasets,  testsets, and transfer models as needed.
Example:

    download_http_base_url="http://nlx-server.di.fc.ul.pt/~lgomes/qtleap/share"
    download_http_user="qtleap"
    download_http_password="paeltqtleap"

### Dataset Configuration

A dataset is a combination of parallel corpora that is used to train the
 transfer models.  For each `DATASET` we must create a respective file
 `$QTLEAP_ROOT/conf/datasets/L1-L2/DATASET.sh` and it must define the following variables:

#### \$dataset_files
A list of files (may be gzipped), each containing tab-separated pairs of human
translated sentences. The file paths specfied here must be relative to
`$download_base_url` configured in `$QTLEAP_ROOT/conf/sharing.sh`.

Example: `dataset="corpora/europarl/ep.enpt.gz"`

#### \$train_hostname
The hostname of the machine where the transfer models are to be trained. This
must be the exact string returned by the hostname command.  It is used as a
safety guard to prevent training on an under-resourced machine. You may use an
`*` to allow training of this dataset on any machine.

#### \$*_train_opts
These are the options affecting the behaviour of the machine learning
algorithm for training each transfer model.
Four variables must be defined: `$lemma_static_train_opts`,
`$lemma_maxent_train_opts`, `$formeme_static_train_opts`, and
`$formeme_maxent_train_opts`.
 Refer to `$TMT_ROOT/treex/training/mt/transl_models/train.pl` for further
 details.  Example:

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

#### \$rm_giza_files
If `true` then GIZA models are removed after the aligment is produced.


### Testset Configuration

A testset is a combination of parallel corpora that is used to test the
 whole pipeline.  For each `TESTSET` we must create a respective file
 `$QTLEAP_ROOT/conf/datasets/L1-L2/TESTSET.sh` and it must define the following variables:

#### \$testset_files
A list of files (may be gzipped), each containing tab-separated pairs of human
 translated sentences.
The file paths specfied here must be relative to
`$download_base_url` configured in `$QTLEAP_ROOT/conf/sharing.sh`.
Example: `testset="corpora/qtleap/qtleap_1a.gz"`

### Treex Configuration

Treex configuration for each user is kept in
`$QTLEAP_ROOT/conf/treex/$USER/config.yaml`.
If you wonder why we don't simply use `$QTLEAP_ROOT/conf/treex/$USER.yaml`, it
is because Treex expects its configuration file to be named `config.yaml`.

Here's my Treex configuration (`$QTLEAP_ROOT/conf/treex/luis/config.yaml`) for
guidance:

    ---
    resource_path:
      - /home/luis/code/tectomt/share
    share_dir: /home/luis/code/tectomt/share
    share_url: http://ufallab.ms.mff.cuni.cz/tectomt/share
    tmp_dir: /tmp
    pml_schema_dir: /home/luis/code/tectomt/treex/lib/Treex/Core/share/tred_extension/treex/resources
    tred_dir: /home/luis/tred
    tred_extension_dir: /home/luis/code/tectomt/treex/lib/Treex/Core/share/tred_extension




