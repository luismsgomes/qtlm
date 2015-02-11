# QTLeap Infra-Structure (Sub-)Project

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
 `conf/en-pt/datasets/ep.sh` must exist (see `CONFIGURATION` section below for
 further details). The date suffix (in this case `2015-02-12`) indicates when
 the transfer models were trained.

### Training

Training transfer models (both translation directions are trained in parallel):

    ./train.sh

### Translation

Translating from English to Portuguese (reads one sentence per line from
 `STDIN` and writes one sentence per line on `STDOUT`):

    ./translate.sh en pt

### Evaluation

Evaluating the current pipeline on a specific evaluation set (in this example
 `qtleap_2a`):

    ./evaluate.sh en pt qtleap_2a

For this command to succeed the file `conf/en-pt/testsets/qtleap_2a.sh`
 must exist and define a variable named `testset_qtleap_2a` as follows:

    testset_qtleap_2a="$HOME/corpora/qtleap/batch2_answers.en-pt.gz"

Evaluating the current pipeline on all configured evaluation sets:

    ./evaluate.sh en pt

This will translate and evaluate all testsets configured in files within
 `conf/en-pt/testsets`.


### Snapshots

Saving a snapshot of all current evaluations, the current mercurial and svn
 revision numbers as well as patch of the uncommited changes on both
 repositories:

    ./snapshot.sh save "brief description of what changed since last snapshot"

This command will save all current evaluations into a directory, plus a copy of
 the configuration file, a reference (date) to the transfer models and the
 mercurial and svn revision numbers of `~/code/qtleap` and `~/code/tectomt`.
Furthermore, uncommited changes to the repositories are also saved in the form
 of a unified diff, allowing us to recover the current source code in full
 extent.
*WARNING*: only files already tracked by mercurial and SVN will be included in
 the unified diff of every snapshot, ie, all files appearing with a question
 mark when you issue the commands `hg status` or `svn status` *WILL NOT* be
 included in the diff.

Listing all saved snapshots, from the most recent to the oldest:

    ./snapshot.sh list

Compare current translations and evaluations with last snapshot:

    ./snapshot.sh compare

Compare current translations and evaluations with a specific snapshot (in this
 case 2015-01-20):

    ./snapshot.sh compare 2015-01-20



## Configuration


Configuration files are kept in directory `conf`.

### Environment

The shell environment is configured by including the `conf/env.sh` file from
 your `~/.bashrc` as follows:

    source $HOME/code/qtleap/conf/env.sh

This file defines and exports the following variables: `PATH`, `PERL5LIB`,
 `TMT_ROOT`, and `TREEX_CONFIG`. If you installed the qtleap and tectomt
 repositories into the recommended place (`~/code/qtleap` and
 `~/code/tectomt`), then you don't have to change this file.

### Host Configuration

The file `conf/hosts/$(hostname).sh` will be used if it exists, else the file
 `conf/hosts/default.sh` is used instead.
 Either of these files must define the following variables:

    gizadir     Where GIZA++ has been installed.
                (default: "$TMT_ROOT/share/installed_tools/giza")

    num_procs   The maximum number of concurrent processes that should be
                executed. Specify a number lower than the number of available
                processors in your machine. (default: 1)

    rm_giza_files (true|false)
                If true then GIZA models are removed after the aligment is
                produced. (default: false)

    sort_mem    How much memory can we use for sorting ? (default: 50%)

    running_on_a_big_machine (true|false)
                Set this to true only if your machine has enough memory to run
                several concurrent analysis pipelines (for example a machine
                with 32 cores and 256 GB RAM).  (default: false)


### Dataset Configuration

The file `conf/datasets/$L1-$L2/$dataset.sh` must define the following
 variables:

    train_hostname
                The hostname of the machine where the transfer models are to
                be trained. This must be the exact string returned by the
                hostname command.  It is used as a safety guard to prevent
                training on a sub-resourced machine.

    conf/$L1-$L2/testsets/$testset.sh
    conf/$L1-$L2/datasets/$dataset.sh


    workdir     the directory where all data is kept
                (for example "$HOME/qtleap_pilot1/ep")



