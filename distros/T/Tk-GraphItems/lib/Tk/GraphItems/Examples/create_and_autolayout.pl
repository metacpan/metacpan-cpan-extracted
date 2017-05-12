#!/usr/bin/perl -w



=head1 NAME

create_and_autolayout - Create a 'Graph' object by clicking/dragging and let Graph::Layout::Aesthetic do the layout.

=cut





use strict;
use warnings;
use Tk;
require Tk::GraphItems::Circle;
require Tk::GraphItems::Connector;
use Graph 0.70 ;
use Graph::Layout::Aesthetic::Topology;
use Graph::Layout::Aesthetic;


package main;
my $mw = tkinit();

# our Graph has to be refvertexed to use
# Tk::GraphItems::Circle instances for the nodes

my $graph = Graph->new( refvertexed => 1 );
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
Mouse bindings:
Shift-Button-1    create a new vertex here
Shift-Button3     delete this vertex
Button1-move      drag this vertex
Control-Button1   select/unselect  this vertex
Control-Button1   if another vertex is selected:
                  create an edge from the selected
                  vertex to this one or delete the
                  edge if it is present.
Control-D         delete all vertices
TEXT
;
$can-> createText(20,20,
		  -font     => ['Courier',10],
		  -text     => $text,
		  -anchor   => 'nw',
	      );
init_bindings($can);


my $repeat;
my $stop_button;
my ($temp,$centrip,$rep,$min_len)=(10,1,10000,0.01);

my $f1 = $mw->Frame()->pack;
my @frames= map {$f1->Frame()->pack(-side=>'left');} (0..2);
$frames[0]->Label(-text=>$_)->pack for ('temperature',
					'centripetal',
					'node_repulsion',
					'min_edge_length');

$frames[1]->Entry(-textvariable=>$_)->pack for (\$temp,
						\$centrip,
						\$rep,
						\$min_len);

{
my $aglo;

$frames[2]->Button(-text=>'start',
		   -width=>20,
		   -command=>sub{ 
		     $aglo = convert($graph);
		     set_aglo_coords($aglo,$graph);
		     if ($repeat){$repeat ->cancel}
		     $repeat = $mw->repeat(100,sub{iterate($aglo,$graph)})
		   }
	   )->pack;
$frames[2]->Button(-text=>'continue',
		   -width=>20,
		   -command=>sub{
		     set_aglo_coords($aglo,$graph);
		     if ($repeat){$repeat ->cancel}
		     $repeat = $mw->repeat(100,sub{iterate($aglo,$graph)})
		   }
	   )->pack;
$stop_button = $frames[2]->Button(-text    => 'stop',
                                  -width   => 20,
                                  -command => \&stop_cb,
                              )->pack;
}#end scope of $g, $aglo


MainLoop;

sub stop_cb{
    if ($repeat){$repeat ->cancel;
                 undef $repeat;
             }
    my @bb = $scrolled_can->bbox('all');
    $scrolled_can->configure(-scrollregion => \@bb);
}

sub iterate{
  my ($aglo,$g) = @_;
  $aglo->_gloss(0);
  $aglo->coordinates_to_graph( $g,
			       pos_attribute => ["x_end", "y_end"]);
}
sub convert{
  my $topo = Graph::Layout::Aesthetic::Topology->from_graph($_[0]);
  my $aglo = Graph::Layout::Aesthetic->new($topo);
  $aglo->add_force(node_repulsion  => $rep);
  $aglo->add_force(min_edge_length => $min_len);
  $aglo->add_force("Centripetal", => $centrip);
  $aglo->init_gloss($temp,0.0001,1000,0);
  return $aglo;
}
sub set_aglo_coords{
  my ($aglo,$graph) = @_;
  for my $v($graph->vertices){
    my $id = $graph->get_vertex_attribute($v,'layout_id');
    $aglo->coordinates($id,$v->get_coords);
  }
}

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
		       my ($wx, $wy)=($e->x, $e->y);
                       my $x = $can->canvasx($wx);
                       my $y = $can->canvasy($wy);
		       new_node( $can,$x,$y);
		   } );
    
    my $mw = $can->MainWindow;
    $mw->bind('<Control-d>',\&delete_all_vertices);
    
}# end init_bindings

sub new_node{
    # Create a new Circle instance and use it as vertex in
    # our Graph. The Circle will be destroyed when its vertex
    # gets deleted.

    my ( $can,$x,$y ) = @_;
#    my $v = Tk::GraphItems::Circle->new(canvas => $can,
        my $v = ColoredCircle->new(canvas => $can,
					colour => 'green',
					size   => 20,
					'x'    => $x,
					'y'    => $y);
    $graph->add_vertex($v);
    $graph->set_vertex_attribute($v,$_,0)for qw/x_end y_end/;

# yes, I know! the following line is a dirty trick and it should 
# *never* be done that way!
    $v->set_coords(\$graph->[2][4]{$v}[2]{x_end},\$graph->[2][4]{$v}[2]{y_end});
    $graph->set_vertex_attribute($v,'x_end',$x);
    $graph->set_vertex_attribute($v,'y_end',$y);

  return $v;
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

sub delete_all_vertices{
    $stop_button->Invoke;
    $graph->delete_vertices($graph->vertices);
}
