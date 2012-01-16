package RG::Snap2::Mdparser;

use strict;
use warnings;
use Carp;

sub new {
    my ($class, $file) = @_;

    my $self = {
        normalized => [],
        ri       => [],
        bin     => []
    };

    bless $self, $class;
    $self->parse($file);
    return $self;
}

sub parse {
    my ($self, $file) = @_;

    open MD, $file or croak "Could not open md file: '$file'\n";
    my @md_cont = grep /^\s*\d+/, (<MD>);
    chomp @md_cont;
    close MD;
    
    my $length = $self->{_length} = scalar @md_cont;

    foreach my $line (@md_cont) {
        $line =~ s/^\s+//;
        my @split = split /\s+/, $line;

        push @{$self->{normalized}}, $split[8];
        push @{$self->{ri}}, normalize_ri($split[9]);
        push @{$self->{bin}}, bin2num($split[10]);
    }
}


sub normalized {
    my $self = shift;
    return @{$self->{normalized}};
}


sub ri {
    my $self = shift;
    return @{$self->{ri}};
}

sub bin {
    my $self = shift;
    return @{$self->{bin}};
}
##--------------------------------------------------
# name:        normalize_ri
# desc:        Normalize RI to [0,1]
# args:        ri
# return:   normalized ri 
#-------------------------------------------------- 
sub normalize_ri {
   my $x = shift;
   return $x/9;
}
#--------------------------------------------------
# name:        normalize_md
# args:        md value
# return:      normalized md value
#-------------------------------------------------- 
sub normalize_md {
    my $x = shift;
    return 1.0 / (1.0 + exp(-$x));
}
##--------------------------------------------------
# name:        bin2num
# desc:        translates binary states (D,-) into (1,0) 
# args:        bin value
# return:      numeric value (1 Disordered, 0 Not disordered)
#-------------------------------------------------- 
sub bin2num {
   my $x = shift;
   if ($x eq "D"){
    return 1;
   }
   else{
    return 0;
   }
}   

1;
