#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Cwd 'abs_path';
use List::MoreUtils qw||;

my $inputdirectory=$ARGV[0];
$inputdirectory=Cwd::realpath($inputdirectory);
#print "'$inputdirectory' \n";
opendir(my $in,$inputdirectory);
my $counter=0;
my @dir=readdir($in);
foreach my $protein (@dir){
    next if $protein=~/^\./o;
    next if $protein=~/^grid/o;
    $counter++;
    open IN,"$inputdirectory/$protein/$protein.effect" or die "fail in $protein";
    my @cont=<IN>;
    close IN;
    chomp @cont;
    @cont = List::MoreUtils::uniq( @cont );
    open OUT,">$inputdirectory/$protein/$protein.effect" or die "fail in $protein";
    print OUT join "\n",@cont;
    close OUT;
    print int(100*$counter/(scalar(@dir)-4))." $protein\n";
}
