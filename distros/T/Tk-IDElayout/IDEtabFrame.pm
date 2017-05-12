=head1 NAME 

Tk::IDEtabFrame - Tabbed Notebook Widget for a IDE Environment

=head1 SYNOPSIS

    use Tk::IDEtabFrame;

    $TabbedFrame = $widget->IDEtabFrame
       (
        # Tk::DynaTabFrame Options:
        -font => $font,
        -raisecmd => \&raise_callback,
        -raisecolor => 'green',
        -tabclose => sub { 
                my ($dtf, $caption) = @_; 
                $dtf->delete($caption);
                },
        -tabcolor => 'yellow',
        -tabcurve => 2,
        -tablock => undef,
        -tabpadx => 5,
        -tabpady => 5,
        -tabrotate => 1,
        -tabside => 'nw',
        -tabscroll => undef,
        -textalign => 1,
        -tiptime => 600,
        -tipcolor => 'yellow',
	
	# Additional Options added by IDEtabFrame
	-raisedfg => 'black',
	-raisedActivefg => 'red',
	
	-raisedCloseButtonfg => 'black',
	-raisedCloseButtonbg => 'lightgrey',
	-raisedCloseButtonActivefg => 'red',
	-raisedCloseButtonActivebg => 'white',
	
	-noraisedfg => 'grey60',
	-noraisedActivefg => 'black',
	
	-noraisedCloseButtonfg => 'lightgrey',
	-noraisedCloseButtonbg => 'white',
	-noraisedCloseButtonActivefg => 'red',
	-noraisedCloseButtonActivebg => 'white',
	
        [normal frame options...],
	
       );



=head1 DESCRIPTION

This is a subclass of the L<Tk::DynaTabFrame> widget that adds some additional
options that affect the appearance and behaviour for use as part of a Integrated
Development Environment (IDE), similar to I<Eclipse>, etc.
	
=head1 DRAG-DROP SUPPORT

Tabs can be dragged to the tab-frame area of other (or the same) IDEtabFrame widget.
This will move the dragged tab and widget to the new IDEtabFrame widget.

Tabs can also be dragged outside the widget to become separate I<Tool-Windows>. These windows can be dragged from 
a drag-area at the top of the I<Tool-Window> and dropped
back into a IDEtabFrame widget.


=head1 OPTIONS

In addition to the options from the parent class L<Tk::DynaTabFrame>, this widget provides the following options:

=over 1

=item raisedfg

Foreground color of the notebook tab that has been raised.

=item raisedActivefg

Active foreground color (i.e. the color when the mouse hovers over it)
of the notebook tab that has been raised.

=item raisedCloseButtonfg

Foreground color of the I<Close> button (i.e. the 'X') for the raised tab.

=item raisedCloseButtonbg

Background color of the I<Close> button for the raised tab.

=item raisedCloseButtonActivefg

Active foreground color (i.e. the color when the mouse hovers over it) of the I<Close> button for the raised tab.

=item raisedCloseButtonActivebg

Active background color (i.e. the color when the mouse hovers over it) of the I<Close> button for the raised tab.

=item noraisedfg

Foreground color of the notebook tabs that have not been raised.

=item noraisedActivefg

Active foreground color (i.e. the color when the mouse hovers over it)
of the notebook tabs not raised.

=item noraisedCloseButtonfg

Foreground color of the I<Close> button (i.e. the 'X') for the tabs not raised.

=item noraisedCloseButtonbg

Background color of the I<Close> button for tabs not raised.

=item noraisedCloseButtonActivefg

Active foreground color (i.e. the color when the mouse hovers over it) of the I<Close> button for the tabs not raised.

=item noraisedCloseButtonActivebg

Active background color (i.e. the color when the mouse hovers over it) of the I<Close> button for the tabs not raised.

=item defaultFrameConfig

Array Ref of default options used to create new tab-frames. Defaults to 
  
  (-relief => 'flat', -bg => 'steelblue4', -bd => 2)
  
=item lastTabDeleteCallback

Optional Callback (i.e. subref) to execute after when the last tab is deleted. This can be used to perform cleanup, remove/unpack the
tabframe from the parent display, etc.


=back 

=head1 ATTRIBUTES

=over 1

=item dragImage

L<Tk::Photo> object of the image displayed when dragging data. Optional.

=item dropSite

L<Tk::DropSite> object of attached to the tab frame for the notebook widget. This provides a drop
target for dropping other widgets into the notebook as new tabs. 

