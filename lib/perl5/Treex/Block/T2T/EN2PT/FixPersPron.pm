package Treex::Block::T2T::EN2PT::FixPersPron;
use Moose;
use Treex::Core::Common;
use utf8;

extends 'Treex::Core::Block';

sub process_tnode {
	my ( $self, $tnode ) = @_;

    my $src_tnode = $tnode->src_tnode();

    if ($src_tnode and $src_tnode->t_lemma eq "#PersPron" ) {
            my $old_t_lemma = $tnode->t_lemma;
            $tnode->set_t_lemma("#PersPron");
            if ($tnode->gram_gender eq "neut") {
                print STDERR "Treex::Block::T2T::EN2PT::FixPersPron: changed lemma from $old_t_lemma to #PersPron and gender from neut to anim\n";
                $tnode->set_gram_gender("anim");
            } else {
                print STDERR "Treex::Block::T2T::EN2PT::FixPersPron: changed lemma from $old_t_lemma to #PersPron\n";
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

