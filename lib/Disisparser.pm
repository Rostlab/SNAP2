package Disisparser;

use strict;
use warnings;
use Carp;

sub new {
    my ($class, $file) = @_;

    my $self = {
        raw  => [],
        bin => [],
        ri   => [],
    };

    bless $self, $class;
    $self->parse($file);
    return $self;
}

sub parse {
    my ($self, $file) = @_;

    open DISIS, $file or croak "Could not open disis file: '$file'\n";
    my @disis_cont = <DISIS>;
    chomp @disis_cont;
    close DISIS;
    my $cnt=0; 
    foreach my $line (@disis_cont) {
        next if $line =~ /^$/o;
        my @split = split /\s+/o, $line;
        if (defined $split[1]){
            push @{$self->{raw}}, $split[1];
            push @{$self->{ri}}, int(abs($split[1]/10))/10;
        }
        else {
            $cnt++;
            next unless $cnt % 2 == 0;
            my @residues=split(//o,$line);
            foreach my $res (@residues) {
                ($res eq "P" ? push @{$self->{bin}},1 : push @{$self->{bin}},0);
            }
        }
    }
}

sub raw {
    my $self = shift;
    return @{$self->{raw}};
}

sub bin {
    my $self = shift;
    return @{$self->{bin}};
}

sub ri {
    my $self = shift;
    return @{$self->{ri}};
}

1;
