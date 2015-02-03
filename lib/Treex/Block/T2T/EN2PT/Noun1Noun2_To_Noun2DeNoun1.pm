package Treex::Block::T2T::EN2PT::Noun1Noun2_To_Noun2DeNoun1;
use Moose;
use Treex::Core::Common;
use LX::Data::PT;
use utf8;

extends 'Treex::Core::Block';

# say 'yes' if exists $LX::Data::PT::gentilicos{'português'};

sub process_ttree {
    my ( $self, $troot ) = @_;
    foreach my $tnode ( $troot->get_descendants ) {
        my $parent = $tnode->get_parent;
        if (( $tnode->formeme || "" ) =~ /^n:(?:attr|de\+X)/ and
                (( $parent->formeme || "" ) =~ /^n:/ ) and
                $tnode->precedes($parent)) {
            $tnode->shift_after_node($parent);

            if ($tnode->formeme =~ /^n:attr/ and
                    !exists $LX::Data::PT::gentilicos{$tnode->t_lemma}) {
                $tnode->set_formeme("n:de+X");
            }
        }
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

Treex::Block::T2T::EN2PT::Noun1Noun2_To_Noun2DeNoun1

=head1 DESCRIPTION

Example:
    text tokenization => tokenização de texto

Exceptions:
    gentílicos:
        portuguese researcher => investigador português


=head1 AUTHORS

Luís Gomes <luis.gomes@di.fc.ul.pt>, <luismsgomes@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright © 2014 by NLX Group, Universidade de Lisboa
