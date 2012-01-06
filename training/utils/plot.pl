#!/usr/bin/perl -w
#--------------------------------------------------
# desc:     Uses gnuplot to draw a lineplot of
#           one or more input files using several 
#           columns.
#
# author:   hoenigschmid@rostlab.org
#-------------------------------------------------- 
use strict;
use feature qw(say);

#--------------------------------------------------
# Open gnuplot 
#-------------------------------------------------- 
open GP, "| gnuplot -persist" or die "Could not find gnuplot binary...\n";
select GP;
$|++;

my @files;
my @cols;

my @col_tmp;
my $params = "w lines";
my $outfile;

my %opts = (xlabel => "epoch",
            ylabel => "Q3",
            term => "png",
            output => "./out.png",
            title   => "Q3 on train-, valid-, testsets" );

#--------------------------------------------------
# Gather files, columns and opts
#-------------------------------------------------- 
foreach my $arg (@ARGV) {
    if (-e $arg) {
            push @files, $arg;
    }
    elsif ($arg =~ /^-/) {
        my $sstr = substr $arg, 1;
        my ($k, $v) = split /=/, $sstr;
        
        $opts{$k} = $v;
    }
    else {
        push @col_tmp, $arg;
        if (scalar @col_tmp == 2) {
                push @cols, [@col_tmp];
                @col_tmp = ();
        }
    }
}

my $script = "";

while (my ($k, $v) = each %opts) {
    if ($v) {
        $script .= "set $k \"$v\";";
    }
    else {
        $script .= "set $k;";
    }
}

$script .= "plot ";
foreach my $file (@files) {
	foreach my $col (@cols) {
		$script .= "\"$file\" using " . (join ':', @$col) . " $params, ";
	}
}

$script =~ s/, $/;/;

say $script;

close GP;
