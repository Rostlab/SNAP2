# $Id: use.t,v 1.2 2003/02/10 02:09:46 mgjv Exp $
use Test;
use strict;

BEGIN { plan tests => 10 }

use GD::Graph;
ok(1);
use GD::Graph::axestype;
ok(1);
use GD::Graph::area;
ok(1);
use GD::Graph::bars;
ok(1);
use GD::Graph::hbars;
ok(1);
use GD::Graph::lines;
ok(1);
use GD::Graph::points;
ok(1);
use GD::Graph::linespoints;
ok(1);
use GD::Graph::mixed;
ok(1);
use GD::Graph::pie;
ok(1);
