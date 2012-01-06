#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Getopt::Long;
use Cwd 'abs_path';
our($in,$out,$components,$nfolds,$debug);

my $args_ok=GetOptions( 'in=s'    =>  \$in,
                        'out=s'    =>  \$out,
                        'components=s'    =>  \$components,
                        'nfolds=i'    =>  \$nfolds,
                        'debug+'    =>  \$debug 
);
sub usage{
    my ($msg)=shift;
    say "\nDESC:\nSplit a set of connected components into 'n' qually sized folds";
    say "\nUSAGE:\nbuildfolds.pl [OPTIONS]";
    say "\nOPTS:\n-i, --in [FILE]\n\tFile that specifies the number of datapoints for each Identifier\n-o, --out [FILE]\n\tOutput file: Holds all the identifieres for each fold\n-n, --nfolds\n\tNumber of folds\n-c, --components [FILE]\n\tComponent file: the output file of 'find_components.pl'\n-d, --debug\n\tShow debugging messages\n";
    die $msg;
}
usage("Invalid options") unless ($args_ok);
usage("No input file specified") unless $in;
usage("No output file specified") unless $out;
usage("Amount of folds not specified") unless $nfolds;
usage("No components file specified") unless $components;
open (IN,$in) or die "Could not open: '$in'";
my @temp=<IN>;
close IN;
chomp @temp;
#print join "\n",@temp;
my %identifiers=@temp;
open (COMP,$components) or die "Could not open: '$components'";
@temp=<COMP>;
close COMP;
chomp @temp;
my %comp=@temp;
my %totalmuts;
my $overalltotal=0;
foreach my $component (keys %comp){
    my @list=split(",",$comp{$component});
    my $muts=0;
    foreach my $id (@list){
        next unless $identifiers{$id};
        $muts+=$identifiers{$id};
    }
    $totalmuts{$component}=$muts;
    $overalltotal+=$muts;
}
if ($debug){
print "Datapoints per component:\n";
while ( my ($k,$v) = each %totalmuts ) {print "$k => $v\n";}
}
my $maxperfold=int($overalltotal/$nfolds);
print "Overall datapoints: $overalltotal\nAverage datapoints per fold: $maxperfold\n" if $debug;
my %finalfolds;
my $foldcount=1;
my %finalfold_datapoints;
for (my $var = 1; $var <= $nfolds; $var++) {
    $finalfolds{"Fold: $var"}="";
    $finalfold_datapoints{"Fold: $var"}=0;
}
foreach my $component (sort {$totalmuts{$b}<=>$totalmuts{$a}} keys %totalmuts){
#    print "$component -> $totalmuts{$component}\n";
    if ($totalmuts{$component}>$maxperfold){
        warn "$component ($totalmuts{$component} datapoints) is bigger than avarage foldsize ($maxperfold)\n"; 
        $finalfolds{"Fold: $foldcount"}=$comp{$component}.",";
        $finalfold_datapoints{"Fold: $foldcount"}=$totalmuts{$component};
        $foldcount++;
        $overalltotal-=$totalmuts{$component};
        $maxperfold=int($overalltotal/($nfolds-1));
        print "Remaining datapoints: $overalltotal\nNew Average datapoints per fold: $maxperfold\n" if $debug;
    }
    else {
        my ($smallest) = (sort {$finalfold_datapoints{$a}<=>$finalfold_datapoints{$b}} keys %finalfold_datapoints);
        $finalfold_datapoints{$smallest}+=$totalmuts{$component};
        $finalfolds{$smallest}.=$comp{$component}.",";
    } 
}
#print to outputfile
open OUT,">$out" or die "Coult not open output file: $out";
foreach my $k (sort keys %finalfolds){
    my $v = $finalfolds{$k};
#while ( my ($k,$v) = each %finalfolds ) { 
    print "$k => $finalfold_datapoints{$k}\n" if $debug;
    $v=~s/,/\n/go;
#    next if $finalfold_datapoints{$k}<50;
    print OUT "$k\n$v\n";
}
close OUT;
