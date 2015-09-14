package Treex::Block::W2A::EN::GazeteerMatch;
use utf8;
use Moose;
use Treex::Core::Common;
use Treex::Core::Resource;

use List::MoreUtils qw/none all/;
use List::Util qw/sum/;

extends 'Treex::Core::Block';

has 'phrase_list_path' => ( is => 'ro', isa => 'Str', default => 'data/models/gazeteer/pt_en/20150910_001.IT.pt_en.en.gaz.gz');
# idx removed: libreoffice_16090, libreoffice_16123, libreoffice_73656

#has 'phrase_list_path' => ( is => 'ro', isa => 'Str', default => 'data/models/gazeteer/skuska.gaz.gz');

has '_searchine' => ( is => 'ro', isa => 'HashRef', builder => '_build_searchine', lazy => 1);

sub _build_searchine {
    my ($self) = @_;

    log_info "Loading the English gazeteer list...";
    log_info "Building a state machine for searching...";

    my $path = require_file_from_share($self->phrase_list_path);
    open my $fh, "<:gzip:utf8", $path;

    my $searchine = {};

    while (my $line = <$fh>) {
        chomp $line;
        my ($id, @phrase_rest) = split /\t/, $line;
        my $phrase = join " ", @phrase_rest;

        insert_phrase_to_searchine($searchine, $phrase, $id);
    }
    close $fh;

    #log_info Dumper($searchine);

    return $searchine;
}

sub process_start {
    my ($self) = @_;
    $self->_searchine;
}

sub process_atree {
    my ( $self, $atree ) = @_;

    my $matches = match_phrases_in_atree($atree, $self->_searchine);
    
    # assess which candidates are likely to be entity phrases and return only the mutually exclusive ones
    my $entities = _resolve_entities($matches);

    $Data::Dumper::Maxdepth = 2;
    #log_info Dumper($matches);
    
    # transform the a-tree
    my $entity_anodes = _collapse_entity_anodes($atree, $entities);

    my $collapsed_entities = _collapse_neighboring_entities($entity_anodes);
    
    $entity_anodes = _collapse_entity_anodes($atree, $collapsed_entities);
    #log_info Dumper($collapsed_entities);

}

my $INFO_LABEL = "__INFO__";

sub insert_phrase_to_searchine {
    my ($searchine, $phrase, $id) = @_;

    #my $debug = 0;
    #if ($id eq "libreoffice_25826") {
    #    $debug = 1;
    #}

    return if ($phrase =~ /^\s*$/);

    my @words = map {lc($_)} (split / +/, $phrase);
    my $next_word = shift @words;
    while (defined $next_word && defined $searchine->{$next_word}) {
        #log_info "NEXT_WORD_GET: " . $next_word if ($debug);
        $searchine = $searchine->{$next_word};
        $next_word = shift @words;
    }

    # there is a tail of remaining words
    if (defined $next_word) {
        my $suffix_hash = {};
        while ($next_word) {
            #log_info "NEXT_WORD_SET: " . $next_word if ($debug);
            $searchine->{$next_word} = {}; 
            $searchine = $searchine->{$next_word};
            $next_word = shift @words;
        }
        my $info = [$id, $phrase];
        $searchine->{$INFO_LABEL} = $info;
    }
    # all words are indexed in a searchine
    else {
        my $info = $searchine->{$INFO_LABEL};
        if (!defined $info) {
            $info = [$id, $phrase];
            $searchine->{$INFO_LABEL} = $info;
        }
        # else: this phrase is already stored - skip it
    }
}

sub match_phrases_in_atree {
    my ($atree, $searchine) = @_;
    
    my @anodes = $atree->get_children( {ordered => 1} );

    my @matches = ();
    my @unproc_searchine_nodes = ();
    my @unproc_anodes = ();

    foreach my $anode (@anodes) {
        unshift @unproc_searchine_nodes, $searchine;

        my $word = lc($anode->form);

        @unproc_searchine_nodes = map {$_->{$word}} @unproc_searchine_nodes;
        my @found = map {defined $_ ? 1 : 0} @unproc_searchine_nodes;
        unshift @unproc_anodes, [];
        @unproc_anodes = grep {defined $_} 
            map { if ($found[$_]) {
                    [ @{$unproc_anodes[$_]}, $anode ] 
                  } else {
                    undef;
                  }
                } 0 .. $#unproc_anodes;
        @unproc_searchine_nodes = grep {defined $_} @unproc_searchine_nodes;

        my @new_matches = map {[@{$unproc_searchine_nodes[$_]->{$INFO_LABEL}}, $unproc_anodes[$_]]} 
            grep {defined $unproc_searchine_nodes[$_]->{$INFO_LABEL}} 0 .. $#unproc_searchine_nodes;
        push @matches, @new_matches;
    }
    return \@matches;
}

