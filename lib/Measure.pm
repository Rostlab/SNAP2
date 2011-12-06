package Measure;
use strict;
use feature qw(say);
use List::Util qw(sum);
use Data::Dumper;
use POSIX qw(floor);

my $threshold = 0.0;

sub new {
    my ($class, $size) = @_;

    my $self = [[], $size];

    bless $self, $class;
    return $self;
}

sub size {
    my $self = shift;
    return $self->[1];
}

sub num_points {
    my $self = shift;
    return scalar $self->[0];
}

sub add {
    my ($self, $observed, $predicted) = @_;

    my $obs = $self->max_pos($observed);
    my $pred = $self->max_pos($predicted);

    #say join " ", "obs: ", @$observed;
    #say join " ", @$obs;

    #say "";
    
    #say join " ", "pred:", @$predicted;
    #say join " ", @$pred;

    push @{$self->[0]}, [$obs, $pred];
}

#--------------------------------------------------
# single measures 
#-------------------------------------------------- 
sub precisions { # ppvs
    my ($self) = @_;

    my @result;
    my $conf = $self->confusion;
    my $size = $self->[1];
    foreach my $i (0 .. $size - 1) {
        if ($conf->[$size][$i] == 0) {
            push @result, 0;
        }
        else {
            push @result, ($conf->[$i][$i] / $conf->[$size][$i]);
        }
    }
    return @result;
}

sub recalls { # sensitivites, tprs
    my ($self) = @_;

    my @result;
    my $conf = $self->confusion;
    my $size = $self->[1];
    foreach my $i (0 .. $size - 1) {
        if ($conf->[$i][$size] == 0) {
            push @result, 0;
        }
        else {
            push @result, ($conf->[$i][$i] / $conf->[$i][$size]);
        }
    }
    return @result;
}

sub fmeasures {
    my ($self) = @_;

    my @result;
    my @p = $self->precisions;
    my @r = $self->recalls;

    foreach my $i (0 .. scalar @p - 1) {
        if (($p[$i] + $r[$i]) == 0) {
            push @result, 0;
        }
        else {
            push @result, ((2 * $p[$i] * $r[$i]) / ($p[$i] + $r[$i]));
        }
    }
    
    return @result;
}

sub mccs {
    my ($self) = @_;

    my @result;
    my $conf = $self->confusion;
    my $size = $self->[1];
    foreach my $i (0 .. $size - 1) {
        my $tp = 0;
        my $tn = 0;
        my $fp = 0;
        my $fn = 0;

        foreach my $o (0 .. $size - 1) {
            foreach my $p (0 .. $size - 1) {
                # true
                if ($o == $p) {
                    # positive
                    if ($o == $i) {
                        $tp += $conf->[$o][$p];
                    }
                    else {
                        $tn += $conf->[$o][$p];
                    }
                }
                else {
                    # positive
                    if ($o == $i) {
                        $fn += $conf->[$o][$p];
                    }
                    else {
                        $fp += $conf->[$o][$p];
                    }
                }
            }
        }

        if ((($tp + $fp) * ($tp + $fn) * ($tn + $fp) * ($tn + $fn)) == 0) {
            push @result, 0;
        }
        else {
            my $mcc = ($tp * $tn - $fp * $fn) / (sqrt(($tp + $fp) * ($tp + $fn) * ($tn + $fp) * ($tn + $fn)));
            push @result, $mcc;
        }
    }
    return @result;
}

sub pr_aucs {
    my ($self, $data_matrix) = @_;

    my @result;

    my $size = $self->size;
    foreach my $pos (1 .. $size) {
        my $current_class = $pos - 1;
        my @sorted = sort {$b->[1][$pos] <=> $a->[1][$pos]} @{$self->[0]};


        my $p = 0;
        my $n = 0;
        foreach my $entry (@sorted) {
            # positive
            if ($entry->[0][0] == $current_class) {
                $p++;
            }
            # negative
            else {
                $n++;
            }
        }
        #say "\ncurrent_class: $current_class p: $p n: $n";

        if ($p == 0 || $n == 0) {
            push @result, 0;
            next;
        }

        my %class_result;

        my $tp = 0;
        my $fp = 0;
        my $tn = 0;
        my $fn = 0;

        my $pred_pos = 0;
        foreach my $entry (@sorted) {
            $pred_pos++;
            # true
            # positive
            if ($entry->[0][0] == $current_class) {
                $tp++;
            }
            # negative
            else {
                $tn++;
            }

            # false
            # positive
            if ($entry->[0][0] == $current_class) {
                $fn++;
            }
            # negative
            else {
                $fp++;
            }

            my $pr = $tp / $pred_pos;
            my $rec = $tp / $p;

            $class_result{$rec} = $pr;
        }

        my @sorted_results;
        foreach my $rec (sort {$a <=> $b} keys %class_result) {
            push @sorted_results, [$class_result{$rec}, $rec];
        }

        if (defined $data_matrix) {
            push @$data_matrix, \@sorted_results;
        }

        my $A = 0;
        foreach my $i (1 .. scalar @sorted_results - 1) {
            #foreach my $i (1 .. scalar @$class_result - 1) {

            my $x1 = $sorted_results[$i - 1]->[1];
            my $x2 = $sorted_results[$i]->[1];

            my $h = $x2 - $x1;
            my $a = $sorted_results[$i - 1]->[0];
            my $b = $sorted_results[$i]->[0];

            $A += (($a + $b) / 2) * $h;
            #say "h $h a $a b $b A $A";

            #say join " ", @{$sorted_results[$i-1]}, "x1: $x1  x2: $x2  h: $h  a: $a  b: $b  A: $A";
        }
        push @result, $A;
    }

    return @result;
}

