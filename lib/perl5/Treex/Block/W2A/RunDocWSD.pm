package Treex::Block::W2A::RunDocWSD;
use Moose;
extends 'Treex::Core::Block';

has [qw( language input_filename output_filename )] => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

sub process_document {
    my ( $self, $a_root ) = @_;

    my $cmd = $ENV{'QTLM_ROOT'}."/tools/lx_wsd "
              .$self->language
              ." < "
              .$self->input_filename
              ." > "
              .$self->output_filename;
    `$cmd`;
    return;
}

1;

__END__


=head1 NAME

Treex::Block::W2A::RunDocWSD;


=head1 SYNOPSIS

This just calls LX-WSD for with given input/output files.

The LX-WSD wraps UKB (see http://ixa2.si.ehu.es/ukb/).


=head1 AUTHORS

Luís Gomes <luis.gomes@di.fc.ul.pt>, <luismsgomes@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright © 2014 by NLX Group, Universidade de Lisboa
