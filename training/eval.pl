#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Getopt::Long;
use Cwd;

my $conf=$ARGV[0];
my $dir=getcwd;

my $count=0;
my $total=0;
my @list= glob ("$dir/*");
foreach my $set (@list){
    next unless -e "$set/$conf/nntrain.result";
    open RES,"$set/$conf/nntrain.result";
    my ($aucs)= grep /ctrain_aucs/, <RES>;
    close RES;
    my ($du,$q2,$du2)=split /\s+/,$aucs;
    die "$q2 in $set/$conf/nntrain.result" unless $q2=~ m/(\d+\.\d+)/;
    $total += $q2;
    $count++;
}
print $total/$count . " (Averaged over $count networks)\n";
