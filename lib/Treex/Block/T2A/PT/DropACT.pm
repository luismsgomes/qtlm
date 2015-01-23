package Treex::Block::T2A::PT::DropACT;
use Moose;
use Treex::Core::Common;
extends 'Treex::Core::Block';


sub process_tnode {
    my ( $self, $tnode ) = @_;

    #TODO Verificar o que acontece com situações para alem do Senhor/Senhores, forçar verificação de lemma?
    if ($tnode->functor eq 'ACT'){
        my $a_node = $tnode->get_lex_anode() or return;
        $a_node->remove();
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
