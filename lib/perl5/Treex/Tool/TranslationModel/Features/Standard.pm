package Treex::Tool::TranslationModel::Features::Standard;
use strict;
use warnings;

sub _node_and_parent {
    my ( $tnode, $prefix ) = @_;
    return if $tnode->is_root();

    # features from the given tnode
    my %feats = (
        lemma     => $tnode->t_lemma,
        formeme   => $tnode->formeme,
        voice     => $tnode->voice,
        negation  => $tnode->gram_negation,
        tense     => $tnode->gram_tense,
        number    => $tnode->gram_number,
        person    => $tnode->gram_person,
        degcmp    => $tnode->gram_degcmp,
        sempos    => $tnode->gram_sempos,
        is_member => $tnode->is_member,
    );
    my $short_sempos = $tnode->gram_sempos;
    if ( defined $short_sempos ) {
        $short_sempos =~ s/\..+//;
        $feats{short_sempos} = $short_sempos;
    }

    # features from tnode's parent
    my ($tparent) = $tnode->get_eparents( { or_topological => 1 } );
    if ( !$tparent->is_root ) {
        $feats{precedes_parent} = $tnode->precedes($tparent);
    }

    # features from a-layer
    if (my $anode = $tnode->get_lex_anode) {
        $feats{tag} = $anode->tag;
        $feats{capitalized} = 1 if $anode->form =~ /^\p{IsUpper}/;
    }

    # features from n-layer (named entity type)
    if ( my $n_node = $tnode->get_n_node() ) {
        $feats{ne_type} = $n_node->ne_type;
    }

    my %f;
    while ( my ( $key, $value ) = each %feats ) {
        if ( defined $value ) {
            $f{ $prefix . $key } = $value;
        }
    }
    return %f;
}

sub _child {
    my ( $tnode, $prefix ) = @_;
    my %feats = (
        lemma   => $tnode->t_lemma,
        formeme => $tnode->formeme,
    );
    if ( my $n_node = $tnode->get_n_node() ) {
        $feats{ne_type} = $n_node->ne_type;
    }
    if (my $anode = $tnode->get_lex_anode) {
        $feats{tag} = $anode->tag;
        $feats{capitalized} = 1 if $anode->form =~ /^\p{IsUpper}/;
    }
    my %f;
    while ( my ( $key, $value ) = each %feats ) {
        if ( defined $value ) {
            $f{ $prefix . $key . '_' . $value } = 1;
        }
    }
    return %f;
}

sub _prev_and_next {
    my ( $tnode, $prefix ) = @_;
    if ( !defined $tnode ) {
        return ( $prefix . 'lemma' => '_SENT_' );
    }
    return ( $prefix . 'lemma' => $tnode->t_lemma, );

}

