#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Getopt::Long;

our($dir,$out,$set);

my $args_ok=GetOptions( 'dir=s'    =>  \$dir,
                        'out=s'    =>  \$out,
                        'set=s'    =>  \$set 
);

my %folds;
my $nr;
open (SETFILE,$set) || die "failed to read set file: $set";
foreach my $line (<SETFILE>){
   next if $line=~/^\s/o;
   chomp $line;
   if ($line=~/Fold: (\d+)/){
    $nr=$1;
    $folds{$1}=[] unless exists $folds{$1};
   }
   else {
    if ($nr){
    push @{$folds{$nr}},$line;}
    else{ die "protein set file is of wrong format";}
   }
}
my $size=352;
foreach my $key (keys %folds) {
    open OUT,">$out/$key";
    foreach my $protein (@{$folds{$key}}) {
        #next if $protein=~/DIRECT/o;
        open IN,"$dir/$protein/$protein.features" or next;
        my @cont=<IN>;
        #foreach my $dp (@cont) {
            #my $dpsize=scalar(split(/\s+/,$dp));
         #if ($dpsize != $size){
                #next if $dpsize==2;
                #say $protein." ".$dpsize;
                    #}
                    #    }
        print OUT join "",@cont;
        close IN;
    }
    close OUT;
}
