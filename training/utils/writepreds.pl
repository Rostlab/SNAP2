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
my $siftpred=new Prediction();
my $snappred=new Prediction();
my $snap2pred=new Prediction();
my $inputdirectory=$dir;
$inputdirectory=Cwd::realpath($inputdirectory);
#print "'$inputdirectory' \n";
opendir(my $in,$inputdirectory);
my $counter=0;
my @dir=readdir($in);
foreach my $protein (@dir){
    $counter++;
    next if $protein=~/^\./o;
    #next unless exists $folds{$protein};
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
        my $observed=($effects[$mutation] == 1 ? [0,1] : [1,0]);
        my ($mutline)=grep(/$mutants[$mutation]/,@sift);
        my ($mut,$pred,$score)=split(/\s+/,$mutline);
        warn "No sift score in $protein: '$mutline" and next unless (defined $score && defined $pred && defined $mut && $pred ne "NOT");
        my ($sumline)=grep(/$mutants[$mutation].*sum/,@snap);
        warn "No snap sum in $protein: '$sumline'" and next unless $sumline;
        my @snapscore=split(/\s+/,$sumline);
        my $sscore=$snapscore[scalar(@snapscore)-1];
        my $s2score;
        if (defined $snap2[0]){
            my ($sumline)=grep(/$mutants[$mutation].*Sum/,@snap2);
            warn "No snap sum in $protein: '$sumline'" and next unless $sumline;
            my @snapscore=split(/\s+/,$sumline);
            $s2score=$snapscore[scalar(@snapscore)-1];
            $snap2pred->add([0,$s2score/100],$observed);
        }
        $snappred->add([0,$sscore],$observed);
        $siftpred->add([$score,0],$observed);
    }
    print int(100*$counter/(scalar(@dir)-4)) . " - $protein\n";
}

$snappred->write("$out.snap");
$snap2pred->write("$out.snap2");
$siftpred->write("$out.sift");
