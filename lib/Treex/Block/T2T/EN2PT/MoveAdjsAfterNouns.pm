package Treex::Block::T2T::EN2PT::MoveAdjsAfterNouns;
use Moose;
use Treex::Core::Common;
extends 'Treex::Core::Block';

sub process_ttree {
    my ( $self, $troot ) = @_;
    foreach my $tnode ( $troot->get_descendants ) {
        my $parent = $tnode->get_parent;
        if (( $tnode->formeme || "" ) =~ /^adj:/
            and $tnode->t_lemma !~ /^(?:maior|menor|melhor|pior|grande|pequeno|óptimo|péssimo)$/i
            and ( ( $parent->formeme || "" ) =~ /^n:/ )
            and $tnode->precedes($tnode->get_parent)
            and not $tnode->get_children
            and not $tnode->is_member
            and not $tnode->is_parenthesis
            ) {
                $tnode->shift_after_node($parent);
        }
    }

}

1;

__END__

=encoding utf-8

=head1 NAME

Treex::Block::T2T::EN2PT::MoveAdjsAfterNouns

=head1 DESCRIPTION

Adjectives (and other adjectivals) that preceed their governing nouns
are moved after them. Examples:
    social policy => política social
    European Commission => Comissão Europeia

=head1 AUTHORS

Luís Gomes <luis.gomes@di.fc.ul.pt>, <luismsgomes@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright © 2014 by NLX Group, Universidade de Lisboa
