package Treex::Block::T2T::EN2PT::FixPersPron;
use Moose;
use Treex::Core::Common;
use utf8;

extends 'Treex::Core::Block';

sub process_tnode {
	my ( $self, $tnode ) = @_;


    my $src_tnode = $tnode->src_tnode();

    if ($src_tnode and $src_tnode->t_lemma eq "#PersPron" ) {
            $tnode->set_t_lemma("#PersPron");
            print STDERR "FIXED\n";

            if ($tnode->gram_gender eq "neut") {
                $tnode->set_gram_gender("anim");
            }
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

