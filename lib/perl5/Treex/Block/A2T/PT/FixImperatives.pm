package Treex::Block::A2T::PT::FixImperatives;
use Moose;
use Treex::Core::Common;
extends 'Treex::Core::Block';

sub process_tnode {
    my ($self, $tnode, $anode) = @_;

    if($tnode->t_lemma eq '#PersPron' and $tnode->is_generated and $tnode->gram_person == 3){

		my $t_parent = $tnode->parent;
    	my $a_parent = $t_parent->get_lex_anode;

    	if($a_parent and $a_parent->iset->mood =~ /^(sub|ind)$/ and $t_parent->formeme eq 'v:fin' and $t_parent->t_lemma ne "haver") {
    		$tnode->set_gram_person(2);
    		$tnode->set_gram_politeness('polite');
            if ($a_parent->iset->mood eq 'sub') {  # indicative forms are kept indicative, only subjunctive turns to imperative
                $t_parent->set_gram_verbmod('imp');
            }
    	}


    }
    
    return;
}

1;

__END__

=encoding utf-8

=head1 NAME

Treex::Block::A2T::PT::SetGrammatemesFromAux

=head1 DESCRIPTION

A very basic, language-independent grammateme setting block for t-nodes. 
Grammatemes are set based on the Interset features (and formeme)
of the corresponding auxiliary a-nodes.

In addition to L<Treex::Block::A2T::SetGrammatemesFromAux>,
this block handles Portuguese analytic comparative ("mais feliz").

=head1 AUTHOR

Martin Popel <popel@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2014 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
