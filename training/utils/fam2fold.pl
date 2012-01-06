#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Getopt::Long;

our($fam,$fold,$out);

my $args_ok=GetOptions( 'fam=s'    =>  \$fam,
                        'fold=s'    =>  \$fold,
                        'out=s'    =>  \$out 
);
sub die_usage{
    my $msg=shift;
    say "\nDESCRIPTION:\n";
    say "\nUSAGE:\n";
    say "\nOPTIONS:\n--fam\n\tfamily set config file\n--fold\n\tfold set config file\n--out\n\toutput file\n";
    die $msg;
}
my %famhash;
my %mapping;
my %foldhash;
my $currentfold;
my $currentfam;
open FOLD,$fold or die_usage("could not open fold set config");
foreach my $line (<FOLD>) {
    next if $line=~/^\s+/o;
    if ($line=~/^Fold:\s(\d+)$/){
        $currentfold=$1;
    }
    else {
        chomp $line;
        $foldhash{$line}=$currentfold; 
    }
}
close FOLD;
open FAM,$fam or die_usage("could not open familiy set config file");
foreach my $line (<FAM>) {
    next if $line=~/^\s+/o;
    if ($line=~/^Fold:\s(\d+)$/) {
        $currentfam=$1;
    }
    else {
        chomp $line;
        my $map=$foldhash{$line};
        $mapping{$currentfam}=$map unless $mapping{$currentfam};
        if ($mapping{$currentfam} ne $map) {
            say "found inconsitency: '$line' was mapped to fold $map and $mapping{$currentfam}";
        }
    }
}
close FAM;
open OUT,">$out" or die_usage("Could not write output file");
while (my ($k,$v) = each %mapping ) { 
    print "Family $k => $v\n"; 
    print OUT "$k $v\n";
}
close OUT;
