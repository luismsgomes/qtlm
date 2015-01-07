package Treex::Block::W2A::PT::FillMissingLemmas;

use strict;
use warnings;
use Moose;
use Treex::Core::Common;
extends 'Treex::Core::Block';

sub process_atree {
    my ( $self, $a_root ) = @_;

    foreach my $a_node ( $a_root->get_descendants ) {
        my $lemma = $a_node->lemma;
        if (!defined $lemma or $lemma eq '_' or $lemma eq '?') {
            $a_node->set_lemma(lc($a_node->form));
        } else {
            $a_node->set_lemma(lc($lemma));
        }
    }
}

1;

__END__

=encoding utf-8

=head1 NAME 

Treex::Block::W2A::PT::FillMissingLemmas

=head1 DESCRIPTION

Fills missing lemmas.

=head1 AUTHORS

Luís Gomes <luis.gomes@di.fc.ul.pt>, <luismsgomes@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright © 2014 by NLX Group, Universidade de Lisboa
