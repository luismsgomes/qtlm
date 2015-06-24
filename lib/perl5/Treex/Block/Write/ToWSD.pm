package Treex::Block::Write::ToWSD;
use Moose;
#extends 'Treex::Core::Block';
extends 'Treex::Block::Write::BaseTextWriter';

has '+extension' => ( default => '.wsd-input' );

sub a_node_to_slashed_token {
	my ( $a_node ) = @_;
	my $form = $a_node->form || '';
	my $lemma = $a_node->form || '';
	my $pos = $a_node->conll_pos || $a_node->tag || '';
	my $result = "$form/$lemma/$pos";
	$result =~ s/ /_/;
	return $result;
}

sub process_atree {
    my ( $self, $a_root ) = @_;

    my $wsd_input = join ' ',
    	map { a_node_to_slashed_token $_ } $a_root->get_descendants({ ordered => 1 });

    print { $self->_file_handle } $wsd_input."\n";
    return;
}

1;

__END__


=head1 NAME

Treex::Block::Write::ToWSD;


=head1 SYNOPSIS

This block prints sentences in the format expected by lx-wsd-module tool 
(developed by Steve Neale).

The LX-WSD tool wraps UKB (see http://ixa2.si.ehu.es/ukb/).


=head1 AUTHORS

Luís Gomes <luis.gomes@di.fc.ul.pt>, <luismsgomes@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright © 2014 by NLX Group, Universidade de Lisboa
