#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Getopt::Long;

my ($set,$pred)=@ARGV;
die unless $set && $pred;
my $counter=0;
my %effect;
open SET,$set or die "No set file: $set";
while (my $line=<SET>){
    $line=<SET>;
    chomp $line;
    if ($line eq "0 1"){
        $effect{$counter}=1;
    }
    elsif ($line eq "1 0"){
        $effect{$counter}=0;
    }
    else {
        die "unknown effect in: $line";
    }
    $counter++;
}
close SET;

open PRED,$pred or die "No prediction file: $pred";
my @prediction=<PRED>;
close PRED;
chomp @prediction;
my %neubins;
foreach (-10..10){
    $neubins{$_}=0;
}
my %nonbins=%neubins;
open NEU,">$pred.neu" or die "Could not write neutral file";
open NON,">$pred.non" or die "Could not wirte non-neutral file";
for (my $i = 0; $i < @prediction; $i++) {
    my ($neu,$non)=split(/\s/o,$prediction[$i]);
    my $diff=$non-$neu;
    my $bin=int(10*$diff);
    if ($effect{$i}==1){
        print NON $diff."\n";
        $nonbins{$bin}++;
    }    
    elsif ($effect{$i}==0){
        print NEU $diff."\n";
        $neubins{$bin}++;
    }
    else {
        die "something went terribly wrong";
    }
}
close NEU;
close NON;
foreach (-10..10){
    print $_ . " " .$neubins{$_} . "\n";
}
foreach (-10..10){
    print $_ . " " .$nonbins{$_} . "\n";
}
