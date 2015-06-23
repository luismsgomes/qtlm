package Treex::Block::W2A::PT::LXSuite;
use Moose;
use File::Basename;
use Frontier::Client;
use Encode;

extends 'Treex::Core::Block';

has server => ( isa => 'Frontier::Client',
    is => 'ro', required => 1, builder => '_build_server', lazy => 1 );

has key => ( isa => 'Str', is => 'ro', required => 1,
    default => ($ENV{'LXSUITE_KEY'} // ''));

sub _build_server {
    my $url = 'http://'.($ENV{'LXSUITE_SERVER'} // 'localhost:10000');
    return Frontier::Client->new(url => $url, debug => 0);
}

sub process_zone {
    my ( $self, $zone ) = @_;

    my $utf8_sentence = encode('UTF-8', $zone->sentence, Encode::FB_CROAK);
    my $tokens = $self->server->call("analyse", $self->key, $utf8_sentence);

    my $a_root = $zone->create_atree();
    # create nodes
    my $i = 1;
    my @a_nodes = map { $a_root->create_child({
        "form"         => $_->{"form"},
        "ord"          => $i++,
        "lemma"        => ($_->{"lemma"} // uc $_->{"form"}),
        "conll/pos"    => $_->{"pos"},
        "conll/cpos"   => $_->{"pos"},
        "conll/feat"   => $_->{"infl"},
        "conll/deprel" => $_->{"udeprel"},
    }); } @$tokens;

    # build tree
    my @roots = ();
    while (my ($i, $token) = each @$tokens) {
        if ($token->{"form"} =~ /^\pP$/) {
            if ($i > 0 and ($token->{"space"} // "") !~ "L") {
                $a_nodes[$i-1]->set_no_space_after(1);
            }
            $a_nodes[$i]->set_no_space_after(($token->{"space"} // "") !~ "R");
        } elsif ($token->{"form"} =~ /_$/) {
            $a_nodes[$i]->set_no_space_after(1);
        }
        if ($token->{"parent"}) {
            $a_nodes[$i]->set_parent(@a_nodes[(int $token->{"parent"})-1]);
        } else {
            push @roots, $a_nodes[$i];
        }
    }

    return @roots;
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
