#!/usr/bin/env perl

use warnings;
use strict;
use utf8;
use autodie;
binmode STDOUT, ':encoding(utf8)';

use String::Diff;
use Term::ANSIColor;
use Getopt::Long;
use Carp;

my ($NO_COLOR, $HIDE_ZERO, $HTML, $title) = (0, 0, 0, "");

GetOptions(
    'no_color' => \$NO_COLOR,
    'hide_zero' => \$HIDE_ZERO,
    'html' => \$HTML,
    'title' => \$title
);

my %MARKUP = (
    'remove_open' => ['on_red', '<span style="color: red">'],
    'remove_close' => ['reset', '</span>'],
    'append_open' => ['on_green', '<span style="color: green">'],
    'append_close' => ['reset', '</span>'],
    'src_open' => ['blue bold', '<span style="color: blue; font-weight: bold">'],
    'src_close' => ['reset', '</span>'],
    'ref_open' => ['yellow', '<span style="color: orange;">'],
    'ref_close' => ['reset', '</span>'],
    'tred_open' => ['blue', '<span style="color: blue;">'],
    'tred_close' => ['reset', '</span>'],
    'diff_open' => ['blue', '<span style="color: blue;">'],
    'diff_close' => ['reset', '</span>'],
    'end' => ['reset', ''],
);

my $input_file1 = shift;
my $input_file2 = shift;

my ($base1, $base2) = ($input_file1, $input_file2);
if ($input_file1 =~ /^(tmp.*|runs.*)output.txt/ ){
    $base1 = $1;
    ($base2) = ($input_file2 =~ /^(tmp.*|runs.*)output.txt/);
}

if ( ! $title ) {
    $title = "$base1 - $base2";
}

sub c {
    return $HTML ? $_[0] :
        $NO_COLOR ? '' : color($_[0]);
}

my $total_diff = 0;
my %data;

open my $F1, '<:encoding(utf8)', $input_file1 or croak $!;
open my $F2, '<:encoding(utf8)', $input_file2 or croak $!;

while(<$F1>){
    my $id1  = $_; last if $id1 !~ /^ID/;
    my $src = <$F1>;
    my $ref = <$F1>;
    my $tst1 = <$F1>;
    my $scores1 = <$F1>; chomp $scores1;
    <$F1>;

    my $id2  = <$F2>;
    my $src2 = <$F2>; croak "$src\nis not the same as\n$src2" if $src ne $src2;
    my $ref2 = <$F2>; croak "$ref\nis not the same as\n$ref2" if $ref ne $ref2;
    my $tst2 = <$F2>;
    my $scores2 = <$F2>; chomp $scores2;
    <$F2>;

    # Takove udelatko, aby si clovek mohl rychle zobrazit vety, ktere ho zajimaji
    if ($base1 && $base2 && $id1 =~ /^(.*)\(([^)]*)\)/){
        my ($id,$file1) = ($1,$2);
        my ($file2) = ($id2 =~ /\(([^)]*)\)/);
        $id1 = "$id\n" .
            c($MARKUP{'tred_open'}->[$HTML])."ttred ${base1}treexfiles/$file1 & " . c($MARKUP{'tred_close'}->[$HTML]). "\n".
            c($MARKUP{'tred_open'}->[$HTML])."ttred ${base2}treexfiles/$file2 & " . c($MARKUP{'tred_close'}->[$HTML]). "\n";
    }

    my @s1 = split / /, $scores1;
    my @s2 = split / /, $scores2;
    my $diff = 0;
    foreach my $i (0 .. 3) {
        $diff += $s1[$i] - $s2[$i];
    }
    if (($HIDE_ZERO && $diff) || (!$HIDE_ZERO && $tst1 ne $tst2) ){
        $total_diff += $diff;
        $data{$id1} = [$diff, $src, $ref, $tst1, $tst2];
    }
}

close $F1;
close $F2;

if ( $HTML ) {
    print "<html><head><meta http-equiv='Content-Type' content='text/html; charset=utf-8' /><title>$title</title></head><body><pre>\n";
}

print "score(1TST=$input_file1) - score(2TST=$input_file2) = $total_diff\n";
foreach my $id (sort {$data{$b}[0] <=> $data{$a}[0]} keys %data){
    my ($diff, $src, $ref, $tst1, $tst2) = @{$data{$id}};
    my($old, $new) = String::Diff::diff( $tst1, $tst2,
      remove_open => c($MARKUP{'remove_open'}->[$HTML]),
      remove_close => c($MARKUP{'remove_close'}->[$HTML]),
      append_open => c($MARKUP{'append_open'}->[$HTML]),
      append_close => c($MARKUP{'append_close'}->[$HTML]),
    );
    print c($MARKUP{'diff_open'}->[$HTML]), "$diff $id", c($MARKUP{'diff_close'}->[$HTML]),
        c($MARKUP{'src_open'}->[$HTML]), $src, c($MARKUP{'src_close'}->[$HTML]),
        c($MARKUP{'ref_open'}->[$HTML]), $ref, c($MARKUP{'ref_close'}->[$HTML]),
        1, $old, 2, $new, "\n";
}

END { print c($MARKUP{'end'}->[$HTML]); } # just to be sure, term colors are kept unchanged

if ( $HTML ) {
    print "</pre></body></html>\n";
}
