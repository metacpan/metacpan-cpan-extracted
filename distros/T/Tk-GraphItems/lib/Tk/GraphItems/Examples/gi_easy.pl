#!/usr/bin/perl -w

=head1 NAME

gi_easy - Demonstrates how to set up mouse bindings to create nodes and edges

=cut

use strict;
use warnings;
use Tk;
require Tk::GraphItems::TextBox;
require Tk::GraphItems::Connector;
require Tk::LabEntry;
my $mw = tkinit();

my %nodes;      # the simplest way to hold a 'model'
my %connectors;

my $scrolled_can = $mw -> Scrolled('Canvas',
				   -width        => 500,
				   -height       => 500,
				   -scrollregion => [0,0,500,500],
			       )->pack(-fill   => 'both',
				       -expand => 1);

# Extract the 'real' canvas out of the Scrolled widget :

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
Button3           Popup a context menu displaying
                  text, colour and coords of a vertex.
                  Edit text or colour fields to
                  change these properties
TEXT
;
$can-> createText(20,20,
		  -font     => ['Courier',10],
		  -text     => $text,
		  -anchor   => 'nw',
	      );

init_context_menu($can);
init_bindings($can);


MainLoop;


# create Tk::GraphItems bindings for the canvas instance
sub init_bindings{
    my ($can) = @_;

    # create a dummy node on our canvas to call bind_class with.
    # A call of 'bind_class' on this 'TextBox' instance installs
    # a binding which will be valid for every 'TextBox' item
    # on the same canvas.
    my $node = Tk::GraphItems::TextBox->new(canvas => $can,
					    'x'    => 0,
					    'y'    => 0
					);

    # Deleting a node:
    $node->bind_class("<Shift-Button-3>",
		      sub {
			  my $item = shift;
			  delete $nodes{$item};
			  delete $connectors{$item};
			  for (values %connectors){
			      delete $_->{$item}
			  }
		      }
		  );
    # Context Menu:
    $node->bind_class("<Button-3>",
		      sub {
			  my $item = shift;
			  my $menu = $can->{gi_easy_menu};
			  $menu->{properties}[1] = $item->text;
			  $menu->{properties}[2] = $item->colour;
			  my ($x,$y) = $item->get_coords;
			  $menu->{properties}[3] = $x;
			  $menu->{properties}[4] = $y;
			  $menu->Popup(-popover=>'cursor');
			  $menu->waitVariable(\$menu->{state});
			  $item->text($menu->{properties}[1]);
			  $item->colour($menu->{properties}[2]);
		      }
		  );

    # Adding and removing edges:
    my $selected;
    $node->bind_class("<Control-Button-1>",
		      sub { my $item = shift;
			    if ( !$selected ) {
				$selected = $item;
				$item -> colour('red');
			    } elsif ( $selected == $item ) {
				$item -> colour('white');
				$selected = undef;
			    } else {
				toggle_edge( $selected,$item );
				$selected -> colour('white');
				$selected = undef;
			    }
			}
		  );
    

    # A Tk-binding to create new nodes on Shift-B1:

    $can->Tk::bind("<Shift-Button-1>", sub {
		       my $e = $can->XEvent;
		       my ($mx, $my)=($e->x, $e->y);
		       new_node( $can,$mx,$my);
		   } );
    
}# end init_bindings

sub new_node{
    # Create a new TextBox instance and store a reference to it.
    # The TextBox will be destroyed when its reference gets deleted.

    my ( $can,$x,$y,$text ) = @_;
    my $v = Tk::GraphItems::TextBox->new(canvas=>$can,
					 text=> $text||'node',
				#	 font=> ['Courier',10],
					 'x'=> $x,
					 'y'=> $y);
    $nodes{$v}=$v;
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
    $connectors{$source}{$target} = $conn;
}

sub toggle_edge{
    my ( $source,$target ) = @_;
    if ($connectors{$source}{$target}){
	delete $connectors{$source}{$target};
    }else{
	new_edge( $source, $target );
    }
}


sub init_context_menu{
    my $canvas = shift;
    my $ctm = $canvas->Toplevel;
    $ctm->configure(-borderwidth => 2,
		    -relief      => 'groove',
		  );
    $ctm->overrideredirect(1);
    $ctm->bind('<Leave>',[\&menu_handle_leave,$ctm]);
    my $properties;
    my $n = 1;
    for (qw/text colour x y/){
	$ctm->LabEntry(-label        => "$_",
		       -textvariable => \$properties->[$n++],
		       -bg           => 'white'
		   )->pack;
    }
    $ctm->{properties} = $properties;
    $ctm->withdraw;
    $canvas->{gi_easy_menu} = $ctm;
}

sub menu_handle_leave{
    my ($w,$ctm) = @_;
    return unless $w == $ctm;# are we leaving the contextmenu
                             # or a subwidget?

    $ctm->{state} ++;        # a flag to signal withdrawing
    $ctm->withdraw;
}
