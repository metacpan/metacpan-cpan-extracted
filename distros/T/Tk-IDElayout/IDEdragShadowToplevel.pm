=head1 NAME 

Tk::IDEdragShadowToplevel - Shadow Outline for Showing Drag Motion or Drop Targets

=head1 SYNOPSIS

    use Tk::IDEdragShadowToplevel;

    $TabbedFrame = $widget->IDEdragShadowToplevel
       (
        -geometry => "30x30+10+30", # Format widthxheight+x+y
 	
       );



=head1 DESCRIPTION

This is a composite widget that implements a grey outline frame that can be used to show window shapes when
dragging, or drop-target areas. 

This differs from the releated L<Tk::IDEdragShadow> widget in that it acts like a top-level widget. It can be dragged
all around the desktop. L<Tk::IDEdragShadow> is a subwidget of a Mainwindow/Toplevel and can't be moved/displayed outside of it's
Mainwindow/Toplevel.

=head1 OPTIONS


=over 1

=item geometry

Geometry of the outline frame, in the form C<widthxheight+x+y>.


=back 

=head1 Advertised Subwidgets

=over 1

=item top/bot/left/right

4 separate L<Tk::Toplevel> components representing the top/bot/left/right element of the outline.

=back

=head1 ATTRIBUTES

None

=head1 Methods

=cut

package Tk::IDEdragShadowToplevel;

our ($VERSION) = ('0.33');

use Carp;
use strict;


use Tk;

use base qw/ Tk::Derived Tk::Frame/;


Tk::Widget->Construct("IDEdragShadowToplevel");

sub Populate {
    my ($cw, $args) = @_;
     
    $cw->SUPER::Populate($args);

    
    $cw->ConfigSpecs( 
		      -geometry => [ qw/METHOD geometry     geometry /,            undef ],
    );

    # Create components (Toplevels for each side of the shadow
    $cw->{top}    = $cw->Toplevel;
    $cw->{bot}    = $cw->Toplevel;
    $cw->{left}   = $cw->Toplevel;
    $cw->{right}  = $cw->Toplevel;
    
    $cw->{top}->overrideredirect(1);
    $cw->{bot}->overrideredirect(1);
    $cw->{left}->overrideredirect(1);
    $cw->{right}->overrideredirect(1);
    
    # Frames to populate each side
    $cw->{top}->Frame(-bg => 'darkgrey')->pack();
    $cw->{bot}->Frame(-bg => 'darkgrey')->pack();
    $cw->{left}->Frame(-bg => 'darkgrey')->pack();
    $cw->{right}->Frame(-bg => 'darkgrey')->pack();
    
    foreach (qw/ top bot left right /){
	    $cw->Advertise( $_ => $cw->{$_});
	    $cw->{$_}->deiconify
    }
 
  
    
}

#----------------------------------------------
# Sub called when -geometry option changed
#
sub geometry{
	my ($cw, $geometry) = @_;


	if(! defined($geometry)){ # Handle case where $widget->cget(-geometry) is called
		
		# Try the normal place where options are stored, if not there
		#   try the alternate location, incase widget has gone away.
		if( defined( $geometry = $cw->{Configure}{-geometry} )){
			return $geometry;
		}
		else{
			return $cw->{-geometry};
		}
		
	}
	
	# Figure out length/width of top/bot/left/right
	my ($top,$bot,$left,$right) = (@$cw{ qw/ top bot left right /});
	
	my ($w,$h,$x,$y);
	unless( ($w, $h, $x, $y) = $geometry =~ /(\d+)x(\d+)\+(\d+)\+(\d+)/ ){
		croak("Error: -geometry should be specified in format 'WxH+X+Y'\n");
	}
	
	my $bd = 3;
	
	#print "Top = $top\n";

	my $geo = $w."x".$bd."+".$x."+".$y;
	$top->geometry ($geo);
	
	$geo = $w."x".$bd."+".$x."+".($y+$h-$bd);
	$bot->geometry ( $geo );

	$geo = $bd."x".$h."+".$x."+".$y;
	$left->geometry ( $geo );

	$geo = $bd."x".$h."+".($x+$w-$bd)."+".$y;
	$right->geometry ( $geo );
	
	$cw->{width} = $w;
	$cw->{height} = $h;
	
	foreach ($top,$bot,$left,$right){
		$_->raise;
	}
	
	$cw->{Configure}{-geometry} = $geometry;
}

#############################################################

=head2 MoveToplevelWindow

Moves the whole widget to a new location on the screen.

B<Usage:>
     
	$widget->moveToplevelWindow($x,$y);
	
	where:
	  $x/$y  are the x/y screen coords to move the upper right
	         corner of the widget to.


=cut

sub MoveToplevelWindow{
	
	my $self = shift;
	my ($x,$y) = @_;

	
	my ($top,$bot,$left,$right) = (@$self{ qw/ top bot left right /});
	my ($w,$h) = @$self{ qw/ width height/};

	my $bd = 3;
	
	$top->MoveToplevelWindow($x,$y);
	$bot->MoveToplevelWindow($x,$y+$h-$bd);
	
	$left->MoveToplevelWindow($x,$y);
	$right->MoveToplevelWindow($x+$w-$bd, $y);
	
	# Update geometry
	$self->{Configure}{-geometry} = $w."x".$h."+".$x."+".$y;
	#print "Updated geometry to '".$self->{Configure}{-geometry}."\n";
	$self->{-geometry} = $self->{Configure}{-geometry}; # Save a copy so we can get the geometry right after
	                                                    # it goes away
}

#############################################################
#

=head2 deiconify

Deiconify (i.e. make visible) the whole widget. This would normally be called after calling I<withdraw> to make
the widget visible again.


B<Usage:>
     
	$widget->deiconify;
	

=cut

sub deiconify{
	
	my $self = shift;

	
	my ($top,$bot,$left,$right) = (@$self{ qw/ top bot left right /});

	foreach my $element( $top,$bot,$left,$right ){
		$element->deiconify;
	}
	
}

#############################################################
#

=head2 withdraw

Withdraw (i.e. withdraw from the screen) the whole widget.


B<Usage:>
     
	$widget->withdraw;
	

=cut

sub withdraw{
	
	my $self = shift;

	
	my ($top,$bot,$left,$right) = (@$self{ qw/ top bot left right /});

	foreach my $element( $top,$bot,$left,$right ){
		$element->withdraw;
	}
	
}


1;
