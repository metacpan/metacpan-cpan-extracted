=head1 NAME 

Tk:IDEdragShadow - Shadow Outline for Showing Drag Motion or Drop Targets

=head1 SYNOPSIS

    use Tk:IDEdragShadow;

    $TabbedFrame = $widget->DragShadow
       (
        -geometry => "30x30+10+30", # Format widthxheight+x+y
 	
       );



=head1 DESCRIPTION

This is a composite widget that implements a grey outline frame that can be used to show window shapes when
dragging, or drop-target areas.

=head1 OPTIONS


=over 1

=item geometry

Geometry of the outline frame, in the form C<widthxheight+x+y>.


=back 

=head1 Advertised Subwidgets

=over 1

=item top/bot/left/right

4 separate L<Tk::Frame> components representing the top/bot/left/right element of the outline.

=back

=head1 ATTRIBUTES

None

=head1 Methods

=cut

package Tk::IDEdragShadow;
our ($VERSION) = ('0.33');

use Carp;
use strict;


use Tk;

use base qw/ Tk::Derived Tk::Frame/;


Tk::Widget->Construct("IDEdragShadow");

sub Populate {
    my ($cw, $args) = @_;
     
    $cw->SUPER::Populate($args);

    
    $cw->ConfigSpecs( 
		      -geometry => [ qw/METHOD geometry     geometry /,            undef ],
    );

    # Create components
    my $toplevel = $cw->toplevel;
    $cw->{top}  = $toplevel->Frame(-bg => 'darkgrey');
    $cw->{bot}  = $toplevel->Frame(-bg => 'darkgrey');
    $cw->{left} = $toplevel->Frame(-bg => 'darkgrey');
    $cw->{right}= $toplevel->Frame(-bg => 'darkgrey');
    
    foreach (qw/ top bot left right /){
	    $cw->Advertise( $_ => $cw->{$_});
    }
 
    
    
}

#----------------------------------------------
# Sub called when -geometry option changed
#
sub geometry{
	my ($cw, $geometry) = @_;


	if(! defined($geometry)){ # Handle case where $widget->cget(-$array) is called

		return $cw->{Configure}{-geometry}
		
	}
	
	# Figure out length/width of top/bot/left/right
	my ($top,$bot,$left,$right) = (@$cw{ qw/ top bot left right /});
	
	my ($w,$h,$x,$y);
	unless( ($w, $h, $x, $y) = $geometry =~ /(\d+)x(\d+)\+(\d+)\+(\d+)/ ){
		croak("Error: -geometry should be specified in format 'WxH+X+Y'\n");
	}
	
	my $bd = 3;
	
	$top->configure(  -width => $w, -height => $bd);
	$bot->configure(  -width => $w, -height => $bd);
	$left->configure( -width => $bd,  -height => $h);
	$right->configure(-width => $bd,  -height => $h);

	$top->place(
		-x=>$x,
		-y=>$y,
		-width=> $w,
		-height=>$bd
	);
	$bot->place(
		-x=>$x,
		-y=>$y+$h-$bd,
		-width=> $w,
		-height=> $bd
	);
	$left->place(
		-x=>$x,
		-y=>$y,
		-width=>$bd,
		-height=>$h
	);
	$right->place(
		-x=>$x+$w-$bd,
		-y=>$y,
		-width=>$bd,
		-height=>$h);

	foreach ($top,$bot,$left,$right){
		$_->raise;
	}
}

#############################################################
#

=head2 placeForget

Forgets the placement (removes from display) of the shadow.

=cut

sub placeForget{
	
	my $self = shift;
	my ($top,$bot,$left,$right) = (@$self{ qw/ top bot left right /});
	
	foreach ($top,$bot,$left,$right){
		$_->placeForget();
	}

}


1;
