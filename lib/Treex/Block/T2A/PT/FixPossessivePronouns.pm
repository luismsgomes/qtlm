package Treex::Block::T2A::PT::FixPossessivePronouns;
use Moose;
use Treex::Core::Common;
extends 'Treex::Core::Block';

my %CONJ = (
    'seu masc sing' => 'seu',
    'seu fem sing' => 'sua',
    'seu masc plur' => 'seus',
    'seu fem plur' => 'suas',

    'teu masc sing' => 'teu',
    'teu fem sing' => 'tua',
    'teu masc plur' => 'teus',
    'teu fem plur' => 'tuas',

    'meu masc sing' => 'meu',
    'meu fem sing' => 'minha',
    'meu masc plur' => 'meus',
    'meu fem plur' => 'minhas',

);

sub process_anode {
    my ( $self, $anode ) = @_;
    return if defined $anode->form;

    if ($anode->iset->prontype =~ m/prn/ && $anode->iset->poss =~ m/poss/){

        $anode->set_lemma('seu') if $anode->lemma =~ /(seu|sua|seus|suas)/;
        $anode->set_lemma('teu') if $anode->lemma =~ /(teu|tua|teus|tuas)/;
        $anode->set_lemma('meu') if $anode->lemma =~ /(meu|minha|meus|minhas)/;

        my $parent = $anode->get_parent();

        my $new_lemma = $CONJ{$anode->lemma . " " . $parent->iset->gender . " " . $parent->iset->number};
        
        $anode->set_lemma($new_lemma) if defined $new_lemma; 
        
        return;
    }

  
    return;
}


1;

__END__

=encoding utf-8

=head1 NAME 

Treex::Block::T2A::PT::FixPossessivePronouns

=head1 DESCRIPTION

Pronomes possessivos são inflexionados admitindo possivel erro no transfer do lemma

=head1 AUTHORS 

Name <email>

=head1 COPYRIGHT AND LICENSE

Copyright © 2014 by Institute of Formal and Applied Linguistics, Charles University in Prague
This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

