package Treex::Block::W2A::PT::Tag;
use Moose;
use Treex::Tool::Tagger::LXTagger;
extends 'Treex::Block::W2A::Tag';

has '+lemmatize' => ( default => 1 );
has debug => ( isa => 'Bool', is => 'ro', required => 0, default => 0 );
has lxsuite_host => ( isa => 'Str', is => 'ro', required => 1);
has lxsuite_port => ( isa => 'Int', is => 'ro', required => 1);
has lxsuite_key => ( isa => 'Str', is => 'ro', required => 1 );

sub _build_tagger{
 	my $self = shift;
    return Treex::Tool::Tagger::LXTagger->new($self->_args);
}

after 'process_atree' => sub {
    my ( $self, $atree ) = @_;
    my @nodes = $atree->get_descendants({ordered=>1});
    foreach my $a_node (@nodes) {
        my $form = $a_node->form;
    	my $pos_feats = $a_node->tag;
    	my ($pos, $feats) = split('#', $pos_feats);
        $a_node->set_conll_pos($pos);
        $a_node->set_conll_cpos($pos);
        if (defined $feats) {
            $a_node->set_conll_feat($feats);
        } else {
            $a_node->set_conll_feat('_');
        }
    }
};

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Treex::Block::W2A::PT::TagLXSuite - Portuguese PoS+morpho tagger

=head1 DESCRIPTION

Each node in the analytical tree is tagged using the
 L<Treex::Tool::Tagger::LXSuite> tagger.

=head1 AUTHORS

Luís Gomes <luis.gomes@di.fc.ul.pt>, <luismsgomes@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright © 2014 by NLX Group, Universidade de Lisboa

