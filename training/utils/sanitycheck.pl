#!/usr/bin/perl
use strict;
use warnings;
use Cwd 'abs_path';
my $inputdirectory=$ARGV[0];
$inputdirectory=Cwd::realpath($inputdirectory);
my $failcnt=0;
#print "'$inputdirectory' \n";
opendir(my $in,$inputdirectory);
my @dir=readdir($in);
my $test;
foreach my $protein (@dir){
    next if $protein=~/^\./;
    my $invalid=0;
    if (open (PSIC, "$inputdirectory/$protein/query.psic")){
         $test= <PSIC>;
         $invalid=1 if $test=~/hits/;
    close PSIC;}
    else {$invalid=1};
    unless (-e "$inputdirectory/$protein/features.arff"){print "No mutationfile in $protein\n"; $failcnt++;}
    elsif ($invalid){print "removed mutationfeatures for $protein - ". `rm $inputdirectory/$protein/features.arff`."\n"}
}
print "Failed: $failcnt\n";
