#!/usr/bin/perl
use strict;
use warnings;
use Cwd 'abs_path';
my $inputdirectory=$ARGV[0];
$inputdirectory=Cwd::realpath($inputdirectory);
#print "'$inputdirectory' \n";
opendir(my $in,$inputdirectory);
my $counter=0;
my @dir=readdir($in);
`rm -rf $inputdirectory/gridout/* $inputdirectory/griderr/*` if (-e "$inputdirectory/griderr");
`mkdir $inputdirectory/gridout $inputdirectory/griderr` unless (-e "$inputdirectory/griderr");
foreach my $protein (@dir){
    open (SH, "> $inputdirectory/$protein/grid_$protein.sh") || die "failed to write shellscript";
    print SH "#!/bin/sh\n";
    #print SH "/mnt/project/rost_db/src/fetchNr20_hhblits\n";
    #print SH "time perl /opt/hhblits/hhblits/hhblits_pssm.pl -h /var/tmp/opt/hhblits/hhblits/databases/nr20/nr20_current -i $inputdirectory/$protein/query.fasta -o $inputdirectory/$protein/query.blastPsiMat -w $inputdirectory/$protein\n";
    #print SH "perl /opt/hhblits/hhblits/scripts/reformat.pl a3m clu $inputdirectory/$protein/query.a3m $inputdirectory/$protein/query.clu 1>/dev/null 2>&1\n";
    #print SH "psic $inputdirectory/$protein/query.clu /usr/share/psic/blosum62_psic.txt $inputdirectory/$protein/query.psic\n";
    print SH "source /mnt/project/resnap/.max\n";
#    print SH "/mnt/project/rost_db/src/fetchAll4Snap.pl\n";
    print SH "perl /mnt/project/resnap/trunk/snap2.pl -q -e -i $inputdirectory/$protein/$protein.sequence -l $inputdirectory/$protein/$protein.effect -o $inputdirectory/$protein/$protein.snap2 --workdir $inputdirectory/$protein/\n";
    close SH;
    $counter++;
    my $cmd='qsub -M hecht@rostlab.org'." -o $inputdirectory/gridout -e $inputdirectory/griderr $inputdirectory/$protein/grid_$protein.sh";
    print int(100*$counter/(scalar(@dir)-4))." $protein: ".`$cmd`."\n";
}
