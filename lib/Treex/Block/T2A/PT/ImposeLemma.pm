package Treex::Block::T2A::PT::ImposeLemma;
use Moose;
use Treex::Core::Common;
extends 'Treex::Core::Block';


sub process_tnode {
    my ( $self, $tnode ) = @_;

    my $a_node = $tnode->get_lex_anode() or return;

    if ($tnode->t_lemma eq 'desastre'){
        $tnode->set_attr('t_lemma', 'email' );
        $a_node->set_attr('lemma', 'email' );
    }

    if ($tnode->t_lemma eq 'imprensa'){
        $tnode->set_attr('t_lemma', 'carregar' );
        $a_node->set_attr('lemma', 'carregar' );
    }

    if ($tnode->t_lemma eq 'animador'){
        $tnode->set_attr('t_lemma', 'clique' );
        $a_node->set_attr('lemma', 'clique' );
    }

    if ($tnode->t_lemma eq 'factura'){
        $tnode->set_attr('t_lemma', 'separador' );
        $a_node->set_attr('lemma', 'separador' );
    }

    return;
}


1;

__END__

=encoding utf-8

=head1 NAME 


=head1 DESCRIPTION


=head1 AUTHORS


=head1 COPYRIGHT AND LICENSE

Copyright © 2014 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
