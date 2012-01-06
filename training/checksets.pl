#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Getopt::Long;
my $first=-1;
foreach my $set (@ARGV) {
    open FH,$set;
    foreach my $line (<FH>) {
        my @dp=split(/\s+/,$line);
        my $dpsize=scalar(@dp);
        $first=$dpsize and say $first if ($first==-1);
        if ($dpsize != $first) {
            next if $dpsize ==2;
            say "$set $dpsize";
        }
    }
    close FH;
}
