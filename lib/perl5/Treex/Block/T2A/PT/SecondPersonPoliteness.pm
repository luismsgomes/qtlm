package Treex::Block::T2A::PT::SecondPersonPoliteness;
use utf8;
use Moose;
use Treex::Core::Common;
extends 'Treex::Core::Block';

sub process_tnode {
    my ( $self, $t_node ) = @_;

    #print "so far OK";

    if ($t_node->t_lemma eq "#PersPron" and $t_node->gram_person eq "2") {
     #   print STDERR "CHANGED\n";
        my $a_node = $t_node->get_lex_anode() or return;
        $a_node->iset->set_person(3);
        #print STDERR "CHANGED2\n";
        
    }

    return;
}


1;

__END__

=encoding utf8

=over

=item Treex::Block::T2A::PT::SecondPersonPoliteness

=back

=cut