sub features_from_src_tnode {
    my ( $node, $arg_ref ) = @_;
    my ($parent) = $node->get_eparents( { or_topological => 1 } );

    my %features = (
        _node_and_parent( $node,   '' ),
        _node_and_parent( $parent, 'parent_' ),
        _prev_and_next( $node->get_prev_node, 'prev_' ),
        _prev_and_next( $node->get_next_node, 'next_' ),
        ( map { _child( $_, 'child_' ) } $node->get_echildren( { or_topological => 1 } ) ),
    );

    if ( $node->get_children( { preceding_only => 1 } ) ) {
        $features{has_left_child} = 1;
    }

    if ( $node->get_children( { following_only => 1 } ) ) {
        $features{has_right_child} = 1;
    }

    # We don't have a grammateme gram/definiteness so far, so let's hack it
    AUX:
    foreach my $aux ( $node->get_aux_anodes ) {
        my $form = lc( $aux->form );
        if ( $form eq 'the' ) {
            $features{determiner} = 'the';
            last AUX;
        }
        elsif ( $form =~ /^an?$/ ) {
            $features{determiner} = 'a';
        }
    }

    # BEGIN WSD features (2015-06-29, luis.gomes@di.fc.ul.pt)

    if (defined $ENV{"WSD_CONF"} and $ENV{"WSD_CONF"} =~ /node_synsetid/) {
        my $anode = $node->get_lex_anode();
        if (defined $anode and defined $anode->wild->{synsetid}
            and $anode->wild->{synsetid} ne "UNK") {
            # say STDERR "adding node+synsetid";
            $features{synsetid} = $anode->wild->{synsetid};
        }
    }

    if (defined $ENV{"WSD_CONF"} and $ENV{"WSD_CONF"} =~ /parent_synsetid/) {
        my $parent_anode = $node->get_parent()->get_lex_anode();
        if (defined $parent_anode and defined $parent_anode->wild->{synsetid}
            and $parent_anode->wild->{synsetid} ne "UNK") {
            # say STDERR "adding node+par+synsetid";
            $features{parent_synsetid} = $parent_anode->wild->{synsetid};
        }
    }

    if (defined $ENV{"WSD_CONF"} and $ENV{"WSD_CONF"} =~ /siblings_synsetids/) {
        # Please check if this is correct (what is a sibling...)

        my $left_sibling = $node->get_left_neighbor();
        if ( defined $left_sibling ) {
            my $left_sibling_anode = $left_sibling->get_lex_anode();
            if (defined $left_sibling_anode and defined $left_sibling_anode->wild->{synsetid}
                and $left_sibling_anode->wild->{synsetid} ne "UNK") {
                # say STDERR "adding node+leftsib+synsetid";
                $features{left_synsetid} = $left_sibling_anode->wild->{synsetid};
            }
        }

        my $right_sibling = $node->get_right_neighbor();
        if ( defined $right_sibling ) {
            my $right_sibling_anode = $right_sibling->get_lex_anode();
            if (defined $right_sibling_anode and defined $right_sibling_anode->wild->{synsetid}
                and $right_sibling_anode->wild->{synsetid} ne "UNK") {
                # say STDERR "adding node+rightsib+synsetid";
                $features{right_synsetid} = $right_sibling_anode->wild->{synsetid};
            }
        }
    }

    if (defined $ENV{"WSD_CONF"} and $ENV{"WSD_CONF"} =~ /node_supersense/) {
        my $anode = $node->get_lex_anode();
        if (defined $anode and defined $anode->wild->{supersense}
            and $anode->wild->{supersense} ne "UNK") {
            # say STDERR "adding node+supersense";
            $features{supersense} = $anode->wild->{supersense};
        }
    }

    if (defined $ENV{"WSD_CONF"} and $ENV{"WSD_CONF"} =~ /parent_supersense/) {
        my $parent_anode = $node->get_parent()->get_lex_anode();
        if (defined $parent_anode and defined $parent_anode->wild->{supersense}
            and $parent_anode->wild->{supersense} ne "UNK") {
            # say STDERR "adding node+par+supersense";
            $features{parent_supersense} = $parent_anode->wild->{supersense};
        }
    }

    if (defined $ENV{"WSD_CONF"} and $ENV{"WSD_CONF"} =~ /siblings_supersenses/) {
        # Please check if this is correct (what is a sibling...)

        my $left_sibling = $node->get_left_neighbor();
        if ( defined $left_sibling ) {
            my $left_sibling_anode = $left_sibling->get_lex_anode();
            if (defined $left_sibling_anode and defined $left_sibling_anode->wild->{supersense}
                and $left_sibling_anode->wild->{supersense} ne "UNK") {
                # say STDERR "adding node+leftsib+supersense";
                $features{left_supersense} = $left_sibling_anode->wild->{supersense};
            }
        }

        my $right_sibling = $node->get_right_neighbor();
        if ( defined $right_sibling ) {
            my $right_sibling_anode = $right_sibling->get_lex_anode();
            if (defined $right_sibling_anode and defined $right_sibling_anode->wild->{supersense}
                and $right_sibling_anode->wild->{supersense} ne "UNK") {
                # say STDERR "adding node+rightsib+supersense";
                $features{right_supersense} = $right_sibling_anode->wild->{supersense};
            }
        }
    }

    # END WSD features

    # Domain adaptation features (2015-06-29, luis.gomes@di.fc.ul.pt)
    # This code should appear just before calling encode_features_for_tsv
    # because all features should be already in $features:
    my $doc = $node->get_document();
    if ( defined $doc and defined $doc->wild->{in_domain} ) {
        my $key_prefix = $doc->wild->{in_domain} ? "indomain_" : "outdomain_";
        my @keys = keys %features;
        foreach my $key (@keys) {
            my $new_key   = $key_prefix.$key ;
            $features{$new_key} = $features{$key};
        }
    }
    
    if ( $arg_ref && $arg_ref->{encode} ) {
        encode_features_for_tsv( \%features );
    }

    return \%features;
}

sub encode_features_for_tsv {
    my ($feats_ref) = @_;
    my @keys = keys %{$feats_ref};
    foreach my $key (@keys) {
        my $new_key   = encode_string_for_tsv($key);
        my $value     = $feats_ref->{$key};
        my $new_value = encode_string_for_tsv($value);
        if ( $new_key ne $key ) {
            delete $feats_ref->{$key};
        }
        $feats_ref->{$new_key} = $new_value;
    }
    return;
}

# We need to escape spaces and equal signs,
# so features can be stored in name=value format (space-separated).
sub encode_string_for_tsv {
    my ($string) = @_;
    $string =~ s/%/%25/g;
    $string =~ s/ /%20/g;
    $string =~ s/=/%3D/g;
    return $string;
}

1;
