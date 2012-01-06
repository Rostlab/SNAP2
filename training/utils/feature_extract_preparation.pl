#! /usr/bin/perl
if (!($ARGV[0] && $ARGV[1])) {die"** Usage:\nperl extract_human_muts.pl [inputfile] [outputfile]\n";}
  $fhin= "FHIN";
  $fhout= "FHOUT";
  $outfolder=$ARGV[1];
  $swissprot=$ARGV[0];
  $human=0;
  $oldname="";
open($fhin,$swissprot)|| die"** could not open input-file $swissprot\n";

while(<$fhin>){
    #print $_;
#	if ($_=~ /^>(.*_HUMAN).*\.(\w)(\d*)(\w)\s(\d)$/){
	if ($_=~ /^>(.*)\.(\w)(\d*)(\w)\s(\d)$/){
		$human=1; 
		$name=$1;
		$org=$2;
		$pos=$3;
		$sub=$4;
		$func=$5;		
		
		$outfile=$outfolder."/$name/$name";
		
	}		
	elsif ($human==1) {
		$seq=$_;
		writefiles($name,$org,$pos,$sub,$func,$seq,$outfile);
		$human=0;
        print sprintf("%.2",$counter/160381) if ($counter/160381 % 100 ==0);
        #last if $counter==50;
	}
}


sub writefiles {
	my ($name,$org,$pos,$sub,$func,$seq,$outfile)=@_;
	if (!-e $outfolder."/$name") {`mkdir $outfolder/$name`}
	
	#Either append to existing mutant file or write a new one
	if (-e "$outfile.mut") {open($fhout, ">>$outfile.mut") || die"** could not open $outfile\n";}
	else {open($fhout, ">$outfile.mut") || die"** could not open $outfile\n";}
	print $fhout $org.$pos.$sub."\n";
	close $fhout;
	
	#Either append to existing mutant file or write a new one
	if (-e "$outfile.effect") {open($fhout, ">>$outfile.effect") || die"** could not open $outfile\n";}
	else {open($fhout, ">$outfile.effect") || die"** could not open $outfile\n";}
	print $fhout $org.$pos.$sub." $func\n";
    ##remove following 3 lines
    if ($func){
        print $fhout $org.$pos.$org." 0\n";
    }
    #end remove
	close $fhout;
	
	#ensure correctness of mutant
	my @tempseq=split(//o,$seq);
	$tempseq[$pos-1]=$org;

	my $newseq=join("",@tempseq);
	
	
	
	#write sequence file
	if (!(-e "$outfile.sequence")) {
			open($fhout,"> $outfile.sequence") || die"** could not open $outfile\n";
			print $fhout $newseq;
			close $fhout;
			$counter++;
		}
}
#print "$counter\n";
close $fhin;


