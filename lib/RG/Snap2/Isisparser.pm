package Isisparser;

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

    open ISIS, $file or croak "Could not open isis file: '$file'\n";
    my @isis_cont = grep /^\d+/, (<ISIS>);
    chomp @isis_cont;
    close ISIS;
    
    my $length = $self->{_length} = scalar @isis_cont;

    foreach my $line (@isis_cont) {
        $line =~ s/^\s+//;
        my @split = split /\s+/, $line;

        push @{$self->{raw}}, $split[2];
        push @{$self->{bin}}, ($split[2]>20 ? 1 : 0);
        push (@{$self->{ri}},0) and next if ($split[2]<=20 && $split[2]>0);
        push @{$self->{ri}}, int(abs($split[2]/10))/9;
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

#--------------------------------------------------
# name:        normalize_isis
# args:        isis value
# return:      normalized isis value
#-------------------------------------------------- 
sub normalize_isis {
    my $x = shift;
    return 1.0 / (1.0 + exp(-$x));
}

1;
