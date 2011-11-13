use GD::Graph::lines;
use GD::Graph::colour;
use GD::Graph::Data;
require 'save.pl';

GD::Graph::colour::read_rgb("rgb.txt") or 
	die "Cannot read colours from rgb.txt";

print STDERR "Processing sample53\n";

$data = ([
    ["1st","2nd","3rd","4th","5th","6th","7th", "8th", "9th"],
    [    1,    2,    5,    6,    3,  1.5,   -1,    -3,    -4],
    [   -4,   -3,    1,    1,   -3, -1.5,   -2,    -1,     0],
    [    9,    8,    9,  8.4,  7.1,  7.5,    8,     3,    -3],
	[  0.1,  0.0, -0.3, -0.4,  0.1,  0.5,  0.1,     0,   0.4],
]);

$my_graph = new GD::Graph::lines();

$my_graph->set( 
	x_label => 'X Label',
	y_label => 'Y label',
	title => 'A Multiple Line Graph',
	y_max_value => 10,
	y_min_value => -5,
	y_tick_number => 3,
	y_label_skip => 1,
	zero_axis_only => 0,
	long_ticks => 1,
	x_ticks => 0,
	dclrs => [ qw( darkorchid2 mediumvioletred deeppink darkturquoise ) ],
	line_types => [ 1, 2, 3, 4 ],
	line_type_scale => 8,
	legend_marker_width => 24,
	line_width => 3,

	show_values => 1,

	transparent => 0,

) or warn $my_graph->error;

$my_graph->set_legend( 'one', 'two', undef, 'four' );
$my_graph->plot($data) or die $my_graph->error;
save_chart($my_graph, 'sample53');

