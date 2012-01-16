package Snapparser;

use strict;
use warnings;
use Carp;

sub new {
    my ($class, $file) = @_;

    my $self = {
        all  => {},
        avg => []
    };

    bless $self, $class;
    $self->parse($file);
    return $self;
}

sub parse {
    my ($self, $file) = @_;

    open SNAP, $file or croak "Could not open snap file: '$file'\n";
    my @snap_cont = grep /Sum/, (<SNAP>);
    chomp @snap_cont;
    close SNAP;
    
    my $length = $self->{_length} = scalar @snap_cont;
    my $cnt=0;
    my $avg=0;
    foreach my $line (@snap_cont) {
        $cnt++;
        my @split = split /\s+/, $line;
        $self->{all}{$split[0]}=$split[scalar(@split)-1];
        if ($cnt % 19 == 0){
            $avg+=$split[scalar(@split)-1];
            push @{$self->{avg}},int($avg/19);
            $avg=0;
        }
        else{
            $avg+=$split[scalar(@split)-1];
        }
    }
}

sub all {
    my $self = shift;
    return %{$self->{all}};
}

sub avg {
    my $self = shift;
    return @{$self->{avg}};
}

1;
