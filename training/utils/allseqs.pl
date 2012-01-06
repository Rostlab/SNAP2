#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Getopt::Long;
use Cwd qw(abs_path);

my $dir=$ARGV[0];
my $outfile=$ARGV[1];
$dir=Cwd::realpath($dir);
my @folders = glob "$dir/*";
open OUT,">$outfile" or die "could not write output file";
my $c=0;
foreach my $folder (@folders) {
    $c++;
    next unless -e "$folder/features.arff";
    $folder=~/.*\/(.*)$/o;
    my $name=$1;
    open SEQ,"$folder/$name.sequence" or die "no sequence file in $name";
    my @seq=<SEQ>;
    close SEQ;
    chomp @seq;
    shift @seq if $seq[0]=~/>/o;
    my $sequence=join("",@seq);
    $sequence=~s/\s+//go;
    say OUT ">$name\n$sequence";
    say $c/scalar(@folders); 
}
close OUT;
