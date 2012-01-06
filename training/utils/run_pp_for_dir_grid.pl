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
	next if $protein=~/^\./;
    next if -e "$inputdirectory/$protein/features.arff";
	my $sequence="$inputdirectory/$protein/$protein.sequence";
    #my $cmd="predictprotein --output-dir $inputdirectory/$protein --seq $sequence"; 
    #system($cmd);
    open (SH, "> $inputdirectory/$protein/grid_$protein.sh") || die "failed to write shellscript";
    print SH "#!/bin/shell\n";
    print SH "predictprotein --output-dir $inputdirectory/$protein --seqfile $sequence --target=query.profRdb --target=query.prof1Rdb --target=query.prosite --target=query.profbval --target=query.hmm3pfam --target=query.mdisorder --target=query.isis --target=query.disis --target=query.psic  --target=query.blastPsiMat\n";
    print SH "export PERL5LIB=/mnt/project/resnap\n";
    print SH "perl /mnt/project/resnap/bin/mutationExtractor.pl -i $inputdirectory/$protein/$protein.sequence -l $inputdirectory/$protein/$protein.effect -o $inputdirectory/$protein/";
    close SH;
    $counter++;
    my $cmd='qsub -M hecht@rostlab.org'." -o $inputdirectory/gridout -e $inputdirectory/griderr $inputdirectory/$protein/grid_$protein.sh";
    print int(100*$counter/(scalar(@dir)-2))." $protein: ".`$cmd`."\n";
}
