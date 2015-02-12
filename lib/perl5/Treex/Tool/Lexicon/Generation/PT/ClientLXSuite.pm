package Treex::Tool::Lexicon::Generation::PT::ClientLXSuite;
use Moose;
use utf8;
use Treex::Tool::ProcessUtils;
use Treex::Core::Common;
use Treex::Core::Resource;
use Treex::Tool::LXSuite::LXConjugator;
use Treex::Tool::LXSuite::LXInflector;

has lxsuite_key => ( isa => 'Str', is => 'ro', required => 1 );
has lxsuite_host => ( isa => 'Str', is => 'ro', required => 1 );
has lxsuite_port => ( isa => 'Int', is => 'ro', required => 1 );
has [qw( _conjugator _inflector )] => ( is => 'rw' );

my %PTFORM = (
    'ind pres' => 'pi',
    'ind past' => 'ppi',
    'ind imp'  => 'ii',
    'ind pqp'  => 'mpi',
    'ind fut'  => 'fi',
    'cnd '     => 'c',
    'sub pres' => 'pc',
    'sub imp'  => 'ic',
    'sub fut'  => 'fc',
);

my %PTNUMBER = (
    'sing' => 's',
    'plur' => 'p',
);

my %PTCATEGORY = (
    'adj' => 'ADJ',
    'noun' => 'CN',
);

my %PTGENDER = (
    'fem' => 'f',
    'masc' => 'm',
);


sub best_form_of_lemma {

    my ( $self, $lemma, $iset ) = @_;

    if ($lemma eq ""){
        log_warn "Lemma is null";
        return "null";
    }

    if ($lemma !~ /^[[:alpha:]]+$/u){
        log_warn "Lemma $lemma has non-alphanumeric characters";
        return $lemma;
    }

    return $lemma if ($lemma =~ /_/);

    my $pos     = $iset->pos;
    my $number  = $PTNUMBER{$iset->number || 'sing'};

    if ($pos eq 'verb'){

        my $mood    = $iset->mood;
        if(not $mood){ return $lemma; }

        my $tense   = $iset->tense;
        my $person  = $iset->person || '1';
        my $form    = $PTFORM{"$mood $tense"} || 'pi';

        if($mood eq 'imp'){
            $form   = 'pc';
            $person = '3';
            $number = 's';
        }

        my $response = $self->_conjugator->conjugate($lemma, $form, $person, $number);

        if(ucfirst($lemma) eq $lemma){
            $response = ucfirst($response);
        }

        #Ocorreu qualquer erro no conjugador...
        return $lemma if $response eq '<NULL>';
        
        return $response;
    }
    elsif ($pos =~/^(noun|adj)$/){

        #Ignora pronomes possessivos
        if ($iset->prontype eq 'prn' && $iset->poss eq 'poss'){
            return $lemma;
        }

        #Salta os endereços electrónicos
        if ($lemma =~ /^(?:https?|s?ftps?):\/\//) { return $lemma; }
        if ($lemma =~ /^(?:www\.|[a-z0-9\.\-]+@[a-z0-9\-\.]+)/) { return $lemma; }

        #TODO: Martelada, perguntar And. e Nuno como resolver isto: $pos = adj|noun
        my $number  = $number;
        my $pos     = $PTCATEGORY{"$pos"} || 'adj';
        my $gender  = $PTGENDER{$iset->gender} || 'm';

        my $superlative = "false";
        my $diminutive = "false";


        if($iset->degree eq 'sup'){
            $superlative = "true";
        }

        my $response = $self->_inflector->inflect( lc $lemma, $pos, $gender, $number,$superlative, $diminutive);

        if(ucfirst($lemma) eq $lemma){
            $response = ucfirst($response);
        }

        #Se não é permitido mudar o número não é permitido flexionar em número
        return $lemma if $response eq 'non-existing1';
        return $response;

    }

    return $lemma;

}

sub BUILD {
    my $self = shift;
    my $lxconfig = {
        lxsuite_key  => $self->lxsuite_key,
        lxsuite_host => $self->lxsuite_host,
        lxsuite_port => $self->lxsuite_port,
    };
    $self->_set_conjugator(Treex::Tool::LXSuite::LXConjugator->new($lxconfig));
    $self->_set_inflector(Treex::Tool::LXSuite::LXInflector->new($lxconfig));
}

1;

__END__

=head1 NAME

Treex::Tool::Lexicon::Generation::PT

=head1 SYNOPSIS


=head1 DESCRIPTION

=head1 AUTHORS

=head1 COPYRIGHT AND LICENSE

Copyright © 2014 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