=item dragShadow

L<Tk::IDEdragShadow> object used to show drag/drop drop targets.

=item endDragActions

Array Refs of callbacks to execute at the end of a drag operation. Typically this will be set to delete or 
add a tab to the dialog after a drag operation has been completed.

=item dragging

Flag = 1 if we are currently in a drag operation for this object.

=back

=head1 Class Data

=over 1

=item Dropbox

Hash of objects. Since the Tk Drag/Drop mechanism only supports passing strings around, this hash
is used as a "dropbox" where the source can put a object in this hash, key'ed by a text name. This
name is passed to the target (i.e. the drop location). The target can use the string to lookup the
real object in this hash.


=head1 Methods

=cut

package Tk::IDEtabFrame;
our ($VERSION) = ('0.33');

use Carp;
use strict;


use Tk;
use Tk::IDEdragDrop;
use Tk::DropSite;
use Tk::IDEdragShadow;
use Tk::CaptureRelease;
use Tk::IDElayout::DropBox; # Used for temp storage during drag/drop operations

use base qw/ Tk::Derived Tk::DynaTabFrame/;

our ($DEBUG); 

Tk::Widget->Construct("IDEtabFrame");

sub Populate {
    my ($cw, $args) = @_;
     
    $cw->SUPER::Populate($args);

    
    $cw->ConfigSpecs( 
		      -raisedfg => [ qw/PASSIVE raisedfg     raisedfg/, 'black' ],
		      -raisedActivefg => [ qw/PASSIVE raisedActivefg     raisedActivefg/, 'black' ],
		      -raisedCloseButtonfg => [ qw/PASSIVE raisedCloseButtonfg     raisedCloseButtonfg/, 'black' ],
		      -raisedCloseButtonbg => [ qw/PASSIVE raisedCloseButtonbg     raisedCloseButtonbg/, 'lightgrey' ],
		      -raisedCloseButtonActivefg => [ qw/PASSIVE raisedCloseButtonActivefg     raisedCloseButtonActivefg/, 'red' ],
		      -raisedCloseButtonActivebg => [ qw/PASSIVE raisedCloseButtonActivebg     raisedCloseButtonActivebg/, 'lightgrey' ],

		      -noraisedfg => [ qw/PASSIVE noraisedfg     noraisedfg/, 'grey60' ],
		      -noraisedActivefg => [ qw/PASSIVE noraisedActivefg     noraisedActivefg/, 'grey60' ],
		      -noraisedCloseButtonfg => [ qw/PASSIVE noraisedCloseButtonfg     noraisedCloseButtonfg/, 'black' ],
		      -noraisedCloseButtonbg => [ qw/PASSIVE noraisedCloseButtonbg     noraisedCloseButtonbg/, 'lightgrey' ],
		      -noraisedCloseButtonActivefg => [ qw/PASSIVE noraisedCloseButtonActivefg     noraisedCloseButtonActivefg/, 'red' ],
		      -noraisedCloseButtonActivebg => [ qw/PASSIVE noraisedCloseButtonActivebg     noraisedCloseButtonActivebg/, 'lightgrey' ],
		      -defaultFrameConfig => [ qw/PASSIVE defaultFrameConfig     defaultFrameConfig/, [-relief => 'flat', -bg => 'steelblue4', -bd => 2] ],
		      -lastTabDeleteCallback => [ qw/METHOD lastTabDeleteCallback     lastTabDeleteCallback/, undef ],

    );


        # This keeps tab contents from being obscured after drag/drop events
        #   Similar to the parent ConfigDebounce method, but this calls TabReconfig more often, 
        #     which is enough to avoid the problem.
        $cw->bind('<Configure>',sub{
                        
        
                        $cw->afterCancel($cw->{LastAfterID}) if defined($cw->{LastAfterID});
        
                        $cw->{LastAfterID} = $cw->after(200, # $cw->cget('-delay'), 
                                sub {
                                        $cw->TabReconfig();
                                        delete $cw->{LastAfterID};
                                }
                        );
        });

    
}


#----------------------------------------------
# Sub called when -lastTabDeleteCallback option changed
#
sub lastTabDeleteCallback{
	my ($cw, $lastTabDeleteCallback) = @_;


	if(! defined($lastTabDeleteCallback)){ # Handle case where $widget->cget(-$array) is called

		return $cw->{Configure}{-lastTabDeleteCallback}
		
	}
	else{
	
		# Make A Tk::Callback Object
		$cw->{Configure}{-lastTabDeleteCallback} = Tk::Callback->new($lastTabDeleteCallback);
	}
	


}

