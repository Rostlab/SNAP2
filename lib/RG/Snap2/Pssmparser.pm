package Pssmparser;

use strict;
use warnings;
use Carp;

sub new {
    my ($class, $file) = @_;

    my $self = {
        raw  => [],
        normalized => [],
        percentage   => [],
        info       => [],
        weight     => []
    };

    bless $self, $class;
    $self->parse($file);
    return $self;
}

sub parse {
    my ($self, $file) = @_;

    open PSSM, $file or croak "Could not open pssm file: '$file'\n";
    my @pssm_cont = grep /^\s*\d+/, (<PSSM>);
    chomp @pssm_cont;
    close PSSM;
    
    my $length = $self->{_length} = scalar @pssm_cont;

    foreach my $line (@pssm_cont) {
        $line =~ s/^\s+//;
        my @split = split /\s+/, $line;

        my @raws = @split[2..21];
        my @norms = map {normalize_pssm($_)} @raws;
        push @{$self->{raw}}, \@raws;
        push @{$self->{normalized}}, \@norms;
        my @pcs = @split[22 .. 41];
        my @pc_norms = map {$_ / 100} @pcs;
        push @{$self->{percentage}}, \@pc_norms;
        push @{$self->{info}}, $split[42];
        push @{$self->{weight}}, $split[43];
    }
}

sub raw {
    my $self = shift;
    return @{$self->{raw}};
}

sub normalized {
    my $self = shift;
    return @{$self->{normalized}};
}

sub percentage {
    my $self = shift;
    return @{$self->{percentage}};
}

sub info {
    my $self = shift;
    return @{$self->{info}};
}

sub weight {
    my $self = shift;
    return @{$self->{weight}};
}

#--------------------------------------------------
# name:        normalize_pssm
# args:        pssm value
# return:      normalized pssm value
#-------------------------------------------------- 
sub normalize_pssm {
    my $x = shift;
    return 1.0 / (1.0 + exp(-$x));
}

1;
