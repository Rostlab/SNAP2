package Prediction;

use strict;
use warnings;
use feature qw(say);
use Carp;
use Measure;
use List::Util qw(max);

sub new {
    my ($class) = @_;

    my $self = {
        predictions  => [],
        labels => [],
        dim => -1,
        measure => 0
    };

    bless $self, $class;
    return $self;
}
sub new_from_file{
    my ($class, $file) = @_;

    my $self = {
        predictions  => [],
        labels => [],
        dim => -1,
        measure => 0
    };
    bless $self, $class;
    $self->parse($file);
    return $self;
}
sub parse{
    my ($self,$file)=@_;
    open IN,$file or confess "No such file: $file";
    while (my $pred=<IN>){
        chomp $pred;
        my @dp=split /\s+/,$pred;
        $self->{dim}=scalar(@dp) if $self->{dim}==-1;
        confess "Inconsistent number of prediction states" if $self->{dim} != scalar(@dp); 
        push @{$self->{predictions}},\@dp;
        
        my $label=<IN>;
        chomp $label;
        my @lab=split /\s+/,$label;
        confess "Inconsistent number of label states" if $self->{dim} != scalar(@lab);
        push @{$self->{labels}},\@lab;
    }
    close IN;
    $self->init_measure();
}
sub init_measure{
    my $self=shift;
    confess "No data points available" if $self->{dim}==-1;
    confess "Inconsistent number of labels and predictions" if scalar(@{$self->{predictions}}) != scalar(@{$self->{labels}});
    my $measure=new Measure($self->{dim});
    foreach my $i (0..@{$self->{predictions}}-1) {
        $measure->add($self->{labels}[$i],$self->{predictions}[$i]);
    }
    $self->{measure}=\$measure;

}
sub measure{
    my $self=shift;
    $self->init_measure() unless $self->{measure};
    return ${$self->{measure}};
}