#############################################################
#

=head2 TabCreate

Over-ridden method to create tabs. 

Calls the parent tabCreate, then applies extra look options

=cut

sub TabCreate{
	
	my $self = shift;
	my @args = @_;
		
	my $Caption = $args[0]; # Name of tab being added
	
	my $widget = $self->SUPER::TabCreate(@args);
	
	
	my $clientHash = $self->{ClientHash};
	my $clientList = $self->{ClientList};
	
	return unless( @$clientList); # Skip if no clients
		
	# Make lookup of client names to client frames
	my @clientFrames =  map $clientList->[$clientHash->{$_}][0], keys %$clientHash;
	
	my %clientFrames;
	@clientFrames{ keys %$clientHash} = @clientFrames;
	
	my $ButtonFrame = $self->{ButtonFrame};
	
		
	my $pageFrame = $clientFrames{$Caption};
	my $TabFrame = $ButtonFrame->Subwidget('Button_'.$pageFrame);
	#$TabFrame->configure(-bd => 2 );
	my $TabButton = $TabFrame->Subwidget('Button');
	
	my $dragToken;
	$dragToken = $TabButton->IDEdragDrop(
	  -event  => '<Any-B1-Motion>',  
	  -sitetypes => ['Local'],
	  -handlers => [[sub{ 
	  			# print "In Handler\n";
				my ($contents) = $widget->packSlaves();
                                my @packInfo = $contents->packInfo();
	  			my $data = {
                                        "DragSource" => $TabButton, "Object" => $self,
                                        "Caption" => $Caption, "Contents" =>  $contents,
                                        "PackInfo"=> [@packInfo]
                                };
                                
				# Put data in dropbox, key'ed by ref address
                                my $DropBox = Tk::IDElayout::DropBox->instance();
                                $DropBox->set("$data", $data);
				# Delete Tab from object
				my $endDragAction = sub{ $self->delete($Caption)};
				
				# Create array ref of endDragActions, if not defined already
				$self->{endDragActions} = [] unless( defined($self->{endDragActions}));
				
				push @{$self->{endDragActions}}, $endDragAction;
				$self->{dropped} = 1; # Flag to indicate that the drag has dropped
	  			return "$data";
	  		    }
	  		],
	  		],
	  -startcommand => [$self, 'startDrag', \$dragToken, $widget],
	  -endcommand => [$self, 'endDrag', \$dragToken, $widget],
	);


	unless( defined($self->{dropSite})){ # Create dropSite, if we don't have one already
		my $dropSite = $ButtonFrame->DropSite(
			-droptypes     => ['Local'],
			-dropcommand   => [ $self, 'drop' ],
			-entercommand => [$self, 'dragDropEnterLeave', \$dragToken], 
		);
		$self->{dropSite} = $dropSite;
	}

	unless( defined($self->{dragShadow})){ # Create DropShadow, if we don't have one already
		my $dragShadow = $ButtonFrame->IDEdragShadow();
		$self->{dragShadow} = $dragShadow;
	}

	
	# my $closeButton = $TabFrame->Subwidget('CloseBtn');

	# Apply default frame configuration
	my $frameConfig = $self->cget(-defaultFrameConfig);
	$widget->configure(@$frameConfig) if (@$frameConfig);	
	
	return $widget;

}

#######################################################################

=head2 TabRaise

Over-ridden method to raise a tab 

Calls the parent TabRase, then applies extra look options

=cut

