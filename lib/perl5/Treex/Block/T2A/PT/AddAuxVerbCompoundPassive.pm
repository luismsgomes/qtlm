package Treex::Block::T2A::PT::AddAuxVerbCompoundPassive;
use utf8;
use Moose;
use Treex::Core::Common;
extends 'Treex::Core::Block';

sub process_tnode {
    my ( $self, $t_node ) = @_;
    return if ( $t_node->voice || $t_node->gram_diathesis || '' ) !~ /^pas/;
    my $a_node = $t_node->get_lex_anode() or return;


    #Nó pai é definido como participio passado
    #$a_node->set_attr( 'iset/mood', 'ind');
    #$a_node->set_attr( 'iset/tense', 'past');
    #$a_node->iset->set_voice('pass');

    my $gender = $a_node->get_attr('iset/gender') // '';
    my $number = $a_node->get_attr('iset/number') // '';

    #Acrescentado nó filho, lado esquerdo mais próximo
    my $new_node = $a_node->create_child({
            'lemma'         => 'ser',
            'afun'          => 'AuxV',
        });

    $new_node->iset->set_gender($gender);
    $new_node->iset->set_number($number);
    $new_node->iset->set_pos('verb');
    $new_node->iset->set_person('3');
    $new_node->iset->set_mood('ind');
    $new_node->iset->set_tense('pres');

    $new_node->shift_before_node($a_node);
    $t_node->add_aux_anodes($new_node);


    return;
}


1;

__END__

=encoding utf8

=over

=item Treex::Block::T2A::PT::AddAuxVerbCompoundPassive

=back

=cut

