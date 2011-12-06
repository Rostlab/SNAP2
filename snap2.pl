#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Getopt::Long;
use Cwd 'abs_path';
use File::Temp qw||;
use File::chdir;
use File::Basename;
use File::Path qw(make_path);
use Carp qw(cluck :DEFAULT);

our ($allmuts,$config,$sequence,@mutants,$name,@sequence_array,$swissdb,$db_swiss,$swiss_dat,$big80,$phat_matrix);
my ($snap2dir,$fannlib,$cpu);
BEGIN {
    use Config::IniFiles;
    #our $VERSION = "__VERSION__";

    #my ( $defaultconfig, $etcconfig );
    #if( -e "__pkgdatadir__/snapfunrc.default" ) { $defaultconfig = Config::IniFiles->new( -file => "__pkgdatadir__/snapfunrc.default" ); }
    #if( -e "__sysconfdir__/snapfunrc" ) { $etcconfig = Config::IniFiles->new( -file => "__sysconfdir__/snapfunrc", -import => $defaultconfig ); } else { $etcconfig = $defaultconfig; }
    #if( ( $ENV{SNAPFUNCONF} && -e "$ENV{SNAPFUNCONF}" ) || -e "$ENV{HOME}/.snapfunrc" ) { $config = Config::IniFiles->new( -file => $ENV{SNAPFUNCONF} || "$ENV{HOME}/.snapfunrc", -import => $etcconfig ); } else { $config = $etcconfig; }

    $config=Config::IniFiles->new( -file => "/mnt/project/resnap/trunk/snap2rc.default");
    $snap2dir = $config->val('snap2', 'snap2dir');
    $swissdb=$config->val('blast','swiss');
    $swiss_dat=$config->val('data','swiss_dat');
    $db_swiss=$config->val('data','db_swiss');
    $big80=$config->val('blast','big80');
    $phat_matrix=$config->val('data','phat_matrix');
    $fannlib=$config->val('snap2','fann_lib');
    $cpu=$config->val('snap2', 'blastpgp_processors');
}

use lib glob( "$snap2dir/lib" );
use lib glob( $fannlib );
use Run;
use Extract;
use Predict;
use Prediction;

my($in,$out,$mut,$workdir,$plot,$labeled_muts_file,$only_extract,@labels,$pc,$quiet,$fcs);
my $debug=0;
$cpu=1;
my $args_ok=GetOptions( 'in=s'    =>  \$in,
                        'out=s'    =>  \$out,
                        'workdir=s'    =>  \$workdir,
                        'debug+'     => \$debug,
                        'muts=s'    =>  \$mut,
                        'label=s'   => \$labeled_muts_file,
                        'extract'   =>\$only_extract,
                        'print-collections' => \$pc,
                        'quiet' => \$quiet,
                        'force-cache-store' => \$fcs,
                        'cpus=i' => \$cpu,
                        'plot'  => \$plot
);
sub die_usage{
    my $msg=shift;
    say "\nDESCRIPTION:\nPredict functional effect of non-synonymous single nucleotide polymorphisms";
    say "\nUSAGE:\nsnap2 -i <input fasta> -o <output file> -m <mutations file> [OPTIONS]";
    say "\nMANDATORY:";
    say "-i, --in <file>\n\tInput sequence in fasta format";
    say "\n-m, --mut <file>\n\tMutation file in format: [A-Z][0-9]+[A-Z] e.g: 'A32S'. One per line";
    say "\n-o, --out <file>\n\tOutput file";
    say "\nOPTIONS:";
    say "-w, --workdir <directory>\n\tWorking directory. Intermediate files will be saved here";
    say "\n-l, --labels <file>\n\tMutation file with labels in format: [A-Z][0-9]+[A-Z]".'\s'."[0|1] e.g: 'A32S 1' (where 1 = non-neutral, 0 = neutral). One per line";
    say "\n-e, --extract\n\tOnly extract feature values. Will be saved to <out file>.features";
    say "\n-p, --print-collections\n\tAlso print the raw outputs for each network";
    say "\n-q, --quiet\n\tSilence announcements";
    say "\n-d, --debug\n\tPrint debugging messages. Use twice to increase level of debugging messages";
    say "\n-c, --cpus\n\tNumber of cpu cores";
    die "\n$msg\n";
}
die_usage("No input file defined") unless $in;
die_usage("No output file defined") unless $out;
die_usage("Unknown argument") unless $args_ok;

if ($workdir){
    $workdir=Cwd::realpath( $workdir );
}
else {
    $workdir=File::Temp::tempdir( CLEANUP=> !$debug);
}

warn "Working directory: $workdir\n" unless $quiet;

$in=Cwd::realpath($in);
$out=Cwd::realpath($out);
$name=fileparse($out,qr/\.[^.]*/);

warn "Job name: $name\n" unless $quiet;

#Read sequence file
open (FHIN,$in) || confess "\nError: unable to open sequence file: $in\n" ;
while (<FHIN>){
    next if /^>/o;
    chomp($_);
    $sequence.=$_;
}
$sequence=~s/\s//g;
close FHIN;

