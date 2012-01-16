#!/usr/bin/perl -w
package Predict;
use strict;
use feature qw(say);
use AI::FANN;
use Carp qw(cluck :DEFAULT);
use Data::Dumper;

sub all{
    my ($data,$modeldir,$debug)=@_;
    my @net_files=glob("$modeldir/*.model");
    my (@networks,%predictions);

    foreach my $net (@net_files){
        my $ann = AI::FANN->new_from_file($net);
        $ann->reset_MSE;
        push @networks,$ann;
    }
    foreach my $dp (0..@$data-1) {
        $predictions{$main::todo[$dp]}=[];
        foreach my $ann (@networks){
            my ($neu,$non) = @{$ann->run(@$data[$dp])};
            my @probability=map {$_/($neu+$non)} ($neu,$non);
            push @{$predictions{$main::todo[$dp]}},\@probability;
        }
    }
    cluck ( Dumper (\%predictions) ) if $debug;
    return %predictions;
}
1;
