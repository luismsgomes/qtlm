package Treex::Block::T2A::PT::AddVerbNegation;
use utf8;
use Moose;
use Treex::Core::Common;
extends 'Treex::Core::Block';

sub process_tnode {

    my ( $self, $t_node ) = @_;

    # select only negated verbs
    return if ( ( $t_node->gram_sempos || '' ) !~ /^v/ or ( $t_node->gram_negation || '' ) ne 'neg1' );
    my $a_node = $t_node->get_lex_anode() or return;

    # create the particle 'not'
    my $neg_node = $a_node->create_child(
        {
            'lemma'        => 'não',
            'form'         => 'não',
            'afun'         => 'Neg',
            'morphcat/pos' => '!',
        }
    );
    $neg_node->shift_before_node($a_node);
    $t_node->add_aux_anodes($neg_node);


    return;


}

1;

__END__

=encoding utf-8

=head1 NAME 

Treex::Block::T2A::EN::AddVerbNegation

=head1 DESCRIPTION

Add the particle 'not' and the auxiliary 'do' for negated verbs.

=head1 AUTHORS 

Ondřej Dušek <odusek@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2014 by Institute of Formal and Applied Linguistics, Charles University in Prague
This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