sub TabRaise{
	
	my $self = shift;
	my @args = @_;
		
	my $widget = $self->SUPER::TabRaise(@args);
	
	my $clientHash = $self->{ClientHash};
	my $clientList = $self->{ClientList};
	my $Raised     = $self->{Raised};
	
	return unless( @$clientList); # Skip if no clients
	my ($raised) = grep $clientList->[$_][0] eq $Raised, (0..(scalar(@$clientList)-1));
	
	my %raiseLookup = reverse(%$clientHash);
	
	my $raiseName = $raiseLookup{$raised}; # Name of the currently raised tab
	#print "RaiseName = $raiseLookup{$raised}\n";

	#  Get current options
	my ($raisedfg, $raisedActivefg) = map $self->cget($_), (-raisedfg, -raisedActivefg);	
	my ($raisedCloseButtonfg, $raisedCloseButtonbg, $raisedCloseButtonActivefg, $raisedCloseButtonActivebg) = 
		map $self->cget($_), (-raisedCloseButtonfg, -raisedCloseButtonbg, -raisedCloseButtonActivefg, -raisedCloseButtonActivebg);
	my ($noraisedfg, $noraisedActivefg) = map $self->cget($_), ( -noraisedfg, -noraisedActivefg);	
	my ($noraisedCloseButtonfg, $noraisedCloseButtonbg, $noraisedCloseButtonActivefg, $noraisedCloseButtonActivebg) = 
		map $self->cget($_), ( -noraisedCloseButtonfg, -noraisedCloseButtonbg, -noraisedCloseButtonActivefg, -noraisedCloseButtonActivebg);

	# Apply Options to all tabs
	my @allTabs = $self->pages();
		
	# Make lookup of client names to client frames
	my @clientFrames =  map $clientList->[$clientHash->{$_}][0], keys %$clientHash;
	
	my %clientFrames;
	@clientFrames{ keys %$clientHash} = @clientFrames;
	
	my $ButtonFrame = $self->{ButtonFrame};
	
	my $Xfont = $self->{Xfont}; # Font used to display the "X"
        
        my $maxWidgetWidth = 0;
        my $maxWidgetHeight = 0;
	
	foreach my $page($self->pages){
		
		my $pageFrame = $clientFrames{$page};
                
                # This is needed to keep some widgets from being unmapped when other IDEtabframes
                #   are deleted in the IDElayout GUI (Not sure why).
                $pageFrame->eventGenerate('<Configure>');

		# get the frame contents, so we can raise/lower in the stacking order
		my ($pageContents) = $pageFrame->packSlaves();
		
                my $widgetWidth = $pageFrame->reqwidth;
                my $widgetHeight= $pageFrame->reqheight;
                
                $maxWidgetWidth = $widgetWidth  if( $widgetWidth  > $maxWidgetWidth);
                $maxWidgetHeight= $widgetHeight if( $widgetHeight > $maxWidgetHeight);
                
		my $TabFrame = $ButtonFrame->Subwidget('Button_'.$pageFrame);
		#$TabFrame->configure(-bd => 2 );
		my $TabButton = $TabFrame->Subwidget('Button');
		my $closeButton = $TabFrame->Subwidget('CloseBtn');
				
		unless (defined($Xfont)){
			my $normFont = $closeButton->cget(-font);
			my $size = $normFont->actual(-size);
			#print "$normFont size = $size\n";
			$Xfont = $self->{Xfont} = $normFont->Clone( -weight => 'bold');	
		}			

		$closeButton->configure(-text => 'X', -anchor => 'center', -image => undef);
		$closeButton->configure(-font => $Xfont, -relief => 'flat', -padx => 0, -pady => 0);
		
		# Set color to raiseFG or noRaiseFG, based on which page is raised
		if( $page eq $raiseName){
			$pageContents->raise() if($pageContents);
			$TabButton->configure(-foreground => $raisedfg, 
			                      -activeforeground => $raisedfg);
			$pageFrame->focus();	
			$closeButton->configure( -bg => $raisedCloseButtonbg, -fg => $raisedCloseButtonfg,
					-activeforeground => $raisedCloseButtonActivefg, 
					-activebackground => $raisedCloseButtonActivebg);
		}
		else{
			$pageContents->lower() if($pageContents);
			$TabButton->configure(-foreground => $noraisedfg,
			                      -activeforeground => $noraisedActivefg);
			$closeButton->configure( -bg => $noraisedCloseButtonbg, -fg => $noraisedCloseButtonfg,
					-activeforeground => $noraisedCloseButtonActivefg, 
					-activebackground => $noraisedCloseButtonActivebg);
			
		}
	}
        
        # Set to the max width/height of the managed frames to the total widget will request the
        #  correct width/height
        $self->{ClientFrame}->configure(-width => $maxWidgetWidth, -height => $maxWidgetHeight );
	
	return $widget;
}

#######################################################################

=head2 startDrag

Method called with a drag operation starts. Changes drag
cursor.

=cut

