#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Getopt::Long;
use Cwd qw(abs_path);

my $dir=$ARGV[0];
$dir=Cwd::realpath($dir);
my @folders = glob "$dir/*";
foreach my $folder (@folders) {
    $folder=~/.*\/(.*)$/o;
    my $name=$1;
    my $cmd="mv $folder/$name.sequence $folder/$name"."_1kgenomes.sequence";
    `$cmd`;
    $cmd="mv $folder/$name.effect $folder/$name"."_1kgenomes.effect";
    `$cmd`;
    $cmd="mv $folder $folder"."_1kgenomes";
    `$cmd`;
}
