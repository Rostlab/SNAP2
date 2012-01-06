#!/usr/bin/perl
use strict;
use warnings;
use Cwd 'abs_path';
my $inputdirectory=$ARGV[0];
my $outfile=$ARGV[1];
$inputdirectory=Cwd::realpath($inputdirectory);
#print "'$inputdirectory' \n";
opendir(my $in,$inputdirectory);
my @dir=readdir($in);
open (OUT,"> $outfile");
foreach my $protein (@dir){
    next unless (-e "$inputdirectory/$protein/$protein.sequence");
    open (IN,"$inputdirectory/$protein/$protein.sequence");
    my $seq=<IN>;
    close IN;
    print OUT ">$protein\n$seq";
}
close OUT;
