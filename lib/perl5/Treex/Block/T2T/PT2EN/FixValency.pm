package Treex::Block::T2T::PT2EN::FixValency;
use Moose;
use Treex::Core::Common;
use utf8;

extends 'Treex::Core::Block';

my %PT2EN_FORMEME = (
    "clicar n:em+X" => "n:on+X",
    );



sub process_tnode {
	my ( $self, $t_node ) = @_;

    my $src_tnode = $t_node->src_tnode;

    if ($src_tnode) {

        my $src_parent = $src_tnode->get_parent;

        my $key = $src_parent->t_lemma." ".$src_tnode->formeme;

        if ($PT2EN_FORMEME{$key}) {
            $t_node->set_formeme($PT2EN_FORMEME{$key});
        }
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

