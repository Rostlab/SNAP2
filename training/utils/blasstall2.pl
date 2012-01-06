#!/usr/bin/perl
use strict;
use warnings;
use Cwd 'abs_path';
my ($inputdirectory,$outdir,$db,$debug)=@ARGV;
my $cpu ||= 100;
$inputdirectory=Cwd::realpath($inputdirectory);
#print "'$inputdirectory' \n";
$SIG{CHLD}="IGNORE";
opendir(my $in,$inputdirectory);
my @dir=readdir($in);
my @queue;
my $counter=0;
my $progress;
foreach my $protein (@dir){
	next if $protein=~/^\.|^grid/o;
    $counter++;
    my $fh;
    my $waitcnt=0;
    my $cmd=qq|blastpgp -i '$inputdirectory/$protein' -d $db -o '$outdir/$protein' -m8 -j 3 -e 1e-3 -h 1e-3 -b 3000|.( $debug ? '' : ' >/dev/null 2>&1' )    ;
    print "Now processing $protein - ";
    while (@queue>=$cpu || !open($fh,"-|",$cmd)) {
        #print "Waiting for resource..\n";
        my $proc = shift @queue;
        close $proc;
    }
    $progress=int(100*$counter/(@dir-2));
    print "$progress% done\n";
    push @queue,$fh;
}
foreach my $process (@queue){
    close $process;
}
