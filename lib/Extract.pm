#!/usr/bin/perl -w
package Extract;
use strict;
use Carp qw(cluck :DEFAULT);
use Data::Dumper;
use Features;
use Pssmparser;
use Psicparser;
use Isisparser;
use Disisparser;
use Swissparser;
use Profbvalparser;

sub all{
    my ($workdir,$debug)=@_;
    my @data;
    my $seqlength=length($main::sequence); 
    my $pssm=new Pssmparser("$workdir/$main::name.blastPsiMat");
    my $psic=new Psicparser("$workdir/$main::name.psic");
    #my $isis=new Isisparser("$workdir/$main::name.isis");
    #my $disis=new Disisparser("$workdir/$main::name.disis");
    #my $md=new Mdparser("$workdir/$main::name.mdisorder");
    my $prof=new Profparser("$workdir/$main::name.reprof");
    my $swiss=new Swissparser("$workdir/$main::name.blastswiss",$main::swiss_dat,$main::db_swiss);
    my $profbval=new Profbvalparser("$workdir/$main::name.profbval");
    my $oriprof=new Profparser("$workdir/$main::name.reprof_ORI");
    #my $snap=new Snapparser("$workdir/$main::name.quick");



    #Global Features, only extracted once
    my @aacomp=Features::aa_comp($seqlength,\@main::sequence_array,$debug);
    my @acccomp=Features::acc_comp($seqlength,\$prof,$debug);
    my @seccomp=Features::sec_comp($seqlength,\$prof,$debug);
    my @protlength=Features::protein_length($seqlength,$debug);

    #Loop over all mutants and extract all features
    foreach my $i (0..@main::todo-1){
        my @features;
        #split mutation A36D into wildtype, position, mutant: 'A', '36', 'D'
        my ($wt,$pos,$mut)=Features::wt_pos_mut($main::todo[$i],$debug);

        #Global Features
        push @features,@aacomp,@acccomp,@seccomp,@protlength;

        #Sequence based features
        push @features,Features::blastPssm($seqlength,$pos,\$pssm,5,$debug);
        push @features,Features::blastPerc($seqlength,$pos,\$pssm,1,$debug);
        push @features,Features::psic($seqlength,$pos,\$psic,13,$debug);
        push @features,Features::sequenceprofile(\@main::sequence_array,$seqlength,$pos,9,$debug);
        #push @features,Features::isis($seqlength,$pos,\$isis,17,$debug);
        #push @features,Features::disis($seqlength,$pos,\$disis,5,$debug);
        #push @features,Features::md($seqlength,$pos,\$md,9,$debug);
        #push @features,Features::sec_bin($seqlength,$pos,\$prof,13,$debug);
        #push @features,Features::sec_raw($seqlength,$pos,\$prof,9,$debug);
        push @features,Features::acc_rel($seqlength,$pos,\$prof,5,$debug);
        #push @features,Features::acc_bin($seqlength,$pos,\$prof,5,$debug);
        #push @features,Features::indices($seqlength,$pos,\@main::sequence_array,17,'charge',$debug);
        #push @features,Features::indices($seqlength,$pos,\@main::sequence_array,17,'hyd',$debug);
        #push @features,Features::indices($seqlength,$pos,\@main::sequence_array,17,'vol',$debug);
        push @features,Features::profbval($seqlength,$pos,\$profbval,5,$debug);
        
        #Difference features
        push @features,Features::pssmDiff($wt,$pos,$mut,\$pssm,$debug);
        push @features,Features::percDiff($wt,$pos,$mut,\$pssm,$debug);
        push @features,Features::psicDiff($wt,$pos,$mut,\$psic,$debug);
        #push @features,Features::indexDiff($wt,$mut,'vol',$debug);
        #push @features,Features::indexDiff($wt,$mut,'charge',$debug);
        #push @features,Features::profDiff($wt,$pos,$mut,"$workdir/$main::name.reprof_$main::todo[$i]",\$oriprof,$debug);

        #Mutation based features
        push @features,Features::swiss($wt,$pos,$mut,\$swiss,$main::phat_matrix,$debug);
        push @features,Features::sift("$workdir/$main::name.SIFTprediction",$main::todo[$i],$debug);
        push @features,Features::residue_representation($mut,$debug);

        #Additional indices from quicksnap
        #push @features,Features::indices($seqlength,$pos,\@main::sequence_array,17,'VINM940103',$debug);
        #push @features,Features::indices($seqlength,$pos,\@main::sequence_array,9,'BLAM930101',$debug);
        #push @features,Features::indices($seqlength,$pos,\@main::sequence_array,5,'DAYM780201',$debug);
        #push @features,Features::indices($seqlength,$pos,\@main::sequence_array,5,'QIAN880123',$debug);
        #push @features,Features::indices($seqlength,$pos,\@main::sequence_array,13,'KLEP840101',$debug);
        #push @features,Features::indexDiff($wt,$mut,'SNEP660101',$debug);
        #push @features,Features::indexDiff($wt,$mut,'RICJ880113',$debug);
        #push @features,Features::indexDiff($wt,$mut,'KLEP840101',$debug);
        #push @features,Features::indexDiff($wt,$mut,'VINM940103',$debug);
        #push @features,Features::potentials($seqlength,$pos,\@main::sequence_array,9,$wt,$debug);
        #push @features,Features::potentials($seqlength,$pos,\@main::sequence_array,9,$mut,$debug);
        push @features,Features::potentialDiff($seqlength,$pos,\@main::sequence_array,9,$wt,$mut,$debug);
        push @features,Features::potentialProfileDiff($wt,$mut,$debug);
        #push @features,Features::qsnap_pred(\$snap,$main::todo[$i],$debug);
        #push @features,Features::qsnap_avg(\$snap,$pos,5,$seqlength,$debug);
        
        #append to data array
        push (@data,\@features);
        #cluck (Dumper (\@features));
    }
cluck (Dumper (\@data)) if $debug;
return \@data;
}

