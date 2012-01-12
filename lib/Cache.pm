package Cache;

use strict;
use Carp;
use Data::Dumper;
use feature qw(say);

sub new{
    my ($class)=@_;

    my $self ={
        results => {},
        muts => [],
        todo => [],
        tostore => {}
    };
    bless $self, $class;
    return $self;
}
sub retrieve{
    my ($mutfile,$seqfile,$dbg)=@_;
	my @cmd = ( 'snapc_fetch', '--seqfile', $seqfile, '--mutfile', $mutfile );
	if ($dbg) { cluck("@cmd"); }
	open( my $fetchpipe, '-|', @cmd ) || confess( "failed to open pipe: $!" );
	my $cachereturn = [ <$fetchpipe> ];
	if( !close( $fetchpipe ) ){ 
		if( $! == 0 && ( $? >> 8 ) == 254 ){ if($dbg){ warn("some mutations were not found in cache"); } }
		else { confess( "failed to close pipe '@cmd': $!" ); } 
	}

    for( my $ln = 0; $ln < @$cachereturn; $ln += 2 )
    {
        #C30Y => 78 20 | 83 16 | 81 17 | 79 19 | 78 21 | 88 11 | 86 13 | 86 13 | 84 15 | 83 15 | sum = 66
        #C30Y    Non-neutral     6           93%
        if( $cachereturn->[$ln] !~ /^([A-Z]\d+[A-Z])/o ){ confess("unrecognized line from cache: '$cachereturn->[$ln]'"); }

        $cacheresults->{$1} = [ $cachereturn->[$ln], $cachereturn->[$ln+1] ];
    }

	my @todomuts;
	foreach my $singlemutant (@muts)
    {
	    if( !exists( $cacheresults->{$singlemutant} ) ){ push( @todomuts, $singlemutant ); if($dbg){ warn("not in cache '$singlemutant'"); } }
	}
    @muts = @todomuts;
    
    if( !@muts )
    {
		if($dbg){ warn("all predictions were found in cache"); }
		#print cached results and exit (@muts, @diff1, @diff2, and @collection are empty here and won't be used)
		printStuff( \@orig_muts, \%diff1, \%diff2, \%collection, $OUT, $print_collection, $cacheresults, $tostore );
		if( !$quiet ){ warn("output in '$fq_out_file'\n"); }
		exit(0);
    }
}

sub store{

	my( $__preds ) = @_;
	my @cmd = ( 'snapc_store', '--seqfile', "$workdir/$jobname/$job_fasta_file");
	if ($dbg) { cluck("@cmd"); }
	open( my $cache, '|-', @cmd ) || confess( "failed to open pipe: $!" );
	foreach( @$__preds ){ print $cache @$_; }
	if( !close( $cache ) ){ confess( "failed to store results (@cmd:".Data::Dumper::Dumper($__preds).") in cache: $!" );  }
}
1;
