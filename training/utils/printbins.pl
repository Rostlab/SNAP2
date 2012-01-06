#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Getopt::Long;

my $prediction=$ARGV[0];
open PRED,$prediction or die "No such file: $prediction";
my @preds=<PRED>;
close PRED;
chomp @preds;
my %bins;
foreach (-11..11){
    $bins{$_}=0;
}

foreach (@preds){
    $bins{int(10*$_)}++;
    if (int(10*$_)==0){
        if ($_>0){
         $bins{11}++;
        }
        elsif ($_<0){
            $bins{-11}++;
        }
    }
}
foreach (-11..11){
    print "$_ $bins{$_}\n";
}
