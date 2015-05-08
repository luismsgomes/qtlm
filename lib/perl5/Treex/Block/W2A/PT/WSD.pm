package Treex::Block::W2A::PT::WSD;
use Moose;
use Treex::Core::Common;
use Treex::Core::Resource;
use Treex::Tool::ProcessUtils;
use File::Basename;
use File::Temp 'tempdir';
extends 'Treex::Core::Block';

has [qw( _reader _writer _pid _tmpdir )] => ( is => 'rw' );
has lang => ( isa => 'Str', is => 'ro', required => 0, default => "pt" );

sub write {
    my $self = shift;
    my $line = shift // "";
    my $writer = $self->_writer;
    log_debug("lx-wsd-module <<< $line", 1);
    say $writer $line;
}

sub read {
    my $self = shift;
    my $reader = $self->_reader;
    my $line = <$reader>;
    if (!defined $line) {
        my $pid = $self->_pid;
        log_fatal "Failed to read from wsd (pid=$pid).";
    }
    chomp $line;
    log_debug("lx-wsd-module >>> $line", 1);
    return $line;
}

sub BUILD {
    my $self = shift;
    my $lang = $self->lang;
    my $tmpdir = tempdir("lx-wsd-module-workdir-XXXXX", CLEANUP => 1);
    $self->_set_tmpdir($tmpdir);
    my $cmd = $ENV{'QTLM_ROOT'}."/tools/lx-wsd-module-v1.0/lx-wsd-module "
             .$ENV{'QTLM_ROOT'}."/tools/lx-wsd-module-v1.0/UKB ".$tmpdir;
    my ( $reader, $writer, $pid ) =
        Treex::Tool::ProcessUtils::bipipe($cmd, ':encoding(utf-8)');
    log_debug("executing $cmd", 1);
    log_debug("pid=$pid", 1);
    $self->_set_reader( $reader );
    $self->_set_writer( $writer );
    $self->_set_pid( $pid );
}

sub DEMOLISH {
    my $self = shift;
    close( $self->_writer ) if defined $self->_writer;
    close( $self->_reader ) if defined $self->_reader;
    Treex::Tool::ProcessUtils::safewaitpid( $self->_pid ) if defined $self->_pid;
}

sub process_atree {
    my ( $self, $a_root ) = @_;

    my $wsd_input = join ' ',
        map { ($_->form || '')."/".($_->lemma || '')."/".($_->conll_pos || '') }
        $a_root->get_descendants({ ordered => 1 });

    $self->write($wsd_input);
    my $wsd_output = $self->read();
    my @word_senses = map { $_ =~ /.*\/([^\/]+)$/ } (split / /, $wsd_output);

    foreach my $a_node ($a_root->get_descendants({ ordered => 1 })) {
        my $ws = shift @word_senses;
        $a_node->wild->{lx_wsd} = $ws
            if $ws ne '_';
    }
    return;
}


1;

__END__


=head1 NAME

Treex::Block::W2A::PT::WSD;


=head1 SYNOPSIS

This is a wrapper for LX-WSD.  It runs the lx-wsd-module tool (developed by
Steve Neale) and adds lx_wsd wild attribute to a-nodes (nouns, adjectives,
 verbs and adverbs).

The contents of the lx_wsd attribute will be either a number (the synset ID) or
 the string 'UNK' if the word is unknown.

The LX-WSD wraps UKB (see http://ixa2.si.ehu.es/ukb/).


=head1 AUTHORS

Luís Gomes <luis.gomes@di.fc.ul.pt>, <luismsgomes@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright © 2014 by NLX Group, Universidade de Lisboa