sub quick{
    my $debug=shift;
    my @data;
    my $seqlength=length($main::sequence);

    #Global Features, only extracted once
    my @aacomp=Features::aa_comp($seqlength,\@main::sequence_array,$debug);
    my @protlength=Features::protein_length($seqlength,$debug);

    #Loop over all mutants and extract all features
    foreach my $i (0..@main::todo-1){
        my @features;
        
        #split mutation A36D into wildtype, position, mutant: 'A', '36', 'D'
        my ($wt,$pos,$mut)=Features::wt_pos_mut($main::todo[$i],$debug);
        
        #Global
        push @features,@aacomp,@protlength;

        #Sequence window
        push @features,Features::indices($seqlength,$pos,\@main::sequence_array,17,'VINM940103',$debug);
        push @features,Features::indices($seqlength,$pos,\@main::sequence_array,9,'BLAM930101',$debug);
        push @features,Features::indices($seqlength,$pos,\@main::sequence_array,5,'DAYM780201',$debug);
        push @features,Features::indices($seqlength,$pos,\@main::sequence_array,5,'QIAN880123',$debug);
        push @features,Features::indices($seqlength,$pos,\@main::sequence_array,13,'KLEP840101',$debug);
        push @features,Features::sequenceprofile(\@main::sequence_array,$seqlength,$pos,9,$debug);
        push @features,Features::potentials($seqlength,$pos,\@main::sequence_array,9,$wt,$debug);
        push @features,Features::potentials($seqlength,$pos,\@main::sequence_array,9,$mut,$debug);

        #Difference
        push @features,Features::indexDiff($wt,$mut,'SNEP660101',$debug);
        push @features,Features::indexDiff($wt,$mut,'RICJ880113',$debug);
        push @features,Features::indexDiff($wt,$mut,'vol',$debug);
        push @features,Features::indexDiff($wt,$mut,'KLEP840101',$debug);
        push @features,Features::indexDiff($wt,$mut,'VINM940103',$debug);
        push @features,Features::residue_representation($mut,$debug);
        push @features,Features::potentialProfileDiff($wt,$mut,$debug);
        push @features,Features::potentialDiff($seqlength,$pos,\@main::sequence_array,9,$wt,$mut,$debug);

        #append to data array
        push (@data,\@features);
    }
    cluck (Dumper (\@data)) if $debug;
    return \@data;
    
}


1;
