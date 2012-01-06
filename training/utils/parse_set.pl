#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Getopt::Long;

our($in,$out,$var3);

my $args_ok=GetOptions( 'in=s'    =>  \$in,
                        'out=s'    =>  \$out,
                        'var3=s'    =>  \$var3 
);

my $counter=0;
open IN,$in or die "Could not open $in";
foreach my $line (<IN>) {
    my ($seq,$mut,$snap,$sift,$source)=split(",",$line);
    print "$seq,$mut\n";
}
close IN;
