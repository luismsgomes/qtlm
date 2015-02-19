package Treex::Block::A2T::SetPersPron;
use Moose;
use Treex::Core::Common;
extends 'Treex::Core::Block';

sub process_tnode {
    my ( $self, $t_node ) = @_;
    my $anode = $t_node->get_lex_anode();
    if (($anode->iset->prontype || "") eq "prs") {
        $t_node->set_t_lemma("#PersPron");
    }
    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Treex::Block::A2T::SetPersPron

=head1 DESCRIPTION

t_lemma is changed to "#PersPron" according to the interset value (iset->prontype).

=over 4

=item process_anode

=back

=head1 AUTHOR

Zdeněk Žabokrtský <zaborktsky@ufal.mff.cuni.cz>
Luís Gomes <luismsgomes@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright © 2014 by NLX Group, Universidade de Lisboa

