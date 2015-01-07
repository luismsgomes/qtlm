package Treex::Block::W2A::PT::RemoveUnderscoresFromExpandedContractions;

use strict;
use warnings;
use Moose;
use Treex::Core::Common;
extends 'Treex::Core::Block';

sub process_anode {
    my ( $self, $a_node ) = @_;
    if ($a_node->form =~ /(.+)_$/) {
        $a_node->set_form($1);
    }
}

1;

__END__

=encoding utf-8

=head1 NAME 

Treex::Block::W2A::PT::RemoveUnderscoresFromExpandedContractions

=head1 DESCRIPTION

Removes underscores from expanded contractions such as "das" => "de_" "as".

=head1 AUTHORS

Luís Gomes <luis.gomes@di.fc.ul.pt>, <luismsgomes@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright © 2014 by NLX Group, Universidade de Lisboa
