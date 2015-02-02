package Treex::Block::A2T::EN::FixAdjNAttrNSub;
use Moose;
use Treex::Core::Common;
extends 'Treex::Core::Block';

sub process_ttree {
    my ( $self, $troot ) = @_;
    foreach my $tnode ( $troot->get_descendants ) {
        my $parent = $tnode->get_parent;
        if (( $tnode->formeme || "" ) =~ /^adj/
            and ( ( $parent->formeme || "" ) =~ /^n:attr/ )
            and $tnode->precedes($tnode->get_parent)
            and not $tnode->get_children
            and not $tnode->is_member
            and not $tnode->is_parenthesis
            ) {
                while (($parent->formeme || "" ) =~ /^n:attr/
                       and $tnode->precedes($parent)) {
                    $parent = $parent->get_parent;
                }
                $tnode->set_parent($parent);
        }
    }

}

1;

__END__

=encoding utf-8

=head1 NAME

Treex::Block::A2T::EN::FixAdjNAttrNSub

=head1 DESCRIPTION

Adjectives (and other adjectivals) that preceed their governing nouns
are moved after them. Examples:
    social policy => política social
    European Commission => Comissão Europeia

=head1 AUTHORS

Luís Gomes <luis.gomes@di.fc.ul.pt>, <luismsgomes@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright © 2014 by NLX Group, Universidade de Lisboa
