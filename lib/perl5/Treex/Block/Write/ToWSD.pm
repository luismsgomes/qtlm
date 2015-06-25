package Treex::Block::Write::ToWSD;
use Moose;
extends 'Treex::Block::Write::BaseTextWriter';

has '+extension' => ( default => '.wsd-input' );

has 'format' => ( is => 'ro', default => 'tsv' );

has 'field_sep' => ( is => 'rw',  default => '\t' );
has 'token_sep' => ( is => 'rw',  default => '\n' );
has 'sent_sep' => ( is => 'rw',  default => '\n\n' );

sub BUILD {
    my $self = shift;
    if ($self->format eq "tsv") {
    	$self->set_field_sep("\t");
    	$self->set_token_sep("\n");
    	$self->set_sent_sep("\n\n");
    } elsif ($self->format eq "slash") {
    	$self->set_field_sep("/");
    	$self->set_token_sep(" ");
    	$self->set_sent_sep("\n");
    }
}

sub format_token {
	my ( $field_sep, $a_node ) = @_;
	my $form = $a_node->form || '';
	my $lemma = lc ($a_node->form || '');
	my $pos = $a_node->conll_pos || $a_node->tag || '';
	$form =~ s/ /_/;
	$lemma =~ s/ /_/;
	my $result = "$form".$field_sep."$lemma".$field_sep."$pos";
	return $result;
}

sub print_header {
    my ( $self, $document ) = @_;
    if ($self->format eq "tsv") {
    	print { $self->_file_handle } "form\tlemma\tpos\n";
    }
    return;
}

sub process_atree {
    my ( $self, $a_root ) = @_;

    my $wsd_input = join $self->token_sep,
    	map { format_token($self->field_sep, $_) }
    	$a_root->get_descendants({ ordered => 1 });

    print { $self->_file_handle } $wsd_input.$self->sent_sep;
    return;
}

1;

__END__


=head1 NAME

Treex::Block::Write::ToWSD;


=head1 SYNOPSIS

This block prints sentences in the formats expected by either:
 * the UKB Python wrapper (lib/python3/ukb.py)
 * the UKB Bash wrapper (tools/lx-wsd-module-vx.y) (by Steve Neale).

For the first format give format=tsv and for the second format=slash.

For more information about UKB see http://ixa2.si.ehu.es/ukb/.


=head1 AUTHORS

Luís Gomes <luis.gomes@di.fc.ul.pt>, <luismsgomes@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright © 2014 by NLX Group, Universidade de Lisboa
