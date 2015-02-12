package Treex::Block::T2A::PT::AddAuxVerbModalTense;

use utf8;
use Moose;
use Treex::Core::Common;

extends 'Treex::Block::T2A::AddAuxVerbModalTense';

override '_build_gram2form' => sub {

    return {
        'ind' => {
            'sim' => {
                ''        => '',
                'decl'    => '',
                'poss'    => 'poder',
                'poss_ep' => 'poder',
                'vol'     => 'querer',
                'deb'     => 'dever',
                'deb_ep'  => 'dever',
                'hrt'     => 'dever',
                'fac'     => 'poder / ser capaz (de)',
                'perm'    => 'poder',
                'perm_ep' => 'poder',
            },
            'ant' => {
                ''        => '',
                'decl'    => '',
                'poss'    => 'poder',
                'poss_ep' => 'poder',
                'vol'     => 'querer',
                'deb'     => 'dever',
                'deb_ep'  => 'dever',
                'hrt'     => 'dever',
                'fac'     => 'poder / ser capaz (de)',
                'perm_ep' => 'poder',
            },
            'post' => {
                ''     => '',
                'decl' => '',
                'poss' => 'poder',
                'vol'  => 'querer',
                'deb'  => 'ter de',
                'hrt'  => 'ter de',
                'fac'  => 'poder',
                'perm' => 'poder',
            },
        },
        'cdn' => {
            'sim' => {
                ''        => '',
                'decl'    => '',
                'poss'    => 'poder',
                'poss_ep' => 'poder',
                'vol'     => 'querer',
                'deb'     => 'dever',
                'deb_ep'  => 'dever',
                'hrt'     => 'dever',
                'fac'     => 'poder / ser capaz (de)',
                'perm'    => 'poder',
                'perm_ep' => 'poder',
            },
            'ant' => {
                ''        => '',
                'decl'    => '',
                'poss'    => 'poder',
                'poss_ep' => 'poder',
                'vol'     => 'querer',
                'deb'     => 'dever',
                'deb_ep'  => 'dever',
                'hrt'     => 'dever',
                'fac'     => 'poder / ser capaz (de)',
                'perm'    => 'poder',
                'perm_ep' => 'poder',
            },
            'post' => {
                ''     => '',
                'decl' => '',
                'poss' => 'poder',
                'vol'  => 'dever',
                'deb'  => 'dever',
                'hrt'  => 'dever',
                'fac'  => 'poder / ser capaz (de)',
                'perm' => 'poder',
            },
        },
    };
};

my %LEMMA_TRANSFORM = (
    'am'    => 'be',
    'could' => 'can',
    'was'   => 'be',
    'might' => 'may',
    'had'   => 'have',
    'would' => 'will',
);

my %FORM_TRANSFORM = (
    'am' => {
        '1' => {
            'P' => 'are',
        },
        '2' => {
            'S' => 'am',
        },
        '3' => {
            'S' => 'is',
        },
    },
    'want' => {
        '3' => {
            'S' => 'wants',
        },
    },
    'have' => {
        '3' => {
            'S' => 'has',
        },
    },
    'was' => {
        '1' => {
            'P' => 'were',
        },
        '2' => {
            'S' => 'were',
            'P' => 'were',
        },
        '3' => {
            'P' => 'were',
        },
    },
);

# get lemma of the auxiliary, given 1.person sg. in current tense
sub _get_lemma {
    my ($form) = @_;
    return $LEMMA_TRANSFORM{$form} ? $LEMMA_TRANSFORM{$form} : $form;
}

# get form of the auxiliary, adjusted for the given person and number
sub _get_form {
    my ( $form, $person, $number ) = @_;

    return (
        $FORM_TRANSFORM{$form}
            and $FORM_TRANSFORM{$form}->{$person}
            and $FORM_TRANSFORM{$form}->{$person}->{$number}
        )
        ? $FORM_TRANSFORM{$form}->{$person}->{$number} : $form;
}

override '_postprocess' => sub {
    my ( $self, $verbforms_str, $anodes ) = @_;

    # change morphology of the 1st auxiliary
    my ($afirst) = $anodes->[0];
    my ( $person, $number, $lemma ) = (
        $afirst->morphcat_person,
        $afirst->morphcat_number,
        $afirst->lemma
    );

    #print STDERR "\nPost process person ",  $person;
    #print STDERR "\nPost process number ",  $number;
    #print STDERR "\nPost process lemma  ",   $lemma;


    $afirst->set_lemma( _get_lemma($lemma) );
    #$afirst->set_form( _get_form( $lemma, $person, $number ) );

    # prepare the last form for generation (past participle/infinitive)
    if ( $verbforms_str =~ /have$/ ) {    # use VBN tag
        $anodes->[-1]->set_morphcat_voice('P');
        $anodes->[-1]->set_morphcat_tense('R');
        $anodes->[-1]->set_conll_pos('VBN');
    }
    else {               # use VB tag
        $anodes->[-1]->set_morphcat_subpos('f');
        $anodes->[-1]->set_conll_pos('VB');
    }
    return;
};

1;

__END__

=encoding utf-8

=head1 NAME 

Treex::Block::T2A::EN::AddAuxVerbModalTense

=head1 DESCRIPTION

Add auxiliary expression for combined modality and tense.

=head1 AUTHORS 

Ondřej Dušek <odusek@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2014 by Institute of Formal and Applied Linguistics, Charles University in Prague
This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