sub startDrag{

	my $self = shift;
	my $dndTokenRef = shift;
	my $tabFrame  = shift;   # Frame in the current dragged frame
	
	my ($contents) = $tabFrame->packSlaves(); # Get the contents of the dragged frame

	#print "In IDEtabFrame StartDrag\n" if($DEBUG);

	my $dragImage = $self->dragImage;
	 $$dndTokenRef->configure( -image => $dragImage);
	 
	# Get the requested width/height of the contents, for use with the DragShadowtopLevel
	# Also get the rootx/y and pointer x/y so we can calculate the offset for DragShadowToplevel
	#  This will make the drag shadow have the same size as the tab-frame being dragged.
	#print "Contents = $contents\n" if($DEBUG); 
	 my $w = $contents->width;
	 my $h = $contents->height;
	 my $rootx = $contents->rootx;
	 my $rooty = $contents->rooty;
	 my $pointerx = $contents->pointerx;
	 my $pointery = $contents->pointery;
	 
	 my $offsetX = $pointerx - $rootx;
	 my $offsetY = -3;  # Offset y set to small number so the drag shadow will be slightly next to the mouse pointer

         # Offsets must be a little bit greater than zero, otherwise the cursor
         #   could be right on the shadow, causing the drop target to be obscured.
         $offsetX = 3 if( $offsetX < 3 );
         $offsetY = 3 if( $offsetY < 3 );
	 
	 #print "req width/height = $w/$h\n" if($DEBUG);
	 #print "offsetX/Y = $offsetX/$offsetY\n"  if($DEBUG);
	 
	$$dndTokenRef->DragShadowToplevelConfig($w, $h,-$offsetX,-$offsetY);
	 $self->{dragging} = 1;

	return 0;

}

##################################################

=head2 endDrag

Method called when a drag operation end. Clears
out the currentDrag class data.

=cut

sub endDrag {

	my $self = shift;
	my $dndTokenRef = shift;
	my $tabFrame  = shift;   # Frame in the current dragged frame
	
	my ($contents) = $tabFrame->packSlaves(); # Get the contents of the dragged frame
	#print "Enddrag\n";
	 
	 if( defined($self->{endDragActions}) ){
		 my $actions = $self->{endDragActions};
		 
		 # Go thru each action
		 while( @$actions){
			 my $action = shift @$actions;
			 $action->(); # execute action
		 }
	 }
	 	 
	 if( !$self->{dropped} && $self->{dragging} ){ # Create a new toplevel window if dragged with no target
		#print "Not Dropped .......\n" if($DEBUG);
		$$dndTokenRef->DragShadowToplevelHide(); # Hide the dragshadow Toplevel
		
		# find the caption of the current tab dragged
		my $clientHash = $self->{ClientHash};
		my $clientList = $self->{ClientList};
		
		if( @$clientList){ # Skip if no clients
			
			# Get the caption for the currently dragged frame by
			#   Making lookup of client Frames (stringified) to client names
			my @clientFrames =  map $clientList->[$clientHash->{$_}][0], keys %$clientHash;
		
			my %clientFrames;
			@clientFrames{ @clientFrames } = keys %$clientHash;
			
			my $caption = $clientFrames{$tabFrame};

                        # Get the packing info for the contents and attach to the toolwindow
                        #  This will be used if the toolwindow is dragged back into a IDEtabFrame
                        my %PackInfo = $contents->packInfo();
                        delete $PackInfo{-in};  # delete the -in option, not relavent
			
			#print "Deleting Caption = $caption\n" if($DEBUG);
			# Delete tab from the dialog and make a new toplevel window
			$self->delete($caption);
			
			my $geometry = $$dndTokenRef->DragShadowToplevelGeometry(); # Hide the dragshadow Toplevel
			#print "Top Level geometry = '$geometry'\n" if($DEBUG);

			$contents->wmRelease;
			# MainWindow needed here because wmReleased widget don't properly inherit from
			#   Tk::Toplevel
			$contents->MainWindow::attributes(-toolwindow => 1) if( $^O =~ /mswin32/i);
			$contents->MainWindow::title($caption);
			$contents->MainWindow::geometry($geometry);
 			$contents->MainWindow::deiconify;
			$contents->raise;

                        $contents->{_PackInfo} = [%PackInfo]; # attach the packInfo
 			
			# Configure the new toolwindow so that we can drag it back to a tabFrame
			$self->toolWindowConfigure($contents);
			
		}

	 }
	 
	 $self->{dragging} = 0;
	 $self->{dropped}  = 0;


	
}

=head2 dragImage

Gets (and optionally sets) the value of the object's dragImage object

B<Usage:>

	$self->dragImage();    # Get dragImage
	$self->dragImage(...); # Set dragImage


=cut

