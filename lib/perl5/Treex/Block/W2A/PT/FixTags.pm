package Treex::Block::W2A::PT::FixTags;
use Moose;
extends 'Treex::Core::Block';

sub process_anode {
    my ( $self, $anode ) = @_;
#print STDERR "SUCCESSSSSSSSSSSSSSS 0\n";    
    if (lc($anode->form) eq 'se'){

        print STDERR (join " ", map {"$_".$anode->attr("conll/$_")} qw(pos cpos feat));
        print STDERR "\n";

#print STDERR "SUCCESSSSSSSSSSSSSSS 1 \n";
        my $previous_anode = $anode->get_prev_node;
        if($previous_anode
            #and do {print STDERR "SUCCESSSSSSSSSSSSSSS 1.5 \n";}
            and $previous_anode->attr('conll/cpos') eq 'V') {

            #print STDERR "SUCCESSSSSSSSSSSSSSS 3\n";
            $anode->set_attr('conll/pos', 'CJ' );
            $anode->set_attr('conll/cpos', 'CJ');
            $anode->set_attr('conll/feat', '_');
        }

    }  
    return 1;
}

1;

__END__

=encoding utf-8

=head1 NAME 

Treex::Block::W2A::PT::Tokenize

=head1 DESCRIPTION

Uses LX-Suite tokenizer to split a sentence into a sequence of tokens.

=head1 AUTHORS

Luís Gomes <luis.gomes@di.fc.ul.pt>, <luismsgomes@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright © 2014 by NLX Group, Universidade de Lisboa
