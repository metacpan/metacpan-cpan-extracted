package Tk::IDElayoutDropSite;
our ($VERSION) = ('0.33');

use base  qw(Tk::DropSite);

use strict;

Construct Tk::Widget 'IDElayoutDropSite';

=head1 NAME 

Tk::IDElayoutDropSite - Tk::DropSite widget with for the IDElayout Widget

=head1 DESCRIPTION

This is a L<Tk::DropSite> derived widget that handles drop-targets for the
L<Tk::IDElayout> widget, which features some special drag/drop behavoir.

=head1 SYNOPSIS

Usage is the same as normal Tk drag/drop usage, except when creating
the dropsite, use:

 use Tk::IDElayoutDropSite;
 
 my $dropSite = $widget->IDElayoutDropSite( ... );

=head1 ATTRIBUTES

=over 1

=item currentSide

Name of the current Side (left/right/top/bottom) in I<currentFrame> that has been dragged over, as part of a drag-drop
operation.

=item currentFrame

Name of the current Frame that has been dragged over, as part of a drag-drop operation.

=back

=head1 METHODS

=cut

=head2 Over

Overridden Over Method. 

This checks to see if we are dragging close to an edge of a frame. These edges are the drop targets for the
IDElayout widget.

=cut

sub Over{

	my $site = shift;
	my @args = @_;
	my ($X,$Y) = (@args);
		
	my $widget = $site->widget;
	
        my $val;
        
	if( defined($X) && defined($Y) ){
	
		my @pxy = $widget->pointerxy;
		
		# 1) Find out which frame we are in
		my @frameInfo = $widget->findFrame( @pxy );
	
		# Clear the member vars for the currentFrame and Side
                $site->{currentFrame} = undef;
                $site->{currentSide}  = undef;
		
		# 2) Find out which side of which frame we are closest to
		if (@frameInfo) {
			#print "--- FrameInfo = ".join(", ", @frameInfo)."\n";
			$site->{currentSide} = $widget->findSide(@pxy, @frameInfo);
			$site->{currentFrame}= $frameInfo[0];
			$val = defined($site->{currentSide});

		}
		else{   # Check to see if we are near the big/outer frame
			#print "Not In Frame\n";
			@frameInfo = $widget->findFrame(@pxy, {'outer' => $widget->toplevel});
			if( @frameInfo){
				$site->{currentSide}  = $widget->flashSide(@pxy, @frameInfo,{'outer' => $widget->toplevel});
				$site->{currentFrame} = $frameInfo[0];
				$val = defined($site->{currentSide});
			}
				
				

		}
		
				
			
			
			
	}

	return ( $val);
}

=head2 Enter

Overridden Enter Method.
        
This turns on the frame-side indicator that shows which frame is the active drop target.


=cut

sub Enter
{
 my ($site,$token,$event) = @_;

 my $widget = $site->widget;
 
 #print "############## In Enter: currentSide = ".$site->{currentSide}." currentFrame = ".$site->{currentFrame}."\n";
 $widget->flashSide($site->{currentSide}, $site->{currentFrame});
 
 $site->SUPER::Enter($token, $event);
}

######################################################
=head2 Leave

Overridden Leave Method.
        
This turns off the frame-side indicator that shows which frame is the active drop target.


=cut

sub Leave
{
 my ($site,$token,$event) = @_;

 my $widget = $site->widget;
 
 #print "############## In Leave: currentSide = ".$site->{currentSide}." currentFrame = ".$site->{currentFrame}."\n";
 $widget->flashSide();
 
 $site->SUPER::Leave($token, $event);
}



1;
