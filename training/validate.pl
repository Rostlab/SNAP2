#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Getopt::Long;
use Cwd;
use lib glob("/mnt/project/resnap/trunk/training"); 
use lib glob("/mnt/project/resnap/training/lib/perl/5.10.1/");
use AI::FANN;
use Measure;
use Prediction;
my $dir=getcwd;
my ($out,$bestconf);
my $args=GetOptions( 'in=s' => \$dir,
                     'out=s' => \$out,
                     'conf=s'=> \$bestconf
);
die "Usage: validate -i <DIR> -o <FILE> -c <[1-10]>" unless ($bestconf && $out);
my @sets=(1..9);
unshift @sets,10;
my $prediction=new Prediction();
#system("perl $netrunner -net $dir/$var/$bestconf/nntrain.model -set $dir/testsets/$sets[$var-1] -out $dir/predictions/$sets[$var-1].pred > /dev/null");

for (my $var = 1; $var <= 10 ; $var++) {
    
    my @data = parse_data("$dir/testsets/$sets[$var-1]");
    my $ann = AI::FANN->new_from_file("$dir/$var/$bestconf/nntrain.model");
    $ann->reset_MSE;

    say "Now testing network number: $var";
    foreach my $dp (@data) {
        my @dp_data = iostring2arrays($dp);
        my $pred = $ann->test(@dp_data);
        $prediction->add($pred,$dp_data[1]);
    }
}
$prediction->write($out);
my $measure=$prediction->measure();
say join " ",$measure->aucs();
say $measure->Qn();

sub parse_data {
    my ($file) = @_;
    open FH, $file or die "Could not open $file\n";
    my @data;
    while (my $inputs = <FH>) {
        chomp $inputs;
        my $outputs = <FH>;
        chomp $outputs;
        push @data, [$inputs, $outputs];
    }
    close FH;
    return @data;
}

sub iostring2arrays {
    my $dp = shift;
    my @inputs = split /\s+/, $dp->[0];
    my @outputs = split /\s+/, $dp->[1];
    return (\@inputs, \@outputs);
}