sub dragImage{
    my $self = shift;
    if (defined $_[0]) { $self->{dragImage} = $_[0] };

    # Create drag image, if not defined
    unless( defined( $self->{dragImage})){
	    	my $dragImage = $self->Photo("dragImage", -data => 'R0lGODlhEAAQAIIAAPwCBAQCBAT+/Pz+/KSipPz+BAAAAAAAACH5BAEAAAAALAAAAAAQABAAAANFCBDc7iqIKUW98WkWpx1DAIphR41ouWya+YVpoBAaCKtMoRfsyue8WGC3YxBii5+RtiEWmASFdDVs6GRTKfCa7UK6AH8CACH+aENyZWF0ZWQgYnkgQk1QVG9HSUYgUHJvIHZlcnNpb24gMi41DQqpIERldmVsQ29yIDE5OTcsMTk5OC4gQWxsIHJpZ2h0cyByZXNlcnZlZC4NCmh0dHA6Ly93d3cuZGV2ZWxjb3IuY29tADs='
	 	);
		$self->{dragImage} = $dragImage;
    }

    return $self->{dragImage};
}

##################################################

=head2 dragDropEnterLeave

Method called when dragging and the mouse pointer enters or leaves
a drop area.

=cut

sub dragDropEnterLeave{

	my $self = shift;
	my ($dndTokenRef,$flag) = @_;
	  
	if( $flag){  # Outline the drag target
		print "entering \n" if($DEBUG);
		my $ButtonFrame = $self->{ButtonFrame};
		
		# compute geometry of where the shadow fram should be
		my $geometry = $ButtonFrame->geometry(); # Geometry of just the button frame
		#print "Geometry $geometry\n";
		my ( $width, $height) = $geometry =~ /(\d+)x(\d+)\+\d+\+\d+/;
		
		# Offset x/y for the x/y of the total widget
		my ( $rootX, $rootY ) = ( $self->x + $ButtonFrame->x, $self->y + $ButtonFrame->y );
		$geometry = $width."x".$height."+".$rootX."+".$rootY;
		#print "New Geometry $geometry\n" if($DEBUG);

		my $dragShadow = $self->{dragShadow};
		$dragShadow->configure(-geometry => $geometry);
		
		# Hide the top-level dragShadow
		$$dndTokenRef->DragShadowToplevelHide();
	}
	else{
		# Get rid of outline
		print "leaving \n" if($DEBUG);
		my $dragShadow = $self->{dragShadow};
		$dragShadow->placeForget();
		# Show the top-level dragShadow
		$$dndTokenRef->DragShadowToplevelShow();
	}
	return 1;
}

##################################################

=head2 drop

Method called when accepting a drop from a drag-drop operation

=cut

sub drop{

	my $self = shift;
	
	my @args = @_;
	my $selection = shift;
	
	my ($sel) = $self->toplevel->SelectionGet('-selection'=>$selection);
	
        print "In IDEtabFrame::Drop...\n" if($DEBUG);
        
	# Get the real object from the dropbox
        my $DropBox = Tk::IDElayout::DropBox->instance();
	my $object = $DropBox->delete($sel);
        
	return 0 unless(defined($object));
	
        # Get all the info about the object dragged
	my ($DragSource, $IDEobject, $Caption, $Contents, $PackInfo) = 
                @$object{qw/DragSource Object Caption Contents PackInfo/};
	
        
	#print "Self Dragging = ".$self->{dragging}."\n";
	
	print "DragSource = $DragSource\n" if($DEBUG);
	
	# Calback to add new tab
	my $addAction =
		sub{
			my $newFrame = $self->add(
				-caption => $Caption,
				-label =>   $Caption,
				);
			my $frameConfig = $self->cget(-defaultFrameConfig);
			$newFrame->configure(@$frameConfig) if (@$frameConfig);	
			
			# If the source is a toolwindow, capture the window (i.e. make it a non-toplevel again)
			if( $DragSource =~ /toolwindow/i ){
                                
                                # Get rid of the dragArea
                                my @packSlaves = $Contents->packSlaves();
                                #print "Packslaves = ".join(", ", @packSlaves)."\n";
                                my ($dragArea) = grep defined($_->{_dragArea_}), @packSlaves; # find the drag area
                                                                                              # based on the tag we put there
                                $dragArea->packForget() if( $dragArea); # forget the drag Area, if we found it.
                                
				$Contents->wmCapture;  # Capture back to a window from a toplevel
 			}
			
                        my %packOptions = (@$PackInfo, -in => $newFrame); # Override the '-in' in the packInfo
			$Contents->pack(%packOptions);
			$Contents->raise();
		};

	# If we are currently dragging, delay adding the tab until after it is complete
	if( $self->{dragging} ){
		push @{ $self->{endDragActions} }, $addAction;
	}
	else{ # Not dragging, execute immediately
		$addAction->();
	}
		
	return 1;
}

