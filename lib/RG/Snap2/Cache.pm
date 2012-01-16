package Cache;

use strict;
use Carp qw(cluck :DEFAULT);
use Data::Dumper;
use feature qw(say);

sub new{
    my ($class,$seq,$muts,$mutfile,$root,$dbg)=@_;

    my $self ={
        results => {},
        todo => []
    };
    bless $self, $class;
    $self->{root}=$root if $root;
    confess "SNAP cache root directory does not exist\n" unless -e $root;
    $self->retrieve($seq,$mutfile,$muts,$dbg);
    return $self;
}
sub retrieve{
    my ($self,$seqfile,$mutfile,$muts,$dbg)=@_;
    my $snapc_fetch=$main::config->val('snap2','snapc_fetch');
	my @cmd = ( $snapc_fetch, '--seqfile', $seqfile, '--mutfile', $mutfile );
    push @cmd,"--root",$self->{root} if $self->{root};
	if ($dbg) { cluck("@cmd"); }
	open( my $fetchpipe, '-|', @cmd ) || confess( "failed to open pipe: $!" );
	my $cachereturn = [ <$fetchpipe> ];
	if( !close( $fetchpipe ) ){ 
		if( $! == 0 && ( $? >> 8 ) == 254 ){ if($dbg){ warn("some mutations were not found in cache"); } }
		else { confess( "failed to close pipe '@cmd': $!" ); } 
	}

    for( my $ln = 0; $ln < @$cachereturn; $ln += 2 ){
        #C30Y => 78 20 | 83 16 | 81 17 | 79 19 | 78 21 | 88 11 | 86 13 | 86 13 | 84 15 | 83 15 | sum = 66
        #C30Y    Non-neutral     6           93%
        if( $cachereturn->[$ln] !~ /^([A-Z]\d+[A-Z])/o ){ confess("unrecognized line from cache: '$cachereturn->[$ln]'"); }

        $self->{results}->{$1} = [ $cachereturn->[$ln], $cachereturn->[$ln+1] ];
    }

	foreach my $singlemutant (@$muts){
	    unless ( exists $self->{results}->{$singlemutant} ){ 
            push( @{$self->{todo}}, $singlemutant ); 
            warn("not in cache '$singlemutant'") if $dbg;
        }
	}
    
    unless ( @{$self->{todo}} ){
		if($dbg){ warn("all predictions were found in cache"); }
    }
}

sub results{
    my ($self)=@_;
    return %{$self->{results}};
}

sub todo{
    my ($self)=@_;
    return @{$self->{todo}};
}

sub store{
	my( $self,$preds,$fasta,$dbg ) = @_;
    my $snapc_store=$main::config->val('snap2','snapc_store');
	my @cmd = ( $snapc_store, '--seqfile', $fasta);
    push @cmd,"--root",$self->{root} if $self->{root};
	if ($dbg) { cluck("@cmd"); }
	open( my $cache, '|-', @cmd ) || confess( "failed to open pipe: $!" );
	foreach(keys %$preds ){ print $cache @{$preds->{$_}}; }
	if( !close( $cache ) ){ confess( "failed to store results (@cmd:".Data::Dumper::Dumper($preds).") in cache: $!" );  }
}
1;
