#!/usr/bin/perl
use strict;
use warnings;
unshift @INC,"/mnt/project/resnap/bin";
use Cwd 'abs_path';
require ForkManager;
use Getopt::Long;

our($dir,$out,$set);

my $args_ok=GetOptions( 'dir=s'    =>  \$dir,
                        'set=s'    =>  \$set 
);
die "missing dir/set" unless ($dir && $set);
my %folds;
open (SETFILE,$set) || die "failed to read set file: $set";
foreach my $line (<SETFILE>){
   next if $line=~/^\s|^Fold/o;
   chomp $line;
   $folds{$line}=1;
}

my $inputdirectory=$dir;
$inputdirectory=Cwd::realpath($inputdirectory);
die "No input directory specified" unless $inputdirectory;
my $cpus = 10;
$inputdirectory=Cwd::realpath($inputdirectory);
opendir(my $in,$inputdirectory);
my @dir=readdir($in);
my $counter=0;
my $progress;
my $pm=new ForkManager($cpus);
foreach my $protein (@dir){
	next if $protein=~/^\.|^grid/o;
    next unless defined $folds{$protein};
    $counter++;
    #next if (-e "$inputdirectory/$protein/features.arff");
    #open (PSIC, "$inputdirectory/$protein/query.psic") or warn "no query.psic in $protein\n";
    #my $test= <PSIC>;
    #close PSIC;
    #next if ($test=~/blastpgp: No hits found/og);
    #open (SEQ,"$inputdirectory/$protein/$protein.sequence");
    #chomp (my $sequence=<SEQ>);
    #close SEQ;
    #my $pp="predictprotein --output-dir $inputdirectory/$protein --seqfile $inputdirectory/$protein/$protein.sequence"; 
    #my $cmd="perl /mnt/project/resnap/trunk/quicksnap.pl -e -q -i $inputdirectory/$protein/$protein.sequence -l $inputdirectory/$protein/$protein.effect -o $inputdirectory/$protein/$protein.quick -w $inputdirectory/$protein/";
    my $cmd="perl /mnt/project/resnap/trunk/snap2.pl -print -q -i $inputdirectory/$protein/$protein.sequence -l $inputdirectory/$protein/$protein.effect -o $inputdirectory/$protein/$protein.snap2 -w $inputdirectory/$protein/";
    #my $cmd="snapfun -print -quiet -i $inputdirectory/$protein/$protein.sequence -m $inputdirectory/$protein/$protein.mut -o $inputdirectory/$protein/$protein.snapout";
    my $pid = $pm->start and next;
    #system($pp) && die "'$pp' failed: ".($?>>8);
    #system($cmd) && `rm -rf $inputdirectory/$protein` and die ("Failed to process $protein\n");
        system($cmd) && die ("Failed to process $protein\n");
        $progress=int(100*$counter/(@dir-4));
        print "$progress% done, sucessfully processed $protein\n";
    $pm->finish;
}
$pm->wait_all_children;
