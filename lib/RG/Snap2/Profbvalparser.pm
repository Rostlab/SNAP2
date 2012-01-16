package RG::Snap2::Profbvalparser;

use strict;
use warnings;
use Carp;

sub new {
    my ($class, $file) = @_;

    my $self = {
        raw1  => [],
        raw2  => [],
        norm1   => [],
        norm2       => [],
        ri     => []
    };

    bless $self, $class;
    $self->parse($file);
    return $self;
}

sub parse {
    my ($self, $file) = @_;

    open PROFB, $file or croak "Could not open profb file: '$file'\n";
    my @profb_cont = grep /^\s*\d+/, (<PROFB>);
    chomp @profb_cont;
    close PROFB;
    
    my $length = $self->{_length} = scalar @profb_cont;

    foreach my $line (@profb_cont) {
        $line =~ s/^\s+//;
        my @split = split /\s+/, $line;

        push @{$self->{raw1}}, $split[1];
        push @{$self->{raw2}}, $split[2];
        push @{$self->{norm1}}, normalize_profb($split[1]);
        push @{$self->{norm2}}, normalize_profb($split[2]);
        push @{$self->{ri}}, int(abs($split[1]-$split[2])/10)/9;
    }
}

sub raw1 {
    my $self = shift;
    return @{$self->{raw1}};
}
sub raw2 {
    my $self = shift;
    return @{$self->{raw2}};
}

sub norm1 {
    my $self = shift;
    return @{$self->{norm1}};
}
sub norm2 {
    my $self = shift;
    return @{$self->{norm2}};
}

sub ri {
    my $self = shift;
    return @{$self->{ri}};
}


#--------------------------------------------------
# name:        normalize_profb
# args:        profb value
# return:      normalized profb value
#-------------------------------------------------- 
sub normalize_profb {
    my $x = shift;
    return $x/100;
}

1;
