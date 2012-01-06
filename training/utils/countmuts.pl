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
my $totalprots=0;
my $totalmuts=0;
open (OUT,"> $outfile");
foreach my $protein (@dir){
    next unless (-e "$inputdirectory/$protein/features.arff");
    my ($n)=split(" ",`wc -l $inputdirectory/$protein/$protein.effect`);
    warn "Problem in $protein\n" unless ($n);
    $totalprots+=1;
    $totalmuts+=$n;
    print OUT "$protein\n$n\n";
}
close OUT;
print "Proteins: $totalprots\nMutations: $totalmuts\n";