###########################################################################################

=head2 toolWindowConfigure

Method to configure a "toolwindow" so that it can be dragged back into a tab window. 
	
Bindings are setup so moving the window just moves a frame.

B<Usage:>

   $self->toolWindowConfigure($toolwindow);


=cut

sub toolWindowConfigure{
    my $self = shift;
    my $top = shift;
    
    # Make Drag Area at the top of the window
    # Get the real contents, unpack, and then pack back to make room for the drag
    #   area at the top of the window.
    my ($realContents) = $top->children();
    #print 'Children = '.join(", ", $contents->children)."\n";
    my $dragArea =  $top->Frame( -height => 5, -cursor => 'fleur')
                        ->pack(-before => $realContents, -side => 'top',  -fill => 'x');
   
    # Add a tag onto dragArea, so we can find it again
    $dragArea->{_dragArea_} = 1;
    
    my $dragAreaBG = $dragArea->cget(-bg);
    $dragArea->bind('<Enter>', sub{
                        $dragArea->configure(-bg => 'lightsteelblue');
                      }
                 );
     $dragArea->bind('<Leave>', sub{
                        $dragArea->configure(-bg => $dragAreaBG);
                      }
                 );
    
    
    my $shadow;
    my ( $posX,    $posY )    = ();
    my ( $offsetX, $offsetY ) = ( 0, 0 );
    
    my $dragToken;
    $dragToken = $dragArea->IDEdragDrop(
          -event  => '<Any-B1-Motion>',  
	  -sitetypes => ['Local'],
          -startcommand => [sub{ 
                my $self   = shift;
 	        my $dndTokenRef = shift;
                my $widget = shift;
                #print "In StartCommand, widget = $widget\n";
                
                my $geom = $widget->toplevel->geometry;
                my ( $rootx, $rooty ) = ( $widget->rootx, $widget->rooty );

                #print "Root x/y = $rootx/$rooty\n";
                #print "Pos X/Y = $posX/$posY\n";
                my ( $width, $height, $x, $y ) =
                  $geom =~
                  /^(\d+)x(\d+)\+(\d+)\+(\d+)/;   # Parse width/height from geom
                #print "x/y = $x/$y\n";

                # Make total height include the title bar
                $height = $height + ( $rooty - $y );
                
                # Figure out the offset between the current mouse position
                #  and the root x/y of the window
                 my $pointerx = $widget->pointerx;
                 my $pointery = $widget->pointery;
                 
                 my $offsetX = $pointerx - $x;
                 my $offsetY = $pointery - $y;
                 
                 

		 $$dndTokenRef->DragShadowToplevelShow();
                 $$dndTokenRef->DragShadowToplevelConfig($width, $height,-$offsetX,-$offsetY);
                 $self->{dragging} = 1;

                 # Set the drag image, so we don't get that lame default "Frame" image
                 my $dragImage = $self->dragImage;
                 $$dndTokenRef->configure( -image => $dragImage);
                 
                return 0;
                
          }, $self, \$dragToken, $top],
	  -handlers => [[sub{ 
				my $contents = $top; 
				my $Caption  = $top->MainWindow::title();
				print "In Handler, Caption = '$Caption'\n" if($DEBUG);
				
				# We signal the Tk::IDEtabFrame method that we will be dropping from a toolwindow
	  			my $data = { DragSource => 'ToolWindow', "Object" => $self, "Caption" => $Caption,
                                             "Contents" =>  $contents,
                                             "PackInfo" => $contents->{_PackInfo}, # Pack options attached when toolwindow created
                                };

				# Put data in dropbox, key'ed by ref address
                                my $DropBox = Tk::IDElayout::DropBox->instance();
				$DropBox->set("$data", $data);
				# Create array ref of endDragActions, if not defined already
				$self->{endDragActions} = [] unless( defined($self->{endDragActions}));
				$self->{dropped} = 1; # Flag to indicate that the drag has dropped
								
	  			return "$data";
	  		    }
	  		],
	  		],
			-endcommand => [$self, 'endDragTW', \$dragToken, $top],
		);
    
    
    
}

##################################################

=head2 endDragTW

Method called when a Tool-Window drag operation ends. 
	
