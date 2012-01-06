#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Getopt::Long;
use List::Util qw (min max);
use List::MoreUtils qw||;
use File::Path qw(make_path);
use Cwd 'abs_path';
use Carp qw(cluck :DEFAULT);

#GetOptions( ''    =>  \,
#''    =>  \,
#''    =>  \ );
die "Usage crossval.pl <INPUT DIR> <OUTPUT DIR>\n" unless ($ARGV[0] && $ARGV[1]);
my $indir=Cwd::realpath($ARGV[0]); 
my $result=Cwd::realpath($ARGV[1]);
my $nntrain="/mnt/project/resnap/training/trunk/scripts/nntrain.pl";
   
my $temp="/tmp/hecht/$result";
my @sets=(1..10);
my @resultfolder;
my $lastset=pop(@sets);
unshift @sets,$lastset;
my @rate_and_momentum=(
    "option learning_rate 0.005\noption learning_momentum 0.1",
    "option learning_rate 0.01\noption learning_momentum 0.3",
);
for (my $var = 1; $var <= @sets; $var++) {
    my $counter=0;
    my $set=shift(@sets);
    push @sets,$set;
    my @neurons=qw(10 25 50 100); #getneurons($selectedinputs);
    foreach my $hidden (@neurons){
        foreach my $learning (@rate_and_momentum){
            $counter++;
            my $tmp=$temp."/fold_$var/$counter/";
            my $currentfolder=$result."/$var/$counter/";
            push @resultfolder,$currentfolder;
            make_path $currentfolder;
            my $training=$tmp."training";
            my $crosstraining=$tmp."crosstraining";
            my $testing=$tmp."testing";
            open CONF,">$currentfolder/nntrain.conf" or die "could not write $currentfolder/nntrain.conf";
            print CONF join("\n",
                "option hiddens $hidden",
                "$learning",
                "option max_epochs 200",
                "option wait_epochs 10",
                "option balanced_train oversampling",
                "option balanced_ctrain oversampling",
                "option measure_type aucs",
                "option out $currentfolder",
                "option trainset $training",
                "option ctrainset $crosstraining",
                "option testset $testing",
            );
            close CONF;
            open SCRIPT,">$currentfolder/buildsets.sh" or die "failed to write shell script";
            print SCRIPT "#!/bin/sh\n";
            print SCRIPT "mkdir -p $tmp\n";
            print SCRIPT "flock $temp -c 'rsync -a $indir/ $temp && touch $temp'\n";
            my @currsets= map {$temp."/$_"} @sets;
            print SCRIPT "cat ".join(" ",@currsets[0..7])." > $training\n";
            print SCRIPT "cat $currsets[8] > $crosstraining\n";
            print SCRIPT "cat $currsets[9] > $testing\n";
            print SCRIPT "source /mnt/project/resnap/.max\n";
            print SCRIPT "/mnt/project/resnap/training/trunk/scripts/nntrain.pl -config $currentfolder/nntrain.conf >/dev/null\n";
            print SCRIPT "rm -rf $tmp\n";
            close SCRIPT;
            print `qsub -o $currentfolder -e $currentfolder $currentfolder/buildsets.sh`;
       }
   }
}
