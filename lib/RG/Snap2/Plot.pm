#!/usr/bin/perl -w
package RG::Snap2::Plot;
use strict;
use feature qw(say);
use Getopt::Long;
use GD::Graph::lines;

sub from_file{
    my ($name,$out,$sequence_array,@files)=@_;
    my @plotdata;
    push @plotdata,$sequence_array;
    
    foreach my $file (@files) {
        my $avg=0;
        my @avgpred;
        open FILE,$file or die "No such file: $file";
        my @file_cont=grep(/Sum/,<FILE>);
        close FILE;
        chomp @file_cont;
        die "No collection line found" if scalar(@file_cont) == 0;
        die "Inconsistent number of lines: found ".scalar(@file_cont)." lines when expecting ".(19*scalar(@$sequence_array))."\n" if (19*scalar(@$sequence_array))!=scalar(@file_cont);
        for (my $i=1; $i<=scalar(@file_cont);$i++){
            my @line=split /\s+/,$file_cont[$i-1];
            if ($i % 19 != 0){
                $avg+=$line[scalar(@line)-1];
            }
            else{
                $avg+=$line[scalar(@line)-1];
                push @avgpred,int($avg/19);
                $avg=0;
            }
        }
    push @plotdata,\@avgpred;
    }
    _plot($name,\@plotdata,2560,1440,$out);
}

sub from_prediction{
    my ($name,$sequence_array,$predictions,$out,$debug)=@_;
    my @plotdata;
    push @plotdata,$sequence_array;
    my @avgpred;
    my $avg=0;

    foreach my $data_point (1..@$predictions) {
        my ($neu,$non)=qw(0 0);
        foreach my $network (@{$$predictions[$data_point-1]}) {
            $neu+=$$network[0];
            $non+=$$network[1];
        }
        if ($data_point % 19 != 0){
            $avg+=100*($neu-$non)/scalar(@{$$predictions[0]});
        }
        else {
            $avg+=100*($neu-$non)/scalar(@{$$predictions[0]});
            push @avgpred,int($avg/19);
            $avg=0;
        }
        my $ri=$neu-$non;
        
    }
    push @plotdata,\@avgpred;
    _plot($name,\@plotdata,2560,1440,$out);
}

sub _plot{
    my ($name,$plotdata,$width,$height,$out)=@_;
    my $graph = GD::Graph::lines->new($width, $height);
    $graph->set( 
        x_label           => 'Residues',
        x_label_position => 0.5,
        x_all_ticks => 1,
        y_label           => 'Effect',
        title             => "In Silico Mutagenesis of $name",
        y_max_value       => 100,
        y_min_value    => -100,
        zero_axis_only => 1,
        transparent => 0,
        bgclr => "white",
        y_tick_number     => 10,
        y_label_skip      => 1 
    ) or die $graph->error;
    $graph->set_x_label_font(['verdana', 'arial'],18);
    my $gd = $graph->plot($plotdata) or die $graph->error;
    open(IMG, ">$out.png") or die $!; 
    binmode IMG;
    print IMG $gd->png;
    close IMG;
}
1;
