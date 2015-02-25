package Treex::Block::T2A::EN::DeleteYouInImperatives;
use Moose;
use Treex::Core::Common;
extends 'Treex::Core::Block';

sub process_tnode {
    my ( $self, $tnode ) = @_;

    if($tnode->t_lemma eq '#PersPron' and $tnode->formeme eq 'n:subj' and $tnode->gram_person == 2){
    	
    	my $t_parent = $tnode->get_parent;
    	if($t_parent->gram_verbmod eq 'imp'){
    		my $a_node = $tnode->get_lex_anode;
    		if($a_node){
    			foreach my $a_child ($a_node->get_children) {
    				$a_child->set_parent($a_node->get_parent)
    			}
    			$a_node->remove;
    		}
    	}
    }
};

1;

__END__

=encoding utf-8

=head1 NAME 

Treex::Block::T2A::EN::DeleteYouInImperatives

=head1 DESCRIPTION

Adding prepositional a-nodes according to prepositions contained in t-nodes' formemes.

English-specific: adding prepositions to gerunds. 

=head1 AUTHORS

Ondřej Dušek <odusek@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2014 by Institute of Formal and Applied Linguistics, Charles University in Prague