#sequence as array
@sequence_array=split(//o,$sequence);

#Read mutants file
if ($labeled_muts_file){
    $labeled_muts_file=Cwd::realpath($labeled_muts_file);
    #Get the corresponding class label if available
    open (LABEL,$labeled_muts_file)|| confess "\nError: unable to open labeled mutation file: $labeled_muts_file\n";
    while (<LABEL>){
        confess "\nError: Invalid mutation line: $_\n" if !/^[A-Z]\d+[A-Z]\s+\d$/o;
        my ($mut,$label)=split;
        push (@mutants,$mut);
        push (@labels,$label);
    }
    close LABEL;

    #write mutant file in correct format (will be passed on to reprof and sift)
    $mut="$workdir/$name.muts";
    open MUT,">$mut" || confess "\nError: unable to write $mut\n";
    print MUT join "\n",@mutants;
    close MUT;
}
elsif ($mut){
    if ($mut eq 'all'){
        @mutants=allmuts(\$mut,$workdir,\@sequence_array,$debug); 
        $allmuts=1;
        $mut="$workdir/$name.allmuts";
    }
    else{
        $mut=Cwd::realpath($mut);
        open (FHIN,$mut) || confess "\nError: unable to open mutations file: $mut\n";
        while(<FHIN>){
            #check every mutant
            confess "\nError: Invalid mutation line: $_\n" unless /^[ARNDCQEGHILKMFPSTWYV]\d+[ARNDCQEGHILKMFPSTWYV]$/o;
            chomp $_;
            push (@mutants,$_);
        }
        close FHIN;
    }
}
else {
    die_usage("No mutation file defined");
}

#Run all external programs
warn "\nRunning external programs..\n" unless $quiet;
Run::all($mut,$workdir,$fcs,$cpu,$allmuts,$debug);

#Extract feature values
warn "\nExtracting feature values..\n" unless $quiet;
my $data=Extract::all($workdir,$debug>1 ? 1 : 0);

#write out the featurefile (for training purpose, won't be used anymore afterwards)
confess "Number of labels is not consistent with number of data points" if ($labeled_muts_file && scalar(@labels) != scalar(@$data));
my $extract="$workdir/$name.features";
open FEATURES,">$extract" || confess "\nError: unable to write $extract\n";
foreach my $i (0..@{$data}-1) {
    say FEATURES join(" ",@{@$data[$i]});
    say FEATURES ($labels[$i]==1 ? "0 1" : "1 0") if ($labeled_muts_file);
}
close FEATURES;

exit(0) if $only_extract;

#Run all the neural networks
warn "\nRunning predictions..\n" unless $quiet;
my @predictions=Predict::all($data,"$snap2dir/models",$debug>1 ? 1 : 0);
confess "Number of predictions is not consistent with number of data points" if scalar(@predictions) != scalar(@$data);

#Expected accuracy as obtained from 10-fold cross-validation
my %expected_accuracy=( -9 => '97%',
                        -8 => '93%',
                        -7 => '87%',
                        -6 => '82%',
                        -5 => '78%',
                        -4 => '72%',
                        -3 => '66%',
                        -2 => '61%',
                        -1 => '57%',
                         0 => '53%',
                         1 => '59%',
                         2 => '63%',
                         3 => '66%',
                         4 => '71%',
                         5 => '75%',
                         6 => '80%',
                         7 => '85%',
                         8 => '91%',
                         9 => '95%');

#Write output file
my $prediction=new Prediction();
open OUT,">$out" or confess "Unable to write output file: $out";
foreach my $data_point (0..@predictions-1) {
    my ($neu,$non)=qw(0 0);
    print OUT $mutants[$data_point] . " => " if $pc;
    foreach my $network (@{$predictions[$data_point]}) {
        $neu+=$$network[0];
        $non+=$$network[1];
        print OUT int(100*$$network[0]) ." ". int(100*$$network[1]) ."\t| " if $pc;
    }
    say OUT "Sum = ". int(100*($neu-$non)/scalar(@{$predictions[0]})) if $pc;
    if ($labeled_muts_file){
        $prediction->add([$neu/10,$non/10],($labels[$data_point] == 1 ? [0,1] : [1,0]));
    }
    my $ri=$neu-$non;
    say OUT $mutants[$data_point] . " => Prediction: " . ($ri>0 ? "Non-neutral" : "Neutral") . "\tReliability Index: " . int(abs($ri)) . "\tExpected accuracy: " . $expected_accuracy{int($ri)}; 
    
}
close OUT;
$prediction->write("$out.labeledpred") if $labeled_muts_file;
if ($plot){
    use lib glob ("$snap2dir/plots");
    use Plot;
    Plot::from_prediction($name,\@sequence_array,\@predictions,$out,$debug);
}
warn "\nOutput written to $out\n" unless $quiet;
exit(0);

#--------------------------------------------------
# Sub-routines 
#-------------------------------------------------- 

sub allmuts{
    my ($mut,$workdir,$seq_arr,$debug)=@_;
    my @mutants;
    my @amino_acids=qw( A R N D C Q E G H I L K M F P S T W Y V );
    for (my $i = 0; $i < scalar(@$seq_arr); $i++) {
        my $wt=($$seq_arr[$i] eq "X" ? "A" : $$seq_arr[$i]);
        foreach my $aa (@amino_acids) {
            push @mutants,$wt . ($i+1) . $aa unless $wt eq $aa;
        }
    }
    open MUT,">$workdir/$name.allmuts" or confess "Unable to write mutant file: $workdir/$name.allmuts";
    say MUT join "\n",@mutants;
    close MUT;

    return @mutants;
}
