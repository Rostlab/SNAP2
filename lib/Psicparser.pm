package Psicparser;

use strict;
use warnings;
use Carp;

sub new {
    my ($class, $file) = @_;

    my $self = {
        raw  => [],
        normalized => [],
        numseq     => []
    };

    bless $self, $class;
    $self->parse($file);
    return $self;
}

sub parse {
    my ($self, $file) = @_;

    open PSIC, $file or croak "Could not open psic file: '$file'\n";
    my @psic_cont = grep /^\s*\d+/, (<PSIC>);
    chomp @psic_cont;
    close PSIC;
    
    my $length = $self->{_length} = scalar @psic_cont;

    foreach my $line (@psic_cont) {
        $line =~ s/^\s*//;
        my @split = split /\s+/, $line;

        my @raws = @split[1..20];
        my @norms = map {normalize_psic($_)} @raws;
        push @{$self->{raw}}, \@raws;
        push @{$self->{normalized}}, \@norms;
        push @{$self->{numseq}}, $split[21];
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

sub numseq {
    my $self = shift;
    return @{$self->{numseq}};
}

sub normalize_psic {
    my $x = shift;
    return 1.0 / (1.0 + exp(-$x));
}

1;
