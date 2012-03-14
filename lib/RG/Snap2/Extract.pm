#!/usr/bin/perl -w
package RG::Snap2::Extract;
use strict;
use Carp qw(cluck :DEFAULT);
use Data::Dumper;
use RG::Snap2::Features;
use RG::Snap2::Pssmparser;
use RG::Snap2::Psicparser;
use RG::Snap2::Isisparser;
use RG::Snap2::Mdparser;
use RG::Snap2::Profparser;
use RG::Snap2::Disisparser;
use RG::Snap2::Swissparser;
use RG::Snap2::Profbvalparser;

sub all{
    my ($workdir,$debug)=@_;
    my @data=(0..@main::todo-1);
    my $seqlength=length($main::sequence); 
    my $pssm=new RG::Snap2::Pssmparser("$workdir/$main::name.blastPsiMat");
    my $psic=new RG::Snap2::Psicparser("$workdir/$main::name.psic");
    #my $isis=new RG::Snap2::Isisparser("$workdir/$main::name.isis");
    #my $disis=new RG::Snap2::Disisparser("$workdir/$main::name.disis");
    my $md=new RG::Snap2::Mdparser("$workdir/$main::name.mdisorder");
    my $prof=new RG::Snap2::Profparser("$workdir/$main::name.reprof");
    my $swiss=new RG::Snap2::Swissparser("$workdir/$main::name.blastswiss",$main::swiss_dat,$main::db_swiss);
    my $profbval=new RG::Snap2::Profbvalparser("$workdir/$main::name.profbval");
    my $oriprof=new RG::Snap2::Profparser("$workdir/$main::name.reprof_ORI");
    #my $snap=new RG::Snap2::Snapparser("$workdir/$main::name.quick");



    #Global Features, only extracted once
    my @aacomp=RG::Snap2::Features::aa_comp($seqlength,\@main::sequence_array,$debug);
    my @acccomp=RG::Snap2::Features::acc_comp($seqlength,\$prof,$debug);
    my @seccomp=RG::Snap2::Features::sec_comp($seqlength,\$prof,$debug);
    my @protlength=RG::Snap2::Features::protein_length($seqlength,$debug);

    #Loop over all mutants and extract all features
    foreach my $i (0..@main::todo-1){
        my ($wt,$pos,$mut)=RG::Snap2::Features::wt_pos_mut($main::todo[$i],$debug);
            my @features=(
            
                #Global Features
                @aacomp,@acccomp,@seccomp,@protlength,

                #Sequence based features
                RG::Snap2::Features::blastPssm($seqlength,$pos,\$pssm,7,$debug),
                RG::Snap2::Features::blastPerc($seqlength,$pos,\$pssm,7,$debug),
                RG::Snap2::Features::psic($seqlength,$pos,\$psic,7,$debug),
                RG::Snap2::Features::sequenceprofile(\@main::sequence_array,$seqlength,$pos,7,$debug),
                #RG::Snap2::Features::isis($seqlength,$pos,\$isis,17,$debug),
                #RG::Snap2::Features::disis($seqlength,$pos,\$disis,5,$debug),
                RG::Snap2::Features::md($seqlength,$pos,\$md,7,$debug),
                RG::Snap2::Features::sec_bin($seqlength,$pos,\$prof,7,$debug),
                #RG::Snap2::Features::sec_raw($seqlength,$pos,\$prof,7,$debug),
                RG::Snap2::Features::acc_rel($seqlength,$pos,\$prof,7,$debug),
                #RG::Snap2::Features::acc_bin($seqlength,$pos,\$prof,5,$debug),
                RG::Snap2::Features::indices($seqlength,$pos,\@main::sequence_array,7,'charge',$debug),
                RG::Snap2::Features::indices($seqlength,$pos,\@main::sequence_array,7,'hyd',$debug),
                RG::Snap2::Features::indices($seqlength,$pos,\@main::sequence_array,7,'vol',$debug),
                RG::Snap2::Features::profbval($seqlength,$pos,\$profbval,7,$debug),
                
                #Difference features
                RG::Snap2::Features::pssmDiff($wt,$pos,$mut,\$pssm,$debug),
                RG::Snap2::Features::percDiff($wt,$pos,$mut,\$pssm,$debug),
                RG::Snap2::Features::psicDiff($wt,$pos,$mut,\$psic,$debug),
                RG::Snap2::Features::profDiff($wt,$pos,$mut,"$workdir/$main::name.reprof_$main::todo[$i]",\$oriprof,$debug),
                #RG::Snap2::Features::indexDiff($wt,$mut,'vol',$debug),
                #RG::Snap2::Features::indexDiff($wt,$mut,'charge',$debug),

                #Mutation based features
                RG::Snap2::Features::swiss($wt,$pos,$mut,\$swiss,$main::phat_matrix,$debug),
                RG::Snap2::Features::sift("$workdir/$main::name.SIFTprediction",$main::todo[$i],$debug),
                RG::Snap2::Features::residue_representation($mut,$debug),
                RG::Snap2::Features::potentialDiff($seqlength,$pos,\@main::sequence_array,9,$wt,$mut,$debug),
                RG::Snap2::Features::potentialProfileDiff($wt,$mut,$debug)
            );

            #Additional indices from quicksnap
            #push @features,RG::Snap2::Features::indices($seqlength,$pos,\@main::sequence_array,17,'VINM940103',$debug);
            #push @features,RG::Snap2::Features::indices($seqlength,$pos,\@main::sequence_array,9,'BLAM930101',$debug);
            #push @features,RG::Snap2::Features::indices($seqlength,$pos,\@main::sequence_array,5,'DAYM780201',$debug);
            #push @features,RG::Snap2::Features::indices($seqlength,$pos,\@main::sequence_array,5,'QIAN880123',$debug);
            #push @features,RG::Snap2::Features::indices($seqlength,$pos,\@main::sequence_array,13,'KLEP840101',$debug);
            #push @features,RG::Snap2::Features::indexDiff($wt,$mut,'SNEP660101',$debug);
            #push @features,RG::Snap2::Features::indexDiff($wt,$mut,'RICJ880113',$debug);
            #push @features,RG::Snap2::Features::indexDiff($wt,$mut,'KLEP840101',$debug);
            #push @features,RG::Snap2::Features::indexDiff($wt,$mut,'VINM940103',$debug);
            #push @features,RG::Snap2::Features::potentials($seqlength,$pos,\@main::sequence_array,9,$wt,$debug);
            #push @features,RG::Snap2::Features::potentials($seqlength,$pos,\@main::sequence_array,9,$mut,$debug);
            #push @features,RG::Snap2::Features::qsnap_pred(\$snap,$main::todo[$i],$debug);
            #push @features,RG::Snap2::Features::qsnap_avg(\$snap,$pos,5,$seqlength,$debug);
            
            #append to data array
            $data[$i]=\@features;
            #cluck (Dumper (\@features));
    }
cluck (Dumper (\@data)) if $debug;
return \@data;
}

