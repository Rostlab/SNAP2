#!/usr/bin/perl
use strict;
use warnings;
use Cwd 'abs_path';
use feature qw(say);
use Getopt::Long;
use lib glob ("/mnt/project/resnap/trunk/lib");
use Prediction;

our($dir,$out,$set);

my $args_ok=GetOptions( 'dir=s'    =>  \$dir,
                        'set=s'    =>  \$set,
                        'out=s'    => \$out
);
die "missing dir/set" unless ($dir && $set);
my %folds;
open (SETFILE,$set) || die "failed to read set file: $set";
foreach my $line (<SETFILE>){
   next if $line=~/^\s|^Fold/o;
   chomp $line;
   $folds{$line}=1;
}
my $inputdirectory=$dir;
my $total;
my $allwrong=0;
my ($snapunique,$siftunique,$snap2unique);
my $siftcorrect;
my $snapcorrect;
my $snap2correct;
my $snapsnap2agree=0;
my $snapsiftagree=0;
my $snap2siftagree=0;
$inputdirectory=Cwd::realpath($inputdirectory);
#print "'$inputdirectory' \n";
opendir(my $in,$inputdirectory);
my $counter=0;
my @dir=readdir($in);
foreach my $protein (@dir){
    $counter++;
    next if $protein=~/^\./o;
    next unless exists $folds{$protein};
    my @mutants;
    my @effects;
    open MUTS,"$inputdirectory/$protein/$protein.effect" or die "Could not open effect file for $protein";
    foreach my $line (<MUTS>) {
        chomp $line;
        my ($mut,$effect)=split(/\s+/,$line);
        die "Something wrong in $protein: '$line'" unless defined $mut && defined $effect;
        push @mutants,$mut;
        push @effects,$effect;
    }
    close MUTS;
    
    open SIFT,"$inputdirectory/$protein/$protein.SIFTprediction" or die "Could not open SIFTprediction for $protein";
    my @sift=<SIFT>;
    close SIFT;
    chomp @sift;

    open SNAP,"$inputdirectory/$protein/$protein.snapout" or die "Could not open SNAP output file for $protein";
    my @snap=<SNAP>;
    close SNAP;
    chomp @snap;

    my @snap2;
    if (-e "$inputdirectory/$protein/$protein.snap2"){
        open SNAP2,"$inputdirectory/$protein/$protein.snap2" or die "Could not open SNAP2 output file for $protein";
        @snap2=<SNAP2>;
        close SNAP2;
        chomp @snap2;
    
    }
    foreach my $mutation (0..@mutants-1) {
        my $observed=$effects[$mutation];
        my ($snap,$snap2,$sift)= qw(0 0 0);
        my ($mutline)=grep(/$mutants[$mutation]/,@sift);
        my ($mut,$pred,$score)=split(/\s+/,$mutline);
        warn "No sift score in $protein: '$mutline" and next unless (defined $score && defined $pred && defined $mut && $pred ne "NOT");
        $sift=1 if $score<0.05;
        my ($sumline)=grep(/$mutants[$mutation].*sum/,@snap);
        warn "No snap sum in $protein: '$sumline'" and next unless $sumline;
        my @snapscore=split(/\s+/,$sumline);
        my $sscore=$snapscore[scalar(@snapscore)-1];
        $snap=1 if $sscore>0;
        my $s2score;
        if (defined $snap2[0]){
            my ($sumline)=grep(/$mutants[$mutation].*Sum/,@snap2);
            warn "No snap2 sum in $protein: '$sumline'" and next unless $sumline;
            my @snapscore=split(/\s+/,$sumline);
            $s2score=$snapscore[scalar(@snapscore)-1];

        }
        $snap2=1 if $s2score > 8;
        if ($snap == $snap2 && $snap == $sift){
            $allwrong++ if $snap != $effects[$mutation];
            next}
        print "Sift: $sift - $score | Snap: $snap - $sscore | Snap2: $snap2 - $s2score | Effect: $effects[$mutation]\n";
        $siftcorrect++ if $effects[$mutation] == $sift;
        $snapcorrect++ if $effects[$mutation] == $snap;
        $snap2correct++ if $effects[$mutation] == $snap2;
        if ($snap == $effects[$mutation] && $snap2 == $effects[$mutation]){
            $snapsnap2agree++;
        }
        elsif ($sift == $effects[$mutation] && $snap2 == $effects[$mutation]){
            $snap2siftagree++;
        }
        elsif ($snap == $effects[$mutation] && $sift == $effects[$mutation]){
            $snapsiftagree++;
        }
        $snapunique++ if ($sift != $effects[$mutation] && $snap2 != $effects[$mutation]);
        $snap2unique++ if ($sift != $effects[$mutation] && $snap != $effects[$mutation]);
        $siftunique++ if ($snap != $effects[$mutation] && $snap2 != $effects[$mutation]);
        $total++;
    }
#    print int(100*$counter/(scalar(@dir)-4)) . " - $protein\n";
}
print "Sift: $siftcorrect correct, $siftunique unique out of $total\n";
print "Snap: $snapcorrect correct, $snapunique unique out of $total\n";
print "Snap2: $snap2correct correct, $snap2unique unique out of $total\n";
print "Cases where Snap and Snap2 agree: $snapsnap2agree\n";
print "Cases where Snap and SIFT agree: $snapsiftagree\n";
print "Cases where Snap2 and SIFT agree: $snap2siftagree\n";
print "Cases were all methods are wrong: $allwrong\n";