sub aucs {
    my ($self, $data_matrix) = @_;

    my @result;

    my $size = $self->size;
    foreach my $pos (1 .. $size) {
        my $current_class = $pos - 1;
        my @sorted = sort {$b->[1][$pos] <=> $a->[1][$pos]} @{$self->[0]};


        my $p = 0;
        my $n = 0;
        foreach my $entry (@sorted) {
            # positive
            if ($entry->[0][0] == $current_class) {
                $p++;
            }
            # negative
            else {
                $n++;
            }
        }
        #say "\ncurrent_class: $current_class p: $p n: $n";

        if ($p == 0 || $n == 0) {
            push @result, 0;
            next;
        }

        my %class_result;

        my $tp = 0;
        my $fp = 0;
        my $tn = 0;
        my $fn = 0;
        foreach my $entry (@sorted) {
            # true
            # positive
            if ($entry->[0][0] == $current_class) {
                $tp++;
            }
            # negative
            else {
                $tn++;
            }

            # false
            # positive
            if ($entry->[0][0] == $current_class) {
                $fn++;
            }
            # negative
            else {
                $fp++;
            }

            my $tpr = $tp / $p;
            my $fpr = $fp / $n;

            $class_result{$fpr} = $tpr;
        }

        my @sorted_results;
        foreach my $fpr (sort {$a <=> $b} keys %class_result) {
            push @sorted_results, [$class_result{$fpr}, $fpr];
        }

        if (defined $data_matrix) {
            push @$data_matrix, \@sorted_results;
        }

        my $A = 0;
        foreach my $i (1 .. scalar @sorted_results - 1) {
            #foreach my $i (1 .. scalar @$class_result - 1) {

            my $x1 = $sorted_results[$i - 1]->[1];
            my $x2 = $sorted_results[$i]->[1];

            my $h = $x2 - $x1;
            my $a = $sorted_results[$i - 1]->[0];
            my $b = $sorted_results[$i]->[0];

            $A += (($a + $b) / 2) * $h;
            #say "h $h a $a b $b A $A";

            #say join " ", @{$sorted_results[$i-1]}, "x1: $x1  x2: $x2  h: $h  a: $a  b: $b  A: $A";
        }
        push @result, $A;
    }

    return @result;
}

#--------------------------------------------------
# cumulative measures 
#-------------------------------------------------- 
sub Qn {
    my ($self) = @_;

    my $conf = $self->confusion;
    my $size = $self->[1];
    my $tp = 0;
    foreach my $i (0 .. $size - 1) {
        $tp += $conf->[$i][$i];
    }
    if ($conf->[$size][$size] == 0) {
        return 0;
    }
    return $tp / $conf->[$size][$size];
}

sub micro_fmeasure {
}

sub macro_fmeasure {
}

sub micro_precision {
}

sub macro_precision {
}

sub micro_recall {
}

sub macro_recall {
}

#--------------------------------------------------
# intern 
#-------------------------------------------------- 
sub confusion {
    my $self = shift;
    my $size = $self->[1];

    my $result = [];
    foreach (0 .. $size) {
        my $array = [];
        foreach (0 .. $size) {
            push @$array, 0;
        }
        push @$result, $array;
    }

    foreach my $entry (@{$self->[0]}) {
        my $o = $entry->[0][0];
        my $p = $entry->[1][0];

        $result->[$o][$p]++;
        $result->[$o][$size]++;
        $result->[$size][$p]++;
        $result->[$size][$size]++;
    }

    return $result;
}

sub max_pos {
    my ($self, $array) = @_;

    my @result;

    my $mpos;
    foreach my $pos (0 .. scalar @$array - 1) {
        if (! defined $mpos) {
            $mpos = $pos;
        }
        elsif ($array->[$pos] > $array->[$mpos]) {
            $mpos = $pos;
        }
    }
    push @result, $mpos;

    foreach my $current (0 .. scalar @$array - 1) {
        my $max_other;
        foreach my $other (0 .. scalar @$array - 1) {
            if ($current != $other) {
                if (! defined $max_other) {
                    $max_other = $other;
                }
                elsif ($array->[$other] > $array->[$max_other]) {
                    $max_other = $other;
                }
            }
        }
        push @result, ($array->[$current] - $array->[$max_other]);
    }

    return \@result;
}

sub output2probabilities {
    my ($self, $array) = @_;

    my $sum = sum @$array;
    my @result = @$array;
    foreach my $val (@result) {
        $val /= $sum;
    }

    return \@result;
}

1;
