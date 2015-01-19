package Treex::Block::T2A::PT::GenerateWordforms;
use Moose;
use Treex::Core::Common;
extends 'Treex::Core::Block';

use Treex::Tool::Lexicon::Generation::PT::ClientLXSuite;
use Data::Dumper;

has lxsuite_key => ( isa => 'Str', is => 'ro', required => 1 );
has lxsuite_host => ( isa => 'Str', is => 'ro', required => 1 );
has lxsuite_port => ( isa => 'Int', is => 'ro', required => 1 );
has generator => ( is => 'rw' );


sub process_anode {
    my ( $self, $anode ) = @_;
    return if defined $anode->form;

    #return $anode->set_form($anode->lemma) if (defined $anode->afun) && ($anode->afun eq 'Sb');
    if ((defined $anode->afun) && ($anode->afun eq 'Sb')){
    	print STDERR "->Warning, Afun=Sb, Lemma: ", $anode->lemma,"\n";
    }

    $anode->set_form($self->generator->best_form_of_lemma($anode->lemma, $anode->iset));
    return;
}

sub BUILD {
    my ( $self, $argsref ) = @_;
	$self->set_generator(Treex::Tool::Lexicon::Generation::PT::ClientLXSuite->new($argsref));
}

1;

__END__

=encoding utf-8

=head1 NAME 

Treex::Block::T2A::PT::GenerateWordforms

=head1 DESCRIPTION

just a draft of Portuguese verbal conjugation
(placeholder for the real morphological module by LX-Center)
based on http://en.wikipedia.org/wiki/Portuguese_verb_conjugation


=head1 AUTHORS 

Martin Popel <popel@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2014 by Institute of Formal and Applied Linguistics, Charles University in Prague
This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
