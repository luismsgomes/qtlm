package Treex::Block::T2A::PT::DropSubjPersProns;
use utf8;
use Moose;
use Treex::Core::Common;
extends 'Treex::Core::Block';

sub process_tnode {
    my ( $self, $t_node ) = @_;
    
    if ($t_node->t_lemma eq "#PersPron" and $t_node->formeme eq "n:subj") {

        my $a_node = $t_node->get_lex_anode();

        if ($a_node) {
            foreach my $a_child ( $a_node->get_children() ) {
                $a_child->set_parent( $a_node->get_parent() );
            }
            $a_node->remove();
        }
        else {
            print STDERR "NO anode\n";
        }

        print STDERR "Perspron REMOVED\n";

    }

}

1;

__END__

=over
