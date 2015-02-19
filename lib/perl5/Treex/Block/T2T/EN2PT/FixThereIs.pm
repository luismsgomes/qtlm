package Treex::Block::T2T::EN2PT::FixThereIs;
use Moose;
use Treex::Core::Common;
use utf8;

extends 'Treex::Core::Block';

sub process_tnode {
	my ( $self, $t_node ) = @_;


    my $src_t_node = $t_node->src_tnode;
    my @anodes = $src_t_node->get_aux_anodes();
    return if !@anodes;

    foreach my $anode (@anodes) {
        if ( grep { $_ =~ /(There|there)/ }  $anode->form 
            and  grep { $_ =~ /(are|is)/ } $anode->get_parent->form) {        
    
            $t_node->set_t_lemma('haver');
            my $new_node = $t_node->create_child(
                {   't_lemma'         => '#PersPron',
                    'form'          => '',
                    'functor'       => 'ACT',
                    'gram/number'   => 'sg',
                    'gram/person'   => '3',
                    'gram/sempos'        => 'n.pron.def.pers',
                    'clause_number' => '1',
                    'formeme'       => 'n:subj',
                    'is_generated'  => '1',
                    'nodetype'      => 'complex'
                }
            );
            $new_node->shift_before_subtree($t_node);
        }
    }

}

1;

__END__

=encoding utf-8

=head1 NAME

Treex::Block::T2T::EN2PT::FixThereIs

=head1 DESCRIPTION

=head1 AUTHORS

=head1 COPYRIGHT AND LICENSE

