package Treex::Block::T2T::EN2PT::AddRelpronBelowRc;
use utf8;
use Moose;
use Treex::Core::Common;
extends 'Treex::Core::Block';

sub process_ttree {
    my ( $self, $t_root ) = @_;

    RELCLAUSE:  
    foreach my $rc_head ( grep { $_->formeme =~ /rc/ } $t_root->get_descendants ) {

        # TODO: add "qual" (but it is a grandson, not a son node)
        next RELCLAUSE if grep {$_->t_lemma =~ /^(que|onde|cujo)$/} $rc_head->get_children; # TODO: it is rather the formeme that should be fixed (not here, but upstream)

        my $src_tnode = $rc_head->src_tnode;
        next RELCLAUSE if !$src_tnode;
        next RELCLAUSE 
            if (($src_tnode->formeme =~ /rc/) && !$src_tnode->wild->{rc_no_relpron});

        # Grammatical antecedent is typically the nominal parent of the clause
        my ($gram_antec) = $rc_head->get_eparents( { ordered => 1 } );
        next RELCLAUSE if !$gram_antec;
        next RELCLAUSE if $gram_antec->formeme !~ /^n/;

#        my $child = $rc_head->get_children({preceding_only=>1, first_only=>1});

        #print STDERR "AddRelpronBelowRc ". $rc_head->t_lemma . " - " . $child->t_lemma . "\n\n";
#        next if (!$child);
#        next if $child->t_lemma ne '#PersPron';

        
        # Create new t-node
        my $relpron = $rc_head->create_child(
            {   nodetype         => 'complex',
                functor          => '???',
                formeme          => 'n:obj',
                t_lemma          => 'que',
                t_lemma_origin   => 'Add_relpron_below_rc',
                'gram/sempos'    => 'n.pron.indef',
                'gram/indeftype' => 'relat',

            }
        );
        #$relpron->set_deref_attr( 'coref_gram.rf', [$gram_antec] );

        $relpron->shift_before_subtree($rc_head);
    }
    return;
}

1;

=over

=item Treex::Block::T2T::EN2CS::AddRelpronBelowRc

Generating new t-nodes corresponding to relative pronoun 'ktery' below roots
of relative clauses, whose source-side counterparts were not relative
clauses (e.g. when translatin an English gerund to a Czech relative
clause ). Grammatical coreference is filled too.

=back

=cut

# Copyright 2009 Zdenek Zabokrtsky
# This file is distributed under the GNU General Public License v2. See $TMT_ROOT/README.
