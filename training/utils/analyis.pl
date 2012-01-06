#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Getopt::Long;

my %hash;
open IN,$ARGV[0] or die "no file";
while (<IN>){
    if ($_=~/Component:? \d+.+ (\d+).*/){
    #f ($_=~/Component \d+:
        $hash{$1}=0 unless defined $hash{$1};
        $hash{$1}++;
    }
}
close IN;
foreach (sort {$hash{$b} <=> $hash{$a}} keys %hash){
    print "$_,$hash{$_}". "\n";
}
