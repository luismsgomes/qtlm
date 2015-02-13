package Treex::Block::T2T::EN2PT::DropNumberSign;
use Moose;
use Treex::Core::Common;
use utf8;

extends 'Treex::Core::Block';

sub process_ttree {
	my ( $self, $troot ) = @_;
    foreach my $tnode ( $troot->get_descendants ) {


	    next if $tnode->t_lemma ne '#PersPron';

	    if($tnode->get_attr('gram/verbmod') ne 'imp'){
            my $t_parent = $tnode->get_parent;
            $t_parent->set_attr( 'gram/person', $tnode->get_attr('gram/person') );
            $t_parent->set_attr( 'gram/gender', $tnode->get_attr('gram/gender') );
            $t_parent->set_attr( 'gram/number', $tnode->get_attr('gram/number') );
        }

	    $tnode->remove();

    }

}

1;

__END__

=encoding utf-8

=head1 NAME

Treex::Block::T2T::EN2PT::DropNumberSign

=head1 DESCRIPTION

=head1 AUTHORS

=head1 COPYRIGHT AND LICENSE