If not dropping back into a tab-frame, moves the toolwindow to the dragged
position.

=cut

sub endDragTW {

	my $self = shift;    # IDE tabframe object
	my $dndTokenRef = shift;
	my $widget  = shift; # toolwindow widget
	
        # Get the geom of the toplevel
        my $shadow = $$dndTokenRef->dragShadowToplevel();
	my $newgeom = $shadow->geometry();
	print "In End Command\n" if($DEBUG);

	# Get the new root positio of the window and set posX/Y, so we don't
	#   get a false window move indication
	my ( $newX, $newY ) = $newgeom =~ /(\d+)\+(\d+)$/;
	if ( defined($newX) && defined($newY) && !$self->{dropped} )
	{    # only set new geom if we haven't dropped
		$widget->MainWindow::geometry("+$newX+$newY");
	}

	$$dndTokenRef->DragShadowToplevelHide(); # Hide the dragshadow Toplevel

        # Execute any endDragActions
	 if( defined($self->{endDragActions}) ){
		 my $actions = $self->{endDragActions};
		 
		 # Go thru each action
		 while( @$actions){
			 my $action = shift @$actions;
			 $action->(); # execute action
		 }
	 }

	$self->{dragging} = 0;
	$self->{dropped}  = 0;

}

##################################################

=head2 TabRemove

Overridden TabRemove method.
        
This calls the parent I<TabRemove> and the calls the I<lastTabDeleteCallback> if all the tabs have been deleted

=cut

sub TabRemove {
	my ($self, @args) = @_;
        $self->SUPER::TabRemove(@args);
        
      # Check for no more tabs
        my $clientHash = $self->{ClientHash};
        if( scalar(keys %$clientHash) == 0){
                my $lastTabDeleteCallback = $self->cget('-lastTabDeleteCallback');
                if(defined($lastTabDeleteCallback) && ( ref($lastTabDeleteCallback) =~ /callback/i )){
                        $lastTabDeleteCallback->Call();
                }
        }
        
}
###################################################################################
=head2 tabclose

Overridden tabclose method.
        
If the tabclose option is 1, this installs a callback to our TabRemove, rather than the default I<Tk::DynaTabFrame::TabRemove>. 

Because L<Tk::DynaTabFrame> calls its I<TabRemove> directly (Using \&TabRemove), rather than by a method call, this tabclose method is
needed to call our overriden I<TabRemove> method.
        
The default code ref installed here is called when the close button pressed on the tab.
It explicitly destroys the widget contained in the tab. This is needed because the widgets in IDElayout
are created as childs of the main widget, and not childs of the IDEtabframe widget.
This is done so the widgets can be dragged around in the GUI.

Since the widgets are created as childs of the main window, and not the IDEtabframe tabs,
just deleting the tab won't delete the widget. So we delete it manually here.

=cut

sub tabclose {
	my ($this, $close) = @_;

	return $this->SUPER::tabclose() unless defined($close);

        if (ref($close) ne 'CODE' && $close == 1){ # Default close button desired
                
                # This code ref called when the close button pressed on the tab
                #   It destroys the widget contents. This is needed because the widgets in IDElayout
                #   are created as childs of the main widget, and not childs of the IDEtabframe widget.
                #   This is done so the widgets can be dragged around in the GUI.
                #   Since the widgets are created as childs of the main window, and not the IDEtabframe tabs,
                #    just deleting the tab won't delete the widget. So we delete it manually here.
                my $subRef = sub{
                        my $self = shift;
                        my $tabName = shift;

                        # Make lookup of client names to client frames
                        my $clientHash = $self->{ClientHash};
                        my $clientList = $self->{ClientList};
                        my @clientFrames =  map $clientList->[$clientHash->{$_}][0], keys %$clientHash;
                        
                        my %clientFrames;
                        @clientFrames{ keys %$clientHash} = @clientFrames;
                        
                        my $clientFrame = $clientFrames{$tabName};
                        #print "clientFrame = $clientFrame\n";
                        
                        # get the frame contents, explicitly destroy it
                        my ($pageContents) = $clientFrame->packSlaves();
                        $pageContents->destroy();
                        
                        #print "Page contents = $pageContents\n";
                        
                        $self->TabRemove($tabName)
                }; # Sub ref to call our TabRemove
                return $this->SUPER::tabclose($subRef);
        }
        
        # Special code ref supplied, just pass this to the parent method
        return $this->SUPER::tabclose($close);
}
        
1;
