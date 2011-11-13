#==========================================================================
#              Copyright (c) 1995-2000 Martien Verbruggen
#--------------------------------------------------------------------------
#
#   Name:
#       GD::Graph::area.pm
#
# $Id: area.pm,v 1.16 2003/02/10 23:33:40 mgjv Exp $
#
#==========================================================================

package GD::Graph::area;
 
($GD::Graph::area::VERSION) = '$Revision: 1.16 $' =~ /\s([\d.]+)/;

use strict;

use GD::Graph::axestype;

@GD::Graph::area::ISA = qw( GD::Graph::axestype );

# PRIVATE
sub draw_data_set
{
    my $self = shift;       # object reference
    my $ds   = shift;       # number of the data set

    my @values = $self->{_data}->y_values($ds) or
        return $self->_set_error("Impossible illegal data set: $ds",
            $self->{_data}->error);

    # Select a data colour
    my $dsci = $self->set_clr($self->pick_data_clr($ds));
    my $brci = $self->set_clr($self->pick_border_clr($ds));

    # Create a new polygon
    my $poly = GD::Polygon->new();

    my @bottom;

    # Add the data points
    for (my $i = 0; $i < @values; $i++)
    {
        my $value = $values[$i];
        next unless defined $value;

        my $bottom = $self->_get_bottom($ds, $i);
        $value = $self->{_data}->get_y_cumulative($ds, $i)
            if ($self->{overwrite} == 2);

        my ($x, $y) = $self->val_to_pixel($i + 1, $value, $ds);
        $poly->addPt($x, $y);
	# Need to keep track of this stuff for hotspots, and because
	# it's the only reliable way of closing the polygon, without
	# making odd assumptions.
        push @bottom, [$x, $bottom];

        # Hotspot stuff
        # XXX needs fixing. Not used at the moment.
	next unless defined $self->{_hotspots}->[$ds]->[$i];
        if ($i == 0)
        {
            $self->{_hotspots}->[$ds]->[$i] = ["poly", 
                $x, $y,
                $x , $bottom,
                $x - 1, $bottom,
                $x - 1, $y,
                $x, $y];
        }
        else
        {
            $self->{_hotspots}->[$ds]->[$i] = ["poly", 
                $poly->getPt($i),
                @{$bottom[$i]},
                @{$bottom[$i-1]},
                $poly->getPt($i-1),
                $poly->getPt($i)];
        }
    }

    foreach my $bottom (reverse @bottom)
    {
        $poly->addPt($bottom->[0], $bottom->[1]);
    }

    # Draw a filled and a line polygon
    $self->{graph}->filledPolygon($poly, $dsci)
        if defined $dsci;
    $self->{graph}->polygon($poly, $brci)
        if defined $brci;

    # Draw the accent lines
    if (defined $brci &&
       ($self->{right} - $self->{left})/@values > $self->{accent_treshold})
    {
        for (my $i = 1; $i < @values - 1; $i++)
        {
            my $value = $values[$i];
	    ## XXX Why don't I need this line?
            ##next unless defined $value;

            my ($x, $y) = $poly->getPt($i);
            my $bottom = $bottom[$i]->[1];

            $self->{graph}->dashedLine($x, $y, $x, $bottom, $brci);
        }
    }

    return $ds
}

"Just another true value";
