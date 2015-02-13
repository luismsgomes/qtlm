package Treex::Block::T2T::EN2PT::FixGrammatemes;
use Moose;
use Treex::Core::Common;
use utf8;

extends 'Treex::Core::Block';

sub process_tnode {
	my ( $self, $tnode ) = @_;


#    my $src_tnode = $tnode->src_tnode();

	# by default, nouns are definite in Portugues

	if ( $tnode->gram_sempos eq "n.denot" and not $tnode->gram_definiteness ) {
		$tnode->set_gram_definiteness("definite");
	}


}

1;

__END__

=encoding utf-8

=head1 NAME

Treex::Block::T2T::EN2PT::FixPersPron

=head1 DESCRIPTION

=head1 AUTHORS

=head1 COPYRIGHT AND LICENSE

