package RG::Snap2::Profparser;
use strict;
use Data::Dumper;
use Carp qw(cluck :DEFAULT);

sub new{
	my ($class,$file)=@_;
	$class=ref $class if ref $class;
	
	my $self={
		header=>{},
		data=>[]
	};
	bless $self,$class;
	$self->_parseProf($file);
	return $self;
}

sub _parseProf{
	my ($self,$file) =@_;
	my $index=0;
	my @profmatrix;
	open (PROF,$file) or confess ("Error: could not open $file\n");
	while (<PROF>){
		next if /^#/o;
		my @line=split(/\s+/o,$_);
		push @profmatrix, \@line;
	}
	foreach my $descriptor (@{$profmatrix[0]}) {
		$self->{header}{$descriptor}=$index;		
		$index++;
	}
	close PROF;
	$self->{data}=\@profmatrix;
}

sub getData{
	my ($self, $pos, $descriptor)=@_;
	my $length=$self->getLength();
	confess "Error: No data for position '$pos'. Data is available for $length residues\n" if $pos > $length;
	return $self->{data}->[$pos][$self->getIndex($descriptor)];
	
}

sub getIndex{
	my ($self,$descriptor)=@_;
	confess "Error: Descriptor '$descriptor' not defined in header\nHeader is: ".Dumper($self->{header}) unless defined $self->{header}{$descriptor};
	return $self->{header}{$descriptor};
}

sub getLength{
	my $self=shift;
	my $length=scalar(@{$self->{data}});
	return $length-1;
}
1;