sub write{
    my ($self,$file)=@_;
    confess "Inconsistent number of labels and predictions" if scalar(@{$self->{predictions}}) != scalar(@{$self->{labels}});
    open OUT,">$file" or confess "Failed to write file: $file";
    foreach my $i (0..scalar(@{$self->{predictions}})-1) {
        say OUT join " ",@{$self->{predictions}[$i]};
        say OUT join " ",@{$self->{labels}[$i]};
    }
    close OUT;
}
sub add{
    my ($self,$pred,$lab)=@_;
    $self->add_pred($pred);
    $self->add_label($lab);
}
sub add_pred{
    my ($self,$pred) = @_;
    $self->{dim}=scalar(@$pred) if $self->{dim}==-1;
    confess "Inconsistent number of prediction states" if $self->{dim} != scalar(@$pred);
    push @{$self->{predictions}},$pred;
}
sub add_label{
    my ($self,$lab) = @_;
    $self->{dim}=scalar(@$lab) if $self->{dim}==-1;
    confess "Inconsistent number of label states" if $self->{dim} != scalar(@$lab);
    push @{$self->{labels}},$lab;
}
sub predictions{
    my $self=shift;
    return @{$self->{predictions}};
}
sub labels{
    my $self=shift;
    return @{$self->{labels}};
}
sub measures{
    my ($self,$threshold)=@_;
    my $total=scalar( $self->predictions() );
    confess "Inconsistent number of labels and predictions" if $total != scalar($self->labels());
    my $tp=0;
    my $fp=0;
    my $tn=0;
    my $fn=0;
    foreach my $i (0..$total-1) {
        my $sum = $self->{predictions}[$i][1] - $self->{predictions}[$i][0];
        my $pred=0;
        $pred=1 if $sum > $threshold;

        #true
        #positives
        if ($pred == 1 && $self->{labels}[$i][1] == 1){
            $tp++;
        }
        #negatives
        elsif ($pred == 0 && $self->{labels}[$i][1] == 0){
            $tn++;
        }
        #false
        #positives
        elsif ($pred == 1 && $self->{labels}[$i][1] == 0){
            $fp++;
        }
        #negatives
        elsif ($pred == 0 && $self->{labels}[$i][1] == 1){
            $fn++;
        }
        else { die "failed to build confusion matrix" }
    }
    my $q2=($tp+$tn)/$total;   #Overall Two-state accuracy
    my $acc_non=$tp/max(1,($tp+$fp)); #Non-neutral accuracy = Positive predictive value = Precision
    my $cov_non=$tp/max(1,($tp+$fn)); #Non-neutral coverage = Sensitivity = Recall
    my $acc_neu=$tn/max(1,($tn+$fn)); #Neutral accuracy = Negative predictive value
    my $cov_neu=$tn/max(1,($tn+$fp)); #Neutral coverage = Specificity
    #say join " ", $q2,$acc_non,$cov_non,$acc_neu,$cov_neu;
    return $q2,$acc_non,$cov_non,$acc_neu,$cov_neu;
}
sub at_ri{
    my ($self,$ri,$threshold)=@_;
    my $total=scalar( $self->predictions() );
    confess "Inconsistent number of labels and predictions" if $total != scalar($self->labels());
    my $tp=0;
    my $fp=0;
    my $tn=0;
    my $fn=0;
    my $count=0;
    foreach my $i (0..$total-1) {
        my $sum = $self->{predictions}[$i][1] - $self->{predictions}[$i][0];
        next if abs($sum)<$ri;
        $count++;
        my $pred=0;
        $pred=1 if $sum > $threshold;

        #true
        #positives
        if ($pred == 1 && $self->{labels}[$i][1] == 1){
            $tp++;
        }
        #negatives
        elsif ($pred == 0 && $self->{labels}[$i][1] == 0){
            $tn++;
        }
        #false
        #positives
        elsif ($pred == 1 && $self->{labels}[$i][1] == 0){
            $fp++;
        }
        #negatives
        elsif ($pred == 0 && $self->{labels}[$i][1] == 1){
            $fn++;
        }
        else { die "failed to build confusion matrix" }
    }
    my $acc_non=$tp/max(1,($tp+$fp)); #Non-neutral accuracy = Positive predictive value = Precision
    my $cov_non=$tp/max(1,($tp+$fn)); #Non-neutral coverage = Sensitivity = Recall
    my $acc_neu=$tn/max(1,($tn+$fn)); #Neutral accuracy = Negative predictive value
    my $cov_neu=$tn/max(1,($tn+$fp)); #Neutral coverage = Specificity
    return $count/$total,$acc_non,$cov_non,$acc_neu,$cov_neu;
}
sub reliabilities{
    my ($self,$min,$max,$step,$threshold,$data)=@_;
    for (my $ri = $min; $ri <=$max; $ri+=$step) {
        my ($perc,$acc_non,$cov_non,$acc_neu,$cov_neu)=$self->at_ri($ri,$threshold);
        #print "$perc - $acc_non\n";
        if (defined $data){
            push @{$data->[0]},sprintf("%.2f",$perc);
            push @{$data->[1]},$acc_non;
            push @{$data->[2]},$cov_non;
            push @{$data->[3]},$acc_neu;
            push @{$data->[4]},$cov_neu;
        }
    }
}
sub best_threshold{
    my ($self,$min,$max,$step,$data)=@_;
    my $min_stddev=100;
    my $best;
    for (my $threshold=$min; $threshold<=$max; $threshold+=$step){
        my @values=$self->measures($threshold);
        my ($q2,$acc_non,$cov_non,$acc_neu,$cov_neu)=@values;
        my $avg=($acc_non+$cov_non+$acc_neu+$cov_neu)/4;
        my $stddev=0;
        foreach my $i (1..4){
            $stddev+=abs($avg-$values[$i]);
        }
        $best=$threshold and $min_stddev=$stddev if $stddev<$min_stddev;
        #say "Threshold: $threshold - Q2: $q2 | Best: $maxsum at $best";
         if (defined $data){
            push @{$data->[0]},sprintf("%.2f",$threshold);
            push @{$data->[1]},$q2;
            push @{$data->[2]},$acc_non;
            push @{$data->[3]},$cov_non;
            push @{$data->[4]},$acc_neu;
            push @{$data->[5]},$cov_neu;
         }
    }
    return $best;
}

1;
