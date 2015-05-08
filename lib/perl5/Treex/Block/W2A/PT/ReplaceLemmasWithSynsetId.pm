package Treex::Block::W2A::PT::ReplaceLemmasWithSynsetId;
use Moose;
extends 'Treex::Core::Block';

sub process_anode {
    my ( $self, $anode ) = @_;
    my $synsetid = $anode->wild->{lx_wsd} // 'UNK';
    if ($synsetid ne 'UNK') {
        $anode->set_lemma($synsetid);
    }  
    return 1;
}

1;

__END__

=encoding utf-8

=head1 NAME 

Treex::Block::W2A::PT::ReplaceLemmasWithSynsetId

=head1 DESCRIPTION

Replaces lemmas with synset ids (where applicable).

=head1 AUTHORS

Luís Gomes <luis.gomes@di.fc.ul.pt>, <luismsgomes@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright © 2014 by NLX Group, Universidade de Lisboa
