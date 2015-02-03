package Treex::Block::T2T::FixQuoteFormeme;
use Moose;
use Treex::Core::Common;
extends 'Treex::Core::Block';

sub process_tnode {
    my ( $self ) = @_;
    if (( $self->t_lemma || "" ) =~ /^[«»`''"]$/ ) {
        $self->set_formeme('x');
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

Treex::Block::T2T::FixQuoteFormeme

=head1 DESCRIPTION

    Force formeme x for quotes:
        Adj -> NAttr1 -> N2



=head1 AUTHORS

Luís Gomes <luis.gomes@di.fc.ul.pt>, <luismsgomes@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright © 2014 by NLX Group, Universidade de Lisboa
