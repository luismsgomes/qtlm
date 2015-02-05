package Treex::Block::T2A::PT::DropACT;
use Moose;
use Treex::Core::Common;
extends 'Treex::Core::Block';


sub process_tnode {
    my ( $self, $t_node ) = @_;

    if ($t_node->functor eq 'ACT'){

        my $a_node = $t_node->get_lex_anode() or return;

        if($a_node->lemma =~ /^que$/){
            my $parent = $a_node->get_parent();

            if($parent->get_attr('gram/verbmod') eq 'imp' ){
                $a_node->remove();
                return;
            }
        }

        if($a_node->lemma =~ m/(senhor|senhores|ser|-lhes|ques|tratar|não)/){
        	

            if($t_node->get_attr('gram/verbmod') ne 'imp'){
                my $t_parent = $t_node->get_parent;
                $t_parent->set_attr( 'gram/person', $t_node->get_attr('gram/person') );
                $t_parent->set_attr( 'gram/gender', $t_node->get_attr('gram/gender') );
                $t_parent->set_attr( 'gram/number', $t_node->get_attr('gram/number') );
            }

            #$t_node->remove();
        	$a_node->remove();
        }


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
