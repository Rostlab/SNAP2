#! /usr/bin/perl -w
use strict;
use warnings;

my $inputdirectory=$ARGV[0];

opendir(my $in,$inputdirectory);
my @dir=readdir($in);
my $dirsize=scalar(@dir)-2;
my $counter=0;
my $minsum=0;
my $seksum=0;
my $max=0;
my $min=999;
my $failcount=0;
foreach my $file (@dir) {
    next if $file=~/^\./o;
    open FH,"$inputdirectory/$file" or die "failed to open $file";
    my ($real) = grep /real/, <FH>;
    next unless ($real);
	$counter++;
	$real =~ /.*?(\d*)m(\d*)\..*/;
	$minsum+=$1;
	$seksum+=$2;
	if ($1>$max) {$max=$1};
	if ($1<$min) {$min=$1};
	}
my $totaltime=$minsum+($seksum/60);
my $avg=$totaltime/$counter;
print "Total runtime on $counter successful hhblits: $totaltime\n";
print "Average runtime per sequence: ".($totaltime/$counter)."\n";
print "Longest runtime: $max\n";
print "Shortest runtime: $min\n";
print "$failcount hhblits runs failed\n";
