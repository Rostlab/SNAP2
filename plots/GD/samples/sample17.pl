use strict;
use GD::Graph::bars;
use GD::Graph::hbars;
require 'save.pl';

# Also see sample63

my @data = ( 
    ["1st","2nd","3rd","4th","5th","6th","7th", "8th", "9th"],
    [   11,   12,   15,   16,    3,  1.5,    1,     3,     4],
    [    5,   12,   24,   15,   19,    8,    6,    15,    21],
    [    12,   3,    1,   5,    12,    9,   16,    25,    11],
);

my @names = qw/sample17 sample17-h/;

for my $my_graph (GD::Graph::bars->new, GD::Graph::hbars->new)
{
    my $name = shift @names;
    print STDERR "Processing $name\n";

    $my_graph->set( 
	x_label         => 'X Label',
	y_label         => 'Y label',
	title           => 'Stacked Bars (incremental)',
	#y_max_value     => 50,
	#y_tick_number   => 10,
	#y_label_skip    => 2,
	cumulate        => 1,
	dclrs           => [ undef, qw(dgreen green) ],
	borderclrs      => [ undef, qw(black black) ],
	bar_spacing     => 4,

	transparent     => 0,
    );

    $my_graph->set_legend(undef, qw(low high));
    $my_graph->plot(\@data) or die $my_graph->error;
    save_chart($my_graph, $name);
}
