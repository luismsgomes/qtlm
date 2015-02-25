package Treex::Block::T2T::PT2EN::FixThereIs;
use Moose;
use Treex::Core::Common;
use utf8;

extends 'Treex::Core::Block';

sub process_tnode {
	my ( $self, $t_node ) = @_;

    my $src_t_node = $t_node->src_tnode;

    if ($src_t_node and $src_t_node->t_lemma eq "haver") {
        $t_node->set_t_lemma('be');
        $t_node->wild->{there_is} = 1;
            # TODO: make sure it is a verb node
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

