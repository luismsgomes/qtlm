package Treex::Block::T2T::EN2PT::FixPunctuation;
use Moose;
use Treex::Core::Common;
use utf8;

extends 'Treex::Core::Block';

sub process_tnode {
	my ( $self, $tnode ) = @_;

    my $src_tnode = $tnode->src_tnode();

    if ($src_tnode and $src_tnode->t_lemma  =~ /^[<>]$/) {
            $tnode->set_formeme('x');
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

Treex::Block::T2T::EN2PT::FixPunctuation

=head1 DESCRIPTION

=head1 AUTHORS

=head1 COPYRIGHT AND LICENSE

