#!/usr/bin/perl
use strict;
use warnings;
use Cwd 'abs_path';
use feature qw(say);
use Getopt::Long;

our($dir,$out,$set);

my $args_ok=GetOptions( 'dir=s'    =>  \$dir,
                        'set=s'    =>  \$set,
                        'out=s'    => \$out
);
die "missing dir/set" unless ($dir && $set);
my %folds;
open (SETFILE,$set) || die "failed to read set file: $set";
foreach my $line (<SETFILE>){
   next if $line=~/^\s|^Fold/o;
   chomp $line;
   $folds{$line}=1;
}
$out=Cwd::realpath($out) if $out;
my $inputdirectory=$dir;
$inputdirectory=Cwd::realpath($inputdirectory);
#print "'$inputdirectory' \n";
opendir(my $in,$inputdirectory);
my $counter=0;
my @dir=readdir($in);
#`rm -rf $inputdirectory/gridout/* $inputdirectory/griderr/*` if (-e "$inputdirectory/griderr");
#`mkdir $inputdirectory/gridout $inputdirectory/griderr` unless (-e "$inputdirectory/griderr");
#`rm -rf $out/gridout/* $out/griderr/* $out/results/*` if (-e "$out/griderr");
`mkdir $out/gridout $out/griderr $out/results/` unless (-e "$out/griderr");
foreach my $protein (@dir){
    $counter++;
    next unless exists $folds{$protein};
    next if (-e "$out/results/$protein.snap2");
    open (SH, "> $inputdirectory/$protein/grid_$protein.sh") || die "failed to write shellscript";
    print SH "#!/bin/sh\n";
    #print SH "/mnt/project/rost_db/src/fetchNr20_hhblits\n";
    #print SH "time perl /opt/hhblits/hhblits/hhblits_pssm.pl -h /var/tmp/opt/hhblits/hhblits/databases/nr20/nr20_current -i $inputdirectory/$protein/query.fasta -o $inputdirectory/$protein/query.blastPsiMat -w $inputdirectory/$protein\n";
    #print SH "perl /opt/hhblits/hhblits/scripts/reformat.pl a3m clu $inputdirectory/$protein/query.a3m $inputdirectory/$protein/query.clu 1>/dev/null 2>&1\n";
    #print SH "psic $inputdirectory/$protein/query.clu /usr/share/psic/blosum62_psic.txt $inputdirectory/$protein/query.psic\n";
    print SH "source /mnt/project/resnap/.max\n";
    print SH "/mnt/project/rost_db/src/fetchAll4Snap.pl\n";
    print SH "export PREDICTPROTEINCONF=/mnt/project/resnap/pp_nodelocaldb_rc\n";
    print SH "time perl /mnt/project/resnap/trunk/snap2.pl -print -q -i $inputdirectory/$protein/$protein.sequence -m all -o $out/results/$protein.snap2 --force-cache-store\n";
    #print SH "perl /mnt/project/resnap/trunk/snap2.pl -e -print -q -i $inputdirectory/$protein/$protein.sequence -l $inputdirectory/$protein/$protein.effect -o $inputdirectory/$protein/$protein.snap2 --workdir $inputdirectory/$protein/\n";
    close SH;
    #my $cmd='qsub -M hecht@rostlab.org'." -o $inputdirectory/gridout -e $inputdirectory/griderr $inputdirectory/$protein/grid_$protein.sh";
    my $cmd='qsub -M hecht@rostlab.org'." -o $out/gridout -e $out/griderr $inputdirectory/$protein/grid_$protein.sh";
    print int(100*$counter/(scalar(@dir)-4))." $protein: ".`$cmd`."\n";
}