sub quick{
    my $debug=shift;
    my @data=(0..@main::todo-1);
    my $seqlength=length($main::sequence);

    #Global Features, only extracted once
    my @aacomp=RG::Snap2::Features::aa_comp($seqlength,\@main::sequence_array,$debug);
    my @protlength=RG::Snap2::Features::protein_length($seqlength,$debug);

    #Loop over all mutants and extract all features
    foreach my $i (0..@main::todo-1){
        
        #split mutation A36D into wildtype, position, mutant: 'A', '36', 'D'
        my ($wt,$pos,$mut)=RG::Snap2::Features::wt_pos_mut($main::todo[$i],$debug);
        
        my @features=(

            #Global
            @aacomp,@protlength,

            #Sequence window
            RG::Snap2::Features::indices($seqlength,$pos,\@main::sequence_array,7,'VINM940103',$debug),
            RG::Snap2::Features::indices($seqlength,$pos,\@main::sequence_array,7,'BLAM930101',$debug),
            RG::Snap2::Features::indices($seqlength,$pos,\@main::sequence_array,7,'DAYM780201',$debug),
            RG::Snap2::Features::indices($seqlength,$pos,\@main::sequence_array,7,'QIAN880123',$debug),
            RG::Snap2::Features::indices($seqlength,$pos,\@main::sequence_array,7,'KLEP840101',$debug),
            RG::Snap2::Features::indices($seqlength,$pos,\@main::sequence_array,7,'charge',$debug),
            RG::Snap2::Features::indices($seqlength,$pos,\@main::sequence_array,7,'hyd',$debug),
            RG::Snap2::Features::indices($seqlength,$pos,\@main::sequence_array,7,'vol',$debug),
            RG::Snap2::Features::sequenceprofile(\@main::sequence_array,$seqlength,$pos,7,$debug),
            RG::Snap2::Features::potentialDiff($seqlength,$pos,\@main::sequence_array,7,$wt,$mut,$debug),
            RG::Snap2::Features::potentialProfileDiff($wt,$mut,$debug),

            #Difference
            RG::Snap2::Features::indexDiff($wt,$mut,'SNEP660101',$debug),
            RG::Snap2::Features::indexDiff($wt,$mut,'RICJ880113',$debug),
            RG::Snap2::Features::indexDiff($wt,$mut,'vol',$debug),
            RG::Snap2::Features::indexDiff($wt,$mut,'KLEP840101',$debug),
            RG::Snap2::Features::indexDiff($wt,$mut,'VINM940103',$debug),
            RG::Snap2::Features::residue_representation($mut,$debug),
            RG::Snap2::Features::potentialProfileDiff($wt,$mut,$debug),
            RG::Snap2::Features::potentialDiff($seqlength,$pos,\@main::sequence_array,7,$wt,$mut,$debug)
        
        );

        #append to data array
        $data[$i]=\@features;
    }
    cluck (Dumper (\@data)) if $debug;
    return \@data;
    
}


1;
