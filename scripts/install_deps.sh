#! /bin/bash

if [ -z ${TMT_ROOT} ]; then
    echo "$TMT_ROOT is not set." >&2
    echo "Please set TMT_ROOT to the directory where you want tectomt to be checked out." >&2
    echo "For example: TMT_ROOT=$HOME/code/tectomt" >&2
    exit 1
fi

if ! [ -d "$TMT_ROOT" ]; then
    svn checkout --username public --password public \
        "https://svn.ms.mff.cuni.cz/svn/tectomt_devel/trunk" \
        "$TMT_ROOT"
fi

sudo apt-get install --yes \
    unattended-upgrades \
    cpanminus \
    bash-completion \
    build-essential \
    git \
    subversion \
    gcc-4.8 \
    g++-4.8 \
    python-pip \
    python-dev \
    xorg-dev \
    libxml2-dev \
    zlib1g-dev \
    software-properties-common \
    python-software-properties # needer for add-apt-repository

sudo add-apt-repository --yes ppa:openjdk-r/ppa
sudo apt-get update
sudo apt-get install --yes openjdk-8-jdk

# Tk tests pop up hundreds of windows, which is slow, let's skip the tests.
sudo cpanm -n Tk
# We want to use Treex::Core from svn, so just install its dependencies
sudo cpanm --installdeps Treex::Core
# There are dependencies of other (non-Core) Treex modules
sudo cpanm \
    Ufal::MorphoDiTa \
    Ufal::NameTag Lingua::Interset \
    URI::Find::Schemeless \
    PerlIO::gzip \
    Text::Iconv \
    Cache::Memcached \
    Email::Find XML::Twig \
    String::Util \
    String::Diff \
    List::Pairwise \
    MooseX::Role::AttributeOverride \
    YAML::Tiny \
    Graph Tree::Trie \
    Text::Brew \
    App::Ack \
    RPC::XML \
    UUID::Generator::PurePerl \
    File::HomeDir \
    App/whichpm.pm

sudo cpanm --force \
    AI::MaxEntropy \

sudo pip install scikit-learn numpy scipy

mkdir -p $TMT_ROOT/share/data/models/morce/en
pushd $TMT_ROOT/share/data/models/morce/en/
wget -c http://ufallab.ms.mff.cuni.cz/tectomt/share/data/models/morce/en/{morce.{alph,dct,ft,ftrs},tags_for_form-from_wsj.dat}
popd

pushd $TMT_ROOT/libs/packaged/Morce-English
perl Build.PL && ./Build && ./Build test && sudo ./Build install
popd

pushd $TMT_ROOT/install/tool_installation/NADA
perl Makefile.PL && make && sudo make install
popd
