#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Getopt::Long;
use lib glob( "/mnt/project/resnap/trunk/plots/");
use lib glob( "/mnt/project/resnap/trunk/training/");
use Prediction;
use GD::Graph::lines;
use GD::Graph::linespoints;
use List::MoreUtils qw{pairwise};

our($in,$plot);

my $args_ok=GetOptions( 'in=s'    =>  \$in,
                        'plot=s'    => \$plot
);
die "No input file given" unless $in;
my $p=Prediction->new_from_file($in);
my $data=[];
my $pr_data=[];
my $threshold_data=[];
my $best_threshold=$p->best_threshold(-0.99,0.99,0.01,$threshold_data);
my $measure=$p->measure();
my @descriptors=(
    "Q2",
    "Non-neutral accuracy / Positive predictive value (PPV) / Precision",
    "Non-neutral coverage / Sensitivity / Recall",
    "Neutral accuracy / Negative predictive value (NPV)",
    "Neutral coverage / Specificity");
my @values=$p->measures(0);
say "\nAt threshold 0.00:\n" . join "\n",pairwise {"$a: $b"} @descriptors,@values;
@values=$p->measures($best_threshold);
say "\nAt best threshold $best_threshold:\n" . join "\n",pairwise {"$a: $b"} @descriptors,@values;
say join " ","ROC AUCs",$measure->aucs($data);
say join " ","PR AUCs",$measure->pr_aucs($pr_data);
my $ri_data=[];
$p->reliabilities(0,0.9,0.1,$best_threshold,$ri_data);
if ($plot){
    roc_plot($data,800,600,$plot."_ROC");
    neg_pr_plot($pr_data,800,600,$plot."_neg_PR");
    pos_pr_plot($pr_data,800,600,$plot."_pos_PR");
    threshold_plot($threshold_data,800,600,$plot."_thresholds");
    ri_plot($ri_data,800,600,$plot."_reliabilities");
}

sub ri_plot{
    my ($data,$width,$height,$out)=@_;
    my $graph = GD::Graph::linespoints->new($width, $height);
    $graph->set_legend("Non-neutral accuracy","Non-neutral coverage","Neutral accuracy","Neutral coverage");
    $graph->set( 
        x_label           => "Percentage of predictions with RI >= n",
        x_label_position => 0.5,
        title             => "Performance by reliability",
        x_labels_vertical => 1,
        y_max_value       => 1,
        y_min_value    => 0.7,
        transparent => 0,
        bgclr => "white",
        y_tick_number     => 100,
        dclrs => [ qw(red lred blue lblue) ]
    ) or die $graph->error;
    $graph->set_x_label_font(['verdana', 'arial'],18);
    my $gd = $graph->plot($data) or die $graph->error;
    open(IMG, ">$out.png") or die $!; 
    binmode IMG;
    print IMG $gd->png;
    close IMG;
}
sub threshold_plot{
    my ($data,$width,$height,$out)=@_;
    my $graph = GD::Graph::lines->new($width, $height);
    $graph->set_legend("Q2","Non-neutral accuracy","Non-neutral coverage","Neutral accuracy","Neutral coverage");
    $graph->set( 
        x_label           => "Threshold",
        x_label_position => 0.5,
        title             => "Threshold Analysis",
        y_max_value       => 1,
        y_min_value    => 0,
        x_labels_vertical => 1,
        transparent => 0,
        bgclr => "white",
        y_tick_number     => 100,
        x_label_skip => 3,
        dclrs => [ qw(lred green lgreen blue lblue) ]
    ) or die $graph->error;
    $graph->set_x_label_font(['verdana', 'arial'],18);
    my $gd = $graph->plot($data) or die $graph->error;
    open(IMG, ">$out.png") or die $!; 
    binmode IMG;
    print IMG $gd->png;
    close IMG;
}
sub pos_pr_plot{
    my ($data,$width,$height,$out)=@_;
    my @plotdata;
    my @xaxis;
    my @yaxis;
    foreach my $dp (@{$data->[1]}) {
        push @yaxis,$$dp[0];
        push @xaxis,sprintf("%.2f",$$dp[1]);
    }
    push @plotdata,\@xaxis,\@yaxis;
    my $graph = GD::Graph::lines->new($width, $height);
    $graph->set( 
        x_label           => "Recall",
        x_label_position => 0.5,
        y_label           => "Precision",
        title             => "Precision/Recall (non-neutral)",
        y_max_value       => 1,
        y_min_value    => 0,
        x_labels_vertical => 1,
        transparent => 0,
        bgclr => "white",
        y_tick_number     => 10,
        x_label_skip      => 1000 
    ) or die $graph->error;
    $graph->set_x_label_font(['verdana', 'arial'],18);
    my $gd = $graph->plot(\@plotdata) or die $graph->error;
    open(IMG, ">$out.png") or die $!; 
    binmode IMG;
    print IMG $gd->png;
    close IMG;
}
sub neg_pr_plot{
    my ($data,$width,$height,$out)=@_;
    my @plotdata;
    my @xaxis;
    my @yaxis;
    foreach my $dp (@{$data->[0]}) {
        push @yaxis,$$dp[0];
        push @xaxis,sprintf("%.2f",$$dp[1]);
    }
    push @plotdata,\@xaxis,\@yaxis;
    my $graph = GD::Graph::lines->new($width, $height);
    $graph->set( 
        x_label           => "Recall",
        x_label_position => 0.5,
        y_label           => "Precision",
        title             => "Precision/Recall (neutral)",
        y_max_value       => 1,
        y_min_value    => 0,
        x_labels_vertical => 1,
        transparent => 0,
        bgclr => "white",
        y_tick_number     => 10,
        x_label_skip      => 1000 
    ) or die $graph->error;
    $graph->set_x_label_font(['verdana', 'arial'],18);
    my $gd = $graph->plot(\@plotdata) or die $graph->error;
    open(IMG, ">$out.png") or die $!; 
    binmode IMG;
    print IMG $gd->png;
    close IMG;
}
sub roc_plot{
    my ($data,$width,$height,$out)=@_;
    my @plotdata;
    my @xaxis;
    my @yaxis;
    foreach my $dp (@{$data->[0]}) {
        push @yaxis,$$dp[0];
        push @xaxis,sprintf("%.2f",$$dp[1]);
    }
    push @plotdata,\@xaxis,\@yaxis;
    my $graph = GD::Graph::lines->new($width, $height);
    $graph->set( 
        x_label           => "FPR",
        x_label_position => 0.5,
        y_label           => "TPR",
        title             => "ROC-curve",
        y_max_value       => 1,
        y_min_value    => 0,
        x_labels_vertical => 1,
        transparent => 0,
        bgclr => "white",
        y_tick_number     => 10,
        x_label_skip      => 1000 
    ) or die $graph->error;
    $graph->set_x_label_font(['verdana', 'arial'],18);
    my $gd = $graph->plot(\@plotdata) or die $graph->error;
    open(IMG, ">$out.png") or die $!; 
    binmode IMG;
    print IMG $gd->png;
    close IMG;
}
