#!/usr/bin/env perl

use strict;
use warnings;

use Treex::Core::Common;

use TranslationModel::Factory;
#use TranslationModel::MaxEnt::FeatureExtractor::EN2CS;

use Getopt::Long;
use Carp;
use File::Temp qw/tempdir/;

########################## PARAMS #############################

my $USAGE = <<"USAGE_END";

Usage: $0 [ flags ] <model_type=static|maxent|vw> <resulting_model_path>
Flags: 
\t-i, --instances=NUM\t\tmaximum instances per source label (e.g. en_lemma) (default = 1000)
\t-m, --min_instances=NUM\t\tminimum instances per source label (models with lower count are not learnt) (default = 2)
\t--class_coverage=NUM\t\tfilter instances with rare target labels; at most this proportion of instances will remain; >1 => no filtering (default = 0.9)
\t--min_per_class=NUM\t\tfilter instances with rare target labels; specifies the exact minimum value (default = 1)
\t-l, --values_file=FILE\t\tpath to a file with a list of source labels, for which do not train a model
\t-f, --feature_cut=NUM\t\tommit features with a number of occurences lower than this (default = 2)
\t-w, --feature_weight_cut=NUM\t\tommit features with the absolute value of its weight lower than this (default = no-cut)
\t-p, --learner_params=STR\tparameters for inner learners in a format 'param1 val1 param2 val2'
\t-s, --source_column=NUM\t\tindex of the column with source labels (default = 0)
\t-t, --target_column=NUM\t\tindex of the column with target labels (default = 1)
\t--feature_column=NUM\t\tindex of the column with features (default = 2)
USAGE_END

my $max_instances = 1000;
my $min_instances = 2;
my $class_coverage = 0.9;
my $min_per_class = 1;
my $feature_cut = 2;
my $feature_weight_cut = undef;
my $lowercase = 0;
my $remove_target = 0;
my $value_list_path = undef;
my $source_column = 0;
my $target_column = 1;
my $feature_column = 2;
my $learner_param_str = undef;
my $tmp_dir = "/tmp";

GetOptions(
    "instances|i=i" => \$max_instances,
    "values_file|l=s" => \$value_list_path,
    "lowercase|c" => \$lowercase,
    "min_instances|m=i" => \$min_instances,
    "class_coverage=f" => \$class_coverage,
    "min_per_class=i" => \$min_per_class,
    "feature_cut|f=i" => \$feature_cut,
    "feature_weight_cut|w=f" => \$feature_weight_cut,
    "remove_target|r=i" => \$remove_target,
    "source_column|s=i" => \$source_column,
    "target_column|t=i" => \$target_column,
    "feature_column=i" => \$feature_column,
    "learner_params|p=s" => \$learner_param_str,
    "tmp_dir|s" => \$tmp_dir,
);

if (@ARGV < 2) {
    log_fatal $USAGE;
}
my $model_type = shift @ARGV;
my $modelfile = shift @ARGV;

$tmp_dir = tempdir("$tmp_dir/tectomt_tm_train_XXXXX", CLEANUP => 1);
my $tmp_fp = "$tmp_dir/input.gz";
open my $tmp_fh, ">:gzip::encoding(UTF8)", $tmp_fp;

my $INFO = <<"INFO_END";
Training $model_type model
\ttmp file:\t$tmp_fp
\tinstances:\t$max_instances
\tmin instances:\t$min_instances
\tclass_coverage:\t$class_coverage
\tmin_per_class:\t$min_per_class
INFO_END
# not yet supported for VW
if ($model_type ne 'static') {
    $INFO .= "\tfeature_cut:\t" . int($feature_cut) . "\n";
    $INFO .= "\tfeature_weight_cut:\t" . $feature_weight_cut . "\n";
    $INFO .= "\tlearner_params:\t" . $learner_param_str . "\n";
}
$INFO .= <<"INFO_END";
\ttarget_column:\t$target_column
\tsource_column:\t$source_column
INFO_END
if ($model_type ne 'static') {
    $INFO .= "\tfeature_column:\t" . int($feature_column) . "\n";
    $INFO .= "\tremove_target:\t" . int($remove_target) . "\n";
}
$INFO .= "\tlowercase:\t" . int($lowercase) . "\n";
$INFO .= "\n";

log_info $INFO;


##################################################################

my %permit_values = ();
if (defined $value_list_path) {
    open my $VALUES, "<:gzip:encoding(UTF8)", $value_list_path or croak "File $value_list_path does not exist";
    while (<$VALUES>) {
        chomp $_;
        my ($val, $count) = split /\s+/, $_;
        $permit_values{$val}++;
    }
    close $VALUES;
}

binmode STDIN,":encoding(UTF8)";

my $learner_params = {
    min_instances => $min_instances,
    max_instances => $max_instances,
    min_per_class => $min_per_class,
# non-static params
    feature_cut => $feature_cut,
};
if (abs($class_coverage) <= 1) {
    $learner_params->{class_coverage} = abs($class_coverage);
}
if (defined $feature_weight_cut) {
    $learner_params->{feat_weight_cut} = $feature_weight_cut;
}
if (defined $learner_param_str) {
    $learner_params->{params} = { split / /, $learner_param_str };
}

log_info "Counting input labels...";

my %input_counts = ();
my $idx = 0;
while (<>) {
print $tmp_fh $_;
chomp;
    my @p = split /\t/, $_;
    my $input = $p[$source_column];
    $input_counts{$input}++;
    if ($idx % 100000 == 0) {
        print STDERR "$input\n";
    }
    $idx++;
}
close $tmp_fh;

$learner_params->{input_counts} = \%input_counts;

my $model_factory = TranslationModel::Factory->new();
my $learner = $model_factory->create_learner($model_type, $learner_params);

open $tmp_fh, "<:gzip:encoding(UTF8)", $tmp_fp || die $!;
while (<$tmp_fh>) {
    chomp;
    my @p = split /\t/, $_;
    my ($input, $output, $features) = ($p[$source_column], $p[$target_column], $p[$feature_column]);

    if ((!defined $value_list_path) || $permit_values{$input}) {
        $output = $lowercase ? lc($output) : $output;
        my @feature_list = ();
        if (defined $features) {
            @feature_list = split / /, $features;
        }
        if ( $remove_target ) {
            #$features =~ s/TRG_[^ ]+ ?//g;
            @feature_list = grep {$_ !~ /^TRG_/} @feature_list;
        }
        # remove alignment features
#        print STDERR "A: ", $features, "\n";
        @feature_list = grep {$_ !~ /^ali_/} @feature_list;
        #$features =~ s/ali_[^ ]+=1 ?//g;
        #print STDERR "B: ", $input, "\t", $output, "\t", $features, "\n";
        $learner->see($input, $output, \@feature_list);
    }
    else {
        print STDERR "Skipping training for $input\n";
    }
}
close $tmp_fh;

my $model = $learner->get_model;

$model->save($modelfile);
