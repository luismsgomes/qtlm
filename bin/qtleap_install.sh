#! /bin/bash

qtleap_dir="$HOME/code/qtleap"
qtleap_url="ssh://hg@bitbucket.org/luismsgomes/qtleap"
tectomt_svn_username="luis.gomes"
tectomt_svn_url="https://svn.ms.mff.cuni.cz/svn/tectomt_devel/trunk"

which hg > /dev/null || {
    log "installing mercurial:"
    sudo apt-get install mercurial
}

test -d "$qtleap_dir" || {
    mkdir -p "$(dirname "$qtleap_dir")"
    log "checking out qtleap repository"
    hg clone "$qtleap_url" "$qtleap_dir"
}

source "$qtleap_dir/conf/env.sh"
source "$qtleap_dir/lib/bash_functions.sh"

set_pedantic_bash_options

which svn > /dev/null > /dev/null || {
    log "installing subversion:"
    sudo apt-get install subversion
}

test -d "$TMT_ROOT" || {
    log "checking out tectomt"
    mkdir -p "$(dirname "$TMT_ROOT")"
    svn checkout --username "$tectomt_svn_username" "$tectomt_svn_url" "$TMT_ROOT"
}

which perlbrew > /dev/null || {
    wget -O - http://install.perlbrew.pl | bash
    source "$PERLBREW_ROOT/etc/bashrc"
    perlbrew init
}

test -n "$(perlbrew list)" || {
    log "installing (brewing) latest stable Perl"
    perlbrew install stable --as stable && perlbrew clean
    perlbrew switch stable
    perlbrew install-cpanm
    cpanm --local-lib=$PERLBREW_ROOT local::lib && eval $(perl -I $PERLBREW_ROOT/lib/perl5 -Mlocal::lib)
}

[[ "$(which cpanm)" == "$PERLBREW_ROOT"* ]] || {
    fatal "refusing to use $(which cpanm) because it resides outside $PERLBREW_ROOT"
}

cpanm Perl::PrereqScanner
