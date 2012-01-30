#!/usr/bin/perl -w
package RG::Snap2::Run;
use strict;
use Carp qw(cluck :DEFAULT);
use RG::Snap2::Features;
use File::Basename;
use File::chdir;
use Parallel::ForkManager;

sub all{
    my ($muts,$workdir,$fcs,$cpu,$debug)=@_;
    my $fasta=$main::fasta_file;
    my $sequence=$main::sequence;
    my $name=$main::name;

    #call predictprotein to retrieve MD, PSIC, BLAST PSSM, PROF, ISIS, DISIS
    predictprotein($workdir,$fasta,$fcs,$cpu,$debug);

    #secondary structure prediction of mutants with prof
    if ($cpu>1){
        my @mutlist=splitmuts(\@main::todo,$cpu,$workdir,$debug);
        my $pm=new Parallel::ForkManager($cpu);
        foreach my $mut (@mutlist) {
            $pm->start and next;
            reprof($mut,$workdir,$debug);
            $pm->finish;
        }
        $pm->wait_all_children;
    }
    else{
        reprof($muts,$workdir,$debug);
    }
    #blast against swissprot
    swiss($workdir,$debug);

    #sift prediction for all mutants
    sift($muts,$workdir,$debug);

    #quicksnap prediction for all 19 non-native per position
    #qsnap($name,$fasta,$workdir,$debug);
}
sub qsnap{
    my ($name,$in,$workdir,$debug)=@_;
    my $out="$workdir/$name.quick";
    unless (-e $out){
        my @cmd=("perl",
            "/mnt/project/resnap/trunk/quicksnap.pl",
            "--in=$in",
            "--mut=all",
            "--out=$out",
            "--quiet",
            "--print-collections");
        cluck (@cmd) if $debug;
        system(@cmd) && confess "'@cmd' failed: ".($?>>8);
    }

}
sub sift{
    my ($muts,$workdir,$debug)=@_;
    my $big80=$main::big80;
    my $sift=$main::config->val('snap2','sift_exe');

    unless (-e "$workdir/$main::name.SIFTprediction") {
        my $siftcall=qq|$sift '$workdir/$main::name.fasta' '$big80' '$muts' 2.75 |.( $debug ? '' : ' >/dev/null 2>&1' );
        local $CWD = $workdir;
        cluck "Workdir: $CWD" if $debug;
        cluck $siftcall if $debug;
        system($siftcall) && confess "'$siftcall' failed: ".($?>>8);
        #do we want to fail if sift fails? if not we can just use an empty sift file
        #system($siftcall) && `touch $workdir/$main::name.SIFTprediction`
    }

}
sub swiss{
    my ($workdir,$debug)=@_;
    my $swissdb=$main::swissdb;
    my $blast=$main::config->val('snap2','blast_exe');

	unless (-e "$workdir/$main::name.blastswiss"){
		my $cmd=qq|$blast -i '$workdir/$main::name.fasta' -d '$swissdb' -e 0.001 -o '$workdir/$main::name.blastswiss'|.( $debug ? '' : ' >/dev/null 2>&1' );
		cluck $cmd if $debug;
		system ($cmd) && unlink("$workdir/$main::name.blastswiss") and confess "'$cmd' failed: ".($?>>8);
	}
}

sub reprof{
   my ($muts,$workdir,$debug)=@_;
   my $prof=$main::config->val('snap2','reprof_exe');

   unless (-e "$workdir/$main::name.reprof"){
       my $cmd = "$prof -i $workdir/$main::name.blastPsiMat -o $workdir/$main::name.reprof -mutations $muts".($debug ? '' : '>/dev/null 2>&1');
       cluck $cmd if $debug;
        system ($cmd) &&  confess "'$cmd' failed: ".($?>>8);
   } 
}
    
sub predictprotein{
    my ($workdir,$fasta,$fcs,$cpu,$debug)=@_;
    return if (-e "$workdir/$main::name.blastPsiMat");
    my $pp=$main::config->val('snap2','pp_exe');
    my $blast_processors=$cpu;

    my @cmd=("$pp", 
        "--seqfile=$fasta",
        "--target=query.blastPsiMat", 
        "--target=query.psic",
        "--target=query.profRdb",
        "--target=query.prof1Rdb",
    #    "--target=query.SIFTprediction ", 
        "--target=query.profbval",
        "--target=query.isis",
        "--target=query.disis",
        "--target=query.mdisorder",
        "--blast-processors=$blast_processors");
    push @cmd,"--force-cache-store" if $fcs;
    push @cmd,"--output-dir=$workdir" unless $main::use_pp_cache;
    cluck(@cmd) if $debug;
    system(@cmd) && confess "Failed to execute '@cmd': ".($?>>8);

    if ($main::use_pp_cache){
        open( my $ph, '-|', 'ppc_fetch', '--seqfile', "$workdir/$main::name.fasta" ) || confess( "failed to open pipe: $!" );
        my ( $ppc_fetch_baseline ) = grep( /.in$/o, <$ph> ); 
        confess("no .in file in cache for sequence '$workdir/$main::name.fasta'") unless $ppc_fetch_baseline; 
        if( !close( $ph ) ){
            if( $! == 0 && ( $? >> 8 ) == 254 ){ 
                confess("no results in cache for sequence '$workdir/$main::name.fasta'"); 
            } 
            else { 
                confess( "failed to close pipe: $!" ); 
            } 
        }
        chomp( $ppc_fetch_baseline );
        $ppc_fetch_baseline =~ s/in$//o;
        my @fetch;
        push @fetch,$ppc_fetch_baseline."disis";
        push @fetch,$ppc_fetch_baseline."blastPsiMat";
        push @fetch,$ppc_fetch_baseline."psic";
        push @fetch,$ppc_fetch_baseline."isis";
        push @fetch,$ppc_fetch_baseline."prof1Rdb";
        push @fetch,$ppc_fetch_baseline."profRdb";
        push @fetch,$ppc_fetch_baseline."mdisorder";
        push @fetch,$ppc_fetch_baseline."profbval"; 
        foreach my $file (@fetch) {
            my ($fname,$base,$ext)=fileparse($file,qr/\.[^.]*/);
            my @cmd=("cp","$file","$workdir/$main::name"."$ext");
            cluck(@cmd) if $debug;
            system(@cmd) && confess "Failed to execute '@cmd': ".($?>>8);
        }
    }
    else {
        my @ppfiles = glob ("$workdir/query.*");
        foreach (@ppfiles) {
            my ($fname,$base,$ext)=fileparse($_,qr/\.[^.]*/);
            my @cmd=("mv","$_","$workdir/$main::name"."$ext");
            cluck(@cmd) if $debug;
            system(@cmd) && confess "Failed to execute '@cmd': ".($?>>8);
            
        }
    }

}


sub splitmuts{
    my ($muts,$cpus,$workdir,$debug)=@_;
    my $mpc=(scalar(@$muts)/$cpus)+1;
    my @muts=@$muts;
    my @mutlist;
    my $curr=0;
    for (my $i = 0; $i < $cpus; $i++) {
        open OMUT,">$workdir/$i.mut" or confess "Unable to write mut file: $workdir/$i.mut";
        for (my $var = 0; $var < $mpc && scalar(@muts)>0; $var++) {
            say OMUT shift @muts;
        }
        close OMUT;
        push @mutlist,"$workdir/$i.mut";
    }
    return @mutlist;
}

1;
