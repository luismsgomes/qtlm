package Treex::Block::A2T::PT::FixFormeme;
use Moose;
use Treex::Core::Common;
extends 'Treex::Core::Block';

sub process_tnode {
    my ( $self, $tnode ) = @_;
    if ($tnode->formeme eq "adj:attr") {
        if ($tnode->parent->formeme =~ /n:/) {
            if ($tnode->precedes($tnode->parent)) {
                $tnode->set_formeme("adj:prenom");
            } else {
                $tnode->set_formeme("adj:postnom");
            }
        }
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

Treex::Block::A2T::PT::FixFormeme

=head1 DESCRIPTION


=head1 AUTHORS

Luís Gomes <luis.gomes@di.fc.ul.pt>, <luismsgomes@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright © 2014 by NLX Group, Universidade de Lisboa

Copyright © 2008 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.