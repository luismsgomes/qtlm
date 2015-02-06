package Treex::Block::W2A::NormalizeForms;

use strict;
use warnings;
use utf8;
use Moose;
use Treex::Core::Common;
extends 'Treex::Core::Block';

sub process_anode {
    my ( $self, $anode ) = @_;

    if ( $anode->form eq '"' ) {
        my $previous_anode = $anode->get_prev_node();
        if ( !$previous_anode || $previous_anode->form =~ /^[\(\[{<]$/ ||
                !$previous_anode->no_space_after ) {
            $anode->set_form('``');
            $anode->set_lemma('``');
        }
    }
    elsif ( $anode->form eq '[' ) {
        $anode->set_form('-LRB-');
        $anode->set_lemma('-LRB-');
    }
    elsif ( $anode->form eq ']' ) {
        $anode->set_form('-RRB-');
        $anode->set_lemma('-RRB-');
    }
    elsif ( $anode->form eq '’' ) {
        $anode->set_form("'");
        $anode->set_lemma("'");
    }
    elsif ( $anode->form =~ /[“«]/ ) {
        $anode->set_form('``');
        $anode->set_lemma('``');
    }
    elsif ( $anode->form =~ /["”»]/ ) {
        $anode->set_form("''");
        $anode->set_lemma("''");
    }
    elsif ( $anode->form =~ /—/ ) {
        $anode->set_form("--");
        $anode->set_lemma("--");
    }

    return 1;
}

1;

__END__

=encoding utf-8

=head1 NAME

Treex::Block::W2A::NormalizeForms - normalize some wordforms

=head1 DESCRIPTION

Some forms are normalized, for example all the quotation marks
get the normalized form `` and ''.

=over 4

=item process_anode

=back

=head1 AUTHOR

Luís Gomes <luismsgomes@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright © 2014 by NLX Group, Universidade de Lisboa

