#! /bin/bash

sudo apt-get install --yes \
	unattended-upgrades \
	bash-completion \
	build-essential \
	git \
	subversion \
	gcc-4.8 \
	g++-4.8 \
	python-pip \
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
	AI::MaxEntropy \
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
	UUID::Generator::PurePerl

sudo pip install scikit-learn numpy scipy
