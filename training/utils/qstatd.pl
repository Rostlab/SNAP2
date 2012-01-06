#!/usr/bin/perl -w
use strict;
use feature qw(say);
use List::Util qw(sum);

my $name = 'hecht';
my $mail = 'hecht@rostlab.org';
my $interval_mins = 5;

my $time_start = time;
my @intervals = (5, 10, 15, 30, 60, 120, 240, 480);
my @jobs_list;

while (1) {
my @qstat_out = grep /$name/, (`qstat -u $name`);

if (scalar @qstat_out == 0) {
say "jobs finished, sending mail";
`echo "yeehaa" | mail -s "jobs finished" $mail`;
last;
}
else {
my $jobs_current = scalar @qstat_out;

my $time_current = time;
my $time_diff = int(($time_current - $time_start) / 60);

say "$jobs_current jobs running since $time_diff mins";

while (scalar @jobs_list <= $time_diff) {
push @jobs_list, $jobs_current;
}

my @interval_diffs;
my @outs;
foreach my $interval_current (@intervals) {
if (scalar @jobs_list >= $interval_current) {
my $last_point = scalar @jobs_list - 1;
my $jobs_diff = $jobs_list[$last_point - $interval_current] - $jobs_current;

push @outs, (sprintf "%d/%d", $jobs_diff, $interval_current);
}
}

if (scalar @outs > 0) {
say join " | ", @outs;
}

}

sleep $interval_mins * 60;
}