sub _resolve_entities {
    my ($matches) = @_;

    my @scores = map {_score_match($_)} @$matches;
    my @accepted_idx = grep {$scores[$_] > 0} 0 .. $#scores;
    
    my @sorted_idx = sort {$scores[$b] <=> $scores[$a]} @accepted_idx;

    my %covered_anode = ();
    my @resolved_entities = ();
    foreach my $idx (@sorted_idx) {
        my $cand = $matches->[$idx];
        if (none {$covered_anode{$_->id}} @{$cand->[2]}) {
            push @resolved_entities, $cand;
            $covered_anode{$_->id} = 1 foreach (@{$cand->[2]});
        }
    }

    return \@resolved_entities;
}

sub _score_match {
    my ($match) = @_;

    my @anodes = @{$match->[2]};
    my @forms = map {$_->form} @anodes;

    my $full_str = join " ", @forms;
    
    my $full_str_score = ($full_str eq $match->[1]) ? 2 : 0;

    my $non_alpha_penalty = ($full_str !~ /[a-zA-Z]/) ? -100 : 0;

    my $first_starts_capital = ($forms[0] =~ /^\p{IsUpper}/) ? 10 : -10;
    my $entity_starts_capital = ($match->[1] =~ /^\p{IsUpper}/) ? 10 : -50;

    my $all_start_capital = (all {$_ =~ /^\p{IsUpper}/} @forms) ? 1 : -1;
    my $no_first = (all {$_->ord > 1} @anodes) ? 1 : -50;

    my $last_menu = ($forms[$#forms] eq "menu") ? -50 : 0;

    my @scores = ( $full_str_score, $non_alpha_penalty, $all_start_capital, 
        $no_first, $first_starts_capital, $entity_starts_capital, $last_menu );
    my $score = (sum @scores) * (scalar @anodes);
    
    return $score;
}

sub _collapse_neighboring_entities {
    my ($entity_anodes) = @_;

    my %covered_anodes = ();

    my @collapsed_entities = ();

    foreach my $anode (@$entity_anodes) {
        my $id = $anode->wild->{gazeteer_entity_id};
        my $phrase = $anode->wild->{matched_item};
        
        next if (defined $covered_anodes{$anode->id});

        $covered_anodes{$anode->id} = 1;
    
        my @consec_ids = ( $id );
        my @consec_phrases = ( $phrase );
        my @consec_anodes = ( $anode );

        my $prev_anode = $anode->get_prev_node;
        while (defined $prev_anode && (defined $prev_anode->wild->{gazeteer_entity_id} || $prev_anode->form =~ /^[>]$/)) {
            if (defined $prev_anode->wild->{gazeteer_entity_id}) {
                unshift @consec_ids, $prev_anode->wild->{gazeteer_entity_id};
                unshift @consec_phrases, $prev_anode->wild->{matched_item};
            }
            else {
                unshift @consec_ids, "__PUNCT__";
                unshift @consec_phrases, $prev_anode->form;
            }
            unshift @consec_anodes, $prev_anode;
            $covered_anodes{$prev_anode->id} = 1;
            $prev_anode = $prev_anode->get_prev_node;
        }
        my $next_anode = $anode->get_next_node;
        while (defined $next_anode && (defined $next_anode->wild->{gazeteer_entity_id} || $next_anode->form =~ /^[>]$/)) {
            if (defined $next_anode->wild->{gazeteer_entity_id}) {
                push @consec_ids, $next_anode->wild->{gazeteer_entity_id};
                push @consec_phrases, $next_anode->wild->{matched_item};
            }
            else {
                push @consec_ids, "__PUNCT__";
                push @consec_phrases, $next_anode->form;
            }
            push @consec_anodes, $next_anode;
            $covered_anodes{$next_anode->id} = 1;
            $next_anode = $next_anode->get_next_node;
        }

        push @collapsed_entities, [\@consec_ids, \@consec_phrases, \@consec_anodes];
    }

    return \@collapsed_entities;
}

sub _collapse_entity_anodes {
    my ($atree, $entities) = @_;

    my @entity_anodes = ();

    foreach my $entity (@$entities) {

        my @anodes = sort {$a->ord <=> $b->ord} @{$entity->[2]};
        my $new_anode = $atree->create_child({
            form => 'item',
        });
        $new_anode->wild->{gazeteer_entity_id} = $entity->[0];
        $new_anode->wild->{matched_item} = $entity->[1];

        $new_anode->shift_before_node($anodes[0]);
        push @entity_anodes, $new_anode;
        $_->remove() foreach (@anodes);
#        my $node_before = $new_anode->get_prev_node;
#        if (defined $node_before && ($node_before->form !~ /^the$|^a$|^an$/)) {
#            my $the_anode = $atree->create_child({
#                form => 'the',
#            });
#            $the_anode->shift_before_node($new_anode);
#        }
    }
    return \@entity_anodes;
}



1;

__END__

=encoding utf-8

=head1 NAME

=item Treex::Block::W2A::EN::GazeteerMatch

=head1 DESCRIPTION


=head1 AUTHORS

Michal Novák <mnovak@ufal.mff.cuni.cz>


=head1 COPYRIGHT AND LICENSE

Copyright © 2015 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
