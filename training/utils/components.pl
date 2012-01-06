#!/usr/bin/perl
use strict;
use warnings;
unshift @INC,"/mnt/project/resnap/bin";
use Cwd 'abs_path';
require Graph;
use feature qw(say);
use Getopt::Long;

our($inputdirectory,$outfile,$debug,$exclude,$consider);

my $args_ok=GetOptions( 'inputdirectory=s'    =>  \$inputdirectory,
                        'outfile=s'    =>  \$outfile,
                        'exclude=s'     => \$exclude,
                        'consider=s'    => \$consider,
                        'debug+'     => \$debug
);
$debug||=0;
my %considered;
my %excluded;
my $usage = "Usage: components.pl [OPTIONS]\n\t -i, --inputdirectory [input dir]\n\t -o, --outfile [output file]\n\t [optional: --debug]\n\t [optional even more debug: --debug]\n"; 
if ($consider){
    open CONS,$consider or die "failed to open consider file: $consider";
    while (<CONS>){
        chomp;
        $considered{$_}=1;
    }
    close CONS;
}
if ($exclude){
    open EX,$exclude or die "failed to open exclude file: $exclude";
    while (<EX>){
        chomp;
        $excluded{$_}=1;
    }
}
die $usage unless ($args_ok);
die $usage unless ($inputdirectory && $outfile);
$inputdirectory=Cwd::realpath($inputdirectory);
$outfile=Cwd::realpath($outfile);
#print "'$inputdirectory' \n";
opendir(my $in,$inputdirectory);
my @dir=readdir($in);
my $graph=Graph->new(($debug>1));
foreach my $protein (@dir){
    next if $protein=~/^\./o;
    #next if ($consider && !$considered{$protein});
    #next if ($exclude && $excluded{$protein});
    #next unless $protein=~/(.*)\..*/o;
    open BLAST,"$inputdirectory/$protein" or die "failed to open $protein";
    my $counter=0;
    my $id;
    foreach my $line (<BLAST>){
        my($dummy,$blasthit)=split(/\s+/o, $line);
        die "Unknown format: $line" unless $blasthit;
        #assuming first hit to be the protein itself
        unless ($counter){
            $id=$blasthit;
        }
        $counter++;
        warn "Skipping $protein..\n" and last if ($consider && !$considered{$id});
        last if ($exclude && $excluded{$id});
        next if ($consider && !$considered{$blasthit});
        next if ($exclude && $excluded{$blasthit});
        $graph->add_edge($id,$blasthit);
    }
    close BLAST;
}
$graph->print_graph() if $debug;
my @components=@{$graph->all_components()};
my $fold=0;
open (OUT,"> $outfile");
print "Members per component:\n" if $debug;
foreach my $component (@components){
    $fold++;
    print OUT "Component: $fold\n";
    print OUT join(",",sort keys(%$component))."\n";
    print "Component $fold: ".scalar(keys(%$component))."\n" if $debug;
}
close OUT;
