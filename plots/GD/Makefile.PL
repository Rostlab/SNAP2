# This -*- perl -*- script makes the Makefile
# $Id: Makefile.PL,v 1.13 2003/06/16 01:26:07 mgjv Exp $
 
#--- Distribution section ---
 
use ExtUtils::MakeMaker;
use Config;
 
#use ExtUtils::Manifest;
#ExtUtils::Manifest::skipcheck();
 
my @clean = qw(*.old *.save tags);
push @clean, map { "*/$_" } @clean;

WriteMakefile(
        'VERSION_FROM'  => 'Graph.pm',  #finds $VERSION
        'DISTNAME'      => 'GDGraph',
        'NAME'          => 'GD::Graph',

        ($] >= 5.005 ?
            ('ABSTRACT'	    => 'Produces charts with GD',
             'AUTHOR'	    => 'Martien Verbruggen <mgjv@tradingpost.com.au>',
            ):()
        ),

        'PREREQ_PM'     => { 
            'GD'	    => '1.18', 
            'GD::Text'      => '0.80',
        },
 
        'dist'          => {
            'COMPRESS'      => 'gzip -9f',
            'SUFFIX'        => 'gz', 
        },

        'clean'         => { 'FILES' => join(" ", @clean), },
);

sub MY::postamble 
{
qq(
samples: all
	\@(cd samples && make PERL=$Config{'perlpath'})
	\@echo Samples have been created in samples directory

tags:
	ptags lib/GD/*.pm lib/GD/Graph/*.pm
)
}

sub MY::libscan
{
    my ($self, $path) = @_;
    return if
	$path =~ m:(^|/)\..+\.swp$:	    or
	$path =~ m:(^|/)\.#.+\d$:	    or
	$path =~ m:\b(RCS|CVS|SCCS)\b:	    ;
    return $path;
}

print <<END;

The automatic tests for GDGraph are not really a solid workout of the
library. The best way to test the package is to run the examples
before installing it.  You can run the examples in the samples
directory with `make samples` or by going into that directory, and
just running `make`.
If that fails, please read samples/Makefile.
END

