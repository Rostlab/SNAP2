#!/usr/bin/perl
use strict;
use warnings;
package Graph;

sub new {
my ($class,$debug) = @_;
$class= ref $class if ref $class;
	my $self={
		graph=>{},
		debug=>$debug
	};
	bless $self,$class;
	return $self;
}
sub add_node {
    my ($self, $node) = @_;
    die "no node specified" unless (defined $node);
	unless ( exists $self->{graph}->{$node} ){
    	$self->{graph}->{$node} = {};
    	print "added a new node: $node\n" if $self->{debug};
    }
}
sub add_edge {
    my ($self, $node1, $node2) = @_;
	$self->add_node($node1) unless (exists $self->{graph}->{$node1});
	$self->add_node($node2) unless (exists $self->{graph}->{$node2});
	if ($node1 eq $node2){
		print "cannot connect $node1 to itself\n" if $self->{debug};
		return;
	}
    $self->{graph}->{$node1}->{$node2} = $self->{graph}->{$node2}->{$node1} = 1;
    print "added a new edge between $node1 and $node2\n" if $self->{debug};
}
sub print_graph {
    my $self = shift;
    my $graph=$self->{graph};
    my @nodes = sort keys %$graph;
    my @neighbours;
    my( $nodecnt, $edgecnt ) = $self->nodes_edges();
    
    print "Nodes: $nodecnt\n";
    print "Edges: $edgecnt\n";
    print "Nodes and neighbours:\n";
    foreach my $node (@nodes) {
        @neighbours = sort keys %{$graph->{$node}};
        print "$node: @neighbours\n";
    }
}

sub nodes_edges {
    my $self = shift;
    my $graph=$self->{graph};
    my ($nodecnt, $edgecnt);
    my @nodes = keys %$graph;
    
    $nodecnt = @nodes;
    $edgecnt = 0;
    
    foreach my $node (@nodes)
    { 
        $edgecnt += keys %{$graph->{$node}};
    }
    $edgecnt /= 2;
    
    return ($nodecnt, $edgecnt);
}

sub connected_component {
    my ($self, $node) = @_;
    my $graph=$self->{graph};
    my ($currentnode, $neighbour);
    my $component = { $node, 1 };
    my @todo = ( $node );
    
    while( @todo > 0 ) {
        $currentnode = pop @todo;
        foreach $neighbour (keys %{$graph->{$currentnode}}) {
            unless (exists $component->{$neighbour} ) {
                $component->{$neighbour} = 1;
                push @todo, $neighbour;
            }
        }
    }
    return( $component );
}

sub all_components {
    my $self = shift;
    my $graph=$self->{graph};
    my $connected_components = [];

    foreach my $node (keys %$graph) {
        my $exists = 0;
        foreach my $component (@$connected_components) {
            if( exists $component->{$node} ){
                $exists = 1;
                last;
            }
        }
        push @$connected_components, $self->connected_component($node) unless ( $exists );
    }
    
    return( $connected_components );
}


1;
