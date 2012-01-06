#!/usr/bin/perl
use strict;
use warnings;
use Cwd 'abs_path';
my $inputdirectory=$ARGV[0];
my $outfile=$ARGV[1];
$inputdirectory=Cwd::realpath($inputdirectory);
#print "'$inputdirectory' \n";
open OUT,">$outfile" or die "failed to open output file: $outfile";
sub po{
    my $text=shift;
    print OUT "$text\n";
}
    my $invalid=0;
opendir(my $in,$inputdirectory);
my @dir=readdir($in);
foreach my $protein (@dir){
    next if $protein=~/^\.|^grid/;

    #check PSIC
    if (open (PSIC, "$inputdirectory/$protein/query.psic")){
         my $test= <PSIC>;
         if ($test=~/blastpgp: No hits found/og){
             $invalid++;
            po($protein);
            print "$protein - psic \n";
            next;
            };
    close PSIC;}
    else {po($protein);
             $invalid++;
            print "$protein - psic \n";
        next;}

    #check PFAM
    if (-e "$inputdirectory/$protein/query.hmm3pfam"){
        open PFAM,"$inputdirectory/$protein/query.hmm3pfam";
        my $cont=join("",<PFAM>);
        close PFAM;
        if ($cont=~/No hits detected that satisfy reporting thresholds/go){
             $invalid++;
            print "$protein - pfam \n";
            po($protein); next;
        }
    }
    else {
            print "$protein - pfam \n";
             $invalid++;
        po($protein); next;}

    #check SIFT
    unless (-e "$inputdirectory/$protein/query.SIFTprediction"){
             $invalid++;
            print "$protein - sift \n";
        po($protein); next;
    }

    #check SWISS
    if (-e "$inputdirectory/$protein/query.blastswiss"){
        open SWISS,"$inputdirectory/$protein/query.blastswiss";
        my $cont=join("",<SWISS>);
        close SWISS;
        if ($cont=~/No hits found/o){
            print "$protein - swiss \n";
             $invalid++;
            po($protein); next;
        }
        $cont =~ s/[^\>]+(\>[^\s\|]+\|+[^\s]+\s+[^\>]+)(\>|Database\:)//;
        unless ($cont=~/Expect = (0\.0|\d*e\-\d+)/o){
            print "$protein - swiss \n";
             $invalid++;
            po($protein); next;
        }
    } 
    else {
            print "$protein - swiss \n";
             $invalid++;
        po($protein); next;}
}
close OUT;
print "Total missing annotation: $invalid\n";
