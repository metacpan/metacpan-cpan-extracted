#!/usr/bin/perl -w

use strict;
use warnings;
use Tk;
require Tk::GraphItems::Circle;
require Tk::GraphItems::Connector;
use Graph 0.70 ;
use Data::Dumper;
my $mw = tkinit();

# our Graph has to be refvertexed to use
# Tk::GraphItems::Circle instances for the nodes

my $graph = Graph->new(refvertexed=>1);
my $scrolled_can = $mw -> Scrolled('Canvas',
				   -width        => 500,
				   -height       => 500,
				   -scrollregion =>[0,0,500,500],
			       )->pack(-fill   => 'both',
				       -expand => 1);

# for use with Tk::GraphItems we have to extract the
# 'real' canvas out of the Scrolled widget :

my $can = $scrolled_can->Subwidget('scrolled');
my $text =<<'TEXT'
Mouse bindings are as follows:
Shift-Button-1    create a new vertex here
Shift-Button3     delete this vertex
Button1-move      drag this vertex
Control-Button1   select/unselect  this vertex
Control-Button1   if another vertex is selected:
                  create an edge from the selected
                  vertex to this one or delete the
                  edge if it is present.
TEXT
;
$can-> createText(20,20,
		  -font     => ['Courier',10],
		  -text     => $text,
		  -anchor   => 'nw',
	      );
init_bindings($can);

MainLoop;


# create Tk::GraphItems bindings for the canvas instance

sub init_bindings{
    my ($can) = @_;

    # create a dummy node on our canvas to call bind_class with.
    # A call of 'bind_class' on this 'Circle' instance installs
    # a binding which will be valid for every 'Circle' item
    # on the same canvas.
    my $node = Tk::GraphItems::Circle->new(canvas => $can,
					    'x'    => 0,
					    'y'    => 0
					);

    # Deleting a node:
    $node->bind_class("<Shift-Button-3>",
		      sub {
			  my $item = shift;
			  $graph->delete_vertex($item);
		      }
		  );

    # Adding and removing edges:
    my ($selected, $old_colour);
    $node->bind_class("<Control-Button-1>",
		      sub { my $item = shift;
			    if ( !$selected ) {
				$selected   = $item;
				$old_colour = $item->colour;
				$item -> colour('red');
			    } elsif ( $selected == $item ) {
				$item -> colour($old_colour);
				$selected = undef;
			    } else {
				toggle_edge( $selected,$item );
				$selected -> colour($old_colour);
				$selected = undef;
			    }
			}
		  );


    # A Tk-binding to create new nodes:

    $can->Tk::bind("<Shift-Button-1>", sub {
		       my $e = $can->XEvent;
		       my ($mx, $my)=($e->x, $e->y);
		       new_node( $can,$mx,$my);
		   } );
    
}# end init_bindings

sub new_node{
    # Create a new Circle instance and use it as vertex in
    # our Graph. The Circle will be destroyed when its vertex
    # gets deleted.

    my ( $can,$x,$y ) = @_;
    my $v = Tk::GraphItems::Circle->new(canvas => $can,
					colour => 'green',
					size   => 20,
					'x'    => $x,
					'y'    => $y);
    $graph->add_vertex($v);
}

sub new_edge{
    # Create a Connector with 'autodestroy' set to true so we don't
    # need to 'detach' it to have it destroyed.

    my ( $source,$target) = @_;
    my $conn = Tk::GraphItems::Connector->new( source      => $source,
					       target      => $target,
					       autodestroy => 1,
					  );
    
    # create a new edge in the Graph and store our new Connector in
    # the edges attribute data. That way the Connector will be destroyed
    # when its edge gets deleted.

    $graph->add_edge( $source , $target);
    $graph->set_edge_attribute($source, $target, 'Connector', $conn);
}

sub toggle_edge{
    my ( $source,$target ) = @_;
    if ($graph->has_edge( $source, $target )){
	$graph->delete_edge( $source, $target );
    }else{
	new_edge( $source, $target );
    }
}


