#!/usr/bin/perl -w
use strict;
use List::Util qw(max);
use feature qw(say);
use Getopt::Long;

our(@folds,$var2,$var3);

my $args_ok=GetOptions( 'folds=s'    =>  \@folds,
                        'var2=s'    =>  \$var2,
                        'var3=s'    =>  \$var3 
);
@folds=split(/,/,join(',',@folds));
foreach my $fold (@folds){
    my ($neutrals,$nonneutrals)=("0","0");
    open IN,$fold or die "Failed to read file: '$fold'";
    while (my $input=<IN>){
        my $output=<IN>;
        chomp($output);
        my ($neutral,$non_neutral)=split(" ",$output);
        if ($neutral==1){
            $neutrals++;
        }
        elsif ($non_neutral==1){
            $nonneutrals++;
        }
        else {
            die "something is wrong in $output\n";
        }
    }
    close IN;
    print "Neutral: $neutrals - Non-neutral: $nonneutrals\n";
    $neutrals=max($neutrals,1);
    print "Non-neutral / Neutral ratio for '$fold' = " . ($nonneutrals/$neutrals)."\n";
}
