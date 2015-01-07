package Treex::Block::W2A::PT::Parse;
use Moose;
use Treex::Core::Common;
extends 'Treex::Block::W2A::ParseMalt';

has '+model'          => ( is => 'ro', default => 'lx_malt_v1.model' );
has '+feat_attribute' => ( is => 'ro', default => 'conll/feat');

1;

__END__

=encoding utf-8

=head1 NAME 

Treex::Block::W2A::PT::ParseMalt

=head1 DESCRIPTION

Defines model and attribute name where features are stored by TagLXSuite.

=head1 SEE ALSO

L<Treex::Block::W2A::ParseMalt> base clase.

=head1 AUTHORS

Luís Gomes <luis.gomes@di.fc.ul.pt>, <luismsgomes@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright © 2014 by NLX Group, Universidade de Lisboa
