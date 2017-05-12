
=head1 NAME 

Tk::IDElayout - Tk Widget for Layout of Frames Similar to an IDE.

=head1 SYNOPSIS

B<Simple Example>: (See t/simpleIDElayout2.t in the source distrubution for complete example)

        #### This example creates two IDEtabFrames for managing with IDElayout #####
        my $TOP = MainWindow->new;
        
        ###  Create layout structures ###
        ###    This structure has the PaneWindow (P1) at the top level, 
        ###      and the two IDEtabFrames next lower level.
        ###     Graphically, this looks like this:
        ###     +------+     +------+
        ###     |  P1  | ==> | Tab1 |
        ###     +------+     +------+
        ###       H
        ###       H
        ###       v
        ###     +------+
        ###     | Tab2 |
        ###     +------+
        my @nodes = (
          {  name => 'P1', 
           dir  => 'V',
           childOrder => ['Tab1', 'Tab2'],
           type => 'panedWindow',
          },  
           {  name => "Tab1", type => 'widget'
           },
           {  name => "Tab2", type => 'widget'
           }
        );
        my @edges = (
           [ 'P1', 'Tab1'],
           [ 'P1', 'Tab2'],
           );
        
        
        #################### Create Widgets ##################################
        # We will use the same default IDEtabFrame config that the IDElayout widget uses
        my $IDEtabFrameConfig = Tk::IDElayout->defaultIDEtabFrameConfig();
        
        ###  TabFrame 1 ###
        my $dtf = $TOP->IDEtabFrame( @$IDEtabFrameConfig);      
        $dtf->configure(-height => 400);
        
        
        ###  TabFrame 2 ###     
        my $dtf2 = $TOP->IDEtabFrame( @$IDEtabFrameConfig);
         
        ######### Populate widgets hash with the two TabFrames created ######
        my %widgets = ( 'Tab1' => $dtf,
                        'Tab2' => $dtf2,
                        );
        
        
        # Create simple menubar
        my $MenuBar = $TOP->Frame(-class => 'Menubar'); # We don't pack this, it will be packed by IDElayout
       
        
        # Create simple statusLine
        my $statusText = "This is statusLine Text";
        my $statusLine = $TOP->Label(-textvariable => \$statusText, -anchor => 'w');
        
        
        # Structure Created, now buld the Tk::IDElayout
        
        my $layout = $TOP->IDElayout(
                -widgets => \%widgets,
                -frameStructure => { nodes => \@nodes,  edges => \@edges},
                -menu    => $MenuBar,
                -statusLine => $statusLine,
                );
        
        
        $layout->pack(-side => 'top', -fill => 'both', -expand => 'yes');


=head1 DESCRIPTION

This is a widget for managing the layout of Tk frames (and other widgets) like an IDE (Integrated Development Environment)
like I<Ecliplse> or I<Microsoft Visual Studio>.

B<Features:>

See I<Screenshots.pdf> in the source distribution for some screenshots demonstrating some of these features.

=over 1

=item *

Layout and management of subwidgets/frames similar to an IDE.
	
=item *

Resizable panes. Separate frames/widgets in the top-level window can be resized by dragging
the separator border between the frames.
	
=item *

Support for Tabbed-Frames (using of subclass of L<Tk::DynaTabFrame>, where each tab can be dragged/dropped;
to another tabframe in the IDE, or to a new separate window, or to "edge" ares in the mainwindow to create new tabframes.

=back	

=head1 OPTIONS


=over 1

=item frameStructure

Hash ref representing the structure and layout of the frames managed by this widget. See L<FrameStructure Description>
below for details on this structure.
	
This option, or I<frameGraph> below is required to be supplied to the widget when it is created.

=item frameGraph

L<Graph> object representing the frame structure, built from the above frameStructure. 
This is used internally by the object for manipulation of the frame structures. Normally this is built
from the I<frameStructure> data above, but can be directly supplied by setting this option.

This option, or I<frameStructure> above is required to be supplied to the widget when it is created.

=item widgets

Hashref (key-ed by name) of subwidgets managed by this widget.

=item menu

Required menu widget that will displayed at the top of the top-level window.
	
=item toolbar

Optional L<Tk::ToolBar> widget to display below the I<menu> above.
	
=item statusLine

Optional status-line frame to display at the bottom of the top-level window. A status-line is typically used
to display short top-level status items to the user.

=item IDEtabFrameConfig

Optional array ref of L<Tk::IDEtabFrame> options to be used when creating new L<Tk::IDEtabFrame> widgets.

New L<Tk::IDEtabFrame> Widgets are created when something is dragged/dropped to an 
interior/exterior edge of the L<Tk::IDElayout> Widget. This array ref will be used to create the 
new L<Tk::IDEtabFrame> widgets. 

If not supplied, this defaults to:

 [
        -tabclose => 1,
        -tabcolor => 'white',
        -raisecolor => 'grey90',
        -tabpady => 1,
        -tabpadx => 1,
        -padx => 0,
        -pady => 0,
        -bg => 'white',
        -raisedfg => 'black',                        
        -raisedCloseButtonfg => 'black',
        -raisedCloseButtonbg => 'lightgrey',
        -raisedCloseButtonActivefg => 'red',
        -noraisedfg => 'grey60',
        -noraisedActivefg => 'black',
        -noraisedCloseButtonfg => 'lightgrey',
        -noraisedCloseButtonbg => 'white',
        -noraisedCloseButtonActivefg => 'red',
 ]
 
=item IDEpanedwindowConfig

Optional array ref of L<Tk::IDEpanedwindow> options to be used when creating new L<Tk::IDEpanedwindow> widgets.

New L<Tk::IDEpanedwindow> Widgets are created when something is dragged/dropped to an 
interior/exterior edge of the L<Tk::IDElayout> Widget that is not compatible with the existing panedwidnow direction
 (For example when a widget is dragged/dropped to the top or bottom of a horizontal panewindow). This array ref will be used to create the 
new L<Tk::IDEpanedwindow> widgets. 

If not supplied, this defaults to:

 [      -sashpad   => 1,
        -sashwidth => 6,
        -sashrelief=> 'ridge'
 ]

=item ResizeOnReconfig

Flag = 1 if the mainwindow should be resized when the IDElayout structure is reconfigured (i.e. widget
added or deleted to the structure, triggerd be a call to the I<addWidgetAtSide> or I<deleteWidget>
method. )

If the flag is 1, the top level window will be resized to the requested width/height (obtained
thru the I<reqwidth> and I<reqheight> methods) of the window. This can be useful in some situations
where the user has resized a window to be large, and then deletes some widgets, resulting in a big window
with not much in it. Setting this flag to 1 in this situation will cause the window to shrink to accomodate
the requested size of the widgets that are left in the window.

Defaults to 0.

=back

=head1 FrameStructure Description

The structure of the frames managed by this widget is defined by the I<frameStructure> option. This is a hash ref
with two entries, I<nodes> and I<edges>, which together describe a L<Graph::Directed> structure.
	
=head2 Node Entry

The node entry is an array ref containing descriptions for each node/frame managed by the widget. Each node entry is a 
hash ref with the following entries:

=over 1

=item type

Node Type. Valid entries are I<panedWindow> or I<widget>. 
	
I<panedWindow> nodes represent L<Tk::IDEpanedWindow> widgets that manage one or more subwidgets.

I<widget> nodes represent normal Tk widgets that are managed by a L<Tk::IDEpanedWindow> widget.

=item name

Name of the node. If I<type> above is 'widget', this should correspond to a entry in the I<widgets> option.
	
=item dir

Direction (H/V for Horizontal/Vertical) of the L<Tk::IDEpanedWindow> panes. Only applies for the I<panedWindow> type.

Horizontal/Verical (H/C) indicates the direction the frames of the L<Tk::IDEpanedwindow> widget are oriented.

=item childOrder

Order of the frames managed by the L<Tk::IDEpanedWindow> widget. Only applies for the I<panedWindow> type.

This is a list of widget names managed by the L<Tk::IDEpanedwindow> widget.

=item expandfactors

List of I<expandFactors> for the frames managed by the L<Tk::IDEpanedwindow> widget. Only applies for the I<panedWindow> type.

I<Expandfactors> determine how the individual widget frames expand or shrink when the entire window is resized. 
See the L<Tk::IDEpanedwindow> docs for details.

=back


=head2 Edges Entry

The edges entry represents the edges (or connections) between the nodes described by the I<nodes> entry. It is
a list of 2-element arrays. Each 2-element array represents a connection between nodes.
	
=head2 Example Structure

The following is an example of a simple I<frameStructure>.
	
  my $frameStructure  = {
      nodes = [
	  {  name => 'P1', 
	     dir  => 'H',
	     childOrder => ['Frame 1', 'P2']
	  },  
	  {  name => "Frame 1",
	  },
	  {  name => 'P2',
	     dir  => 'V',
	     childOrder => ['Frame 2', 'Frame 3']
	  },
	  {  name => 'Frame 2' },
	  {  name => 'Frame 3' },
	 ],
      edges = [
	   [ 'P1', 'Frame 1'],
	   [ 'P1', 'P2'],
	   [ 'P2', 'Frame 2'],
	   [ 'P2', 'Frame 3'],
        ]
   };
   
The above will result in the following frame structure (as a L<Graph::Directed> object in the I<frameGraph> option).
	
	+--------+     +--------+     +--------+
	|   P1   | --> |   P2   | --> | Frame2 |
	+--------+     +--------+     +--------+
	  |              |
	  |              |
	  v              v
	+--------+     +--------+
	| Frame1 |     | Frame3 |
	+--------+     +--------+
	

The top-level PanedWindow, P1, manages Frame1 and another PanedWindow, P2, in the horizontal direction

The PanedWindow P2 manages Frame2 and Frame3 in the vertical direction.
	
The actual layout on the screen will look something like this.
        
       +---------------+----------------+
       |               |     Frame2     |
       |    Frame1     +----------------|
       |               |     Frame3     |
       |---------------+----------------+

=head1 Advertised Sub-widgets

=over 1

=item menuFrame

L<Tk::Frame> object that holds the menu bar at the top of the main window.

=item mainPW

L<Tk::IDEanedWindow> object used for main display of widgets.
	
=item toolbarFrame

L<Tk::Frame> object that holds the toolbar (if used).

=item statusLineFrame

L<Tk::Frame> object that holds the status-line widget.
	
=back

=head1 ATTRIBUTES

=over 1

=item   indicator

L<Tk::Frame> object used to indicate drop target areas. This will appear as a horizontal or vertical Bar on the
sides or top/bottom of a frame to indicate where a drag/drop operation can be dropped.

        
=item currentFrame

Current frame that the mouse pointer is over during a drag/drop operation.
        
=item currentSide

Current side of the frame (e.g. left, right, top, bot) that the mouse pointer is over during a drag/drop operation.
        
=item lastSide

The last side of the frame (e.g. left, right, top, bot) that the mouse pointer was over during a drag/drop operation.

=back

=head1 Methods

=cut

package Tk::IDElayout;

our ($VERSION) = ('0.33');

use strict;

use Carp;

use Tk;
use Tk::Font;

use Tk::IDEpanedwindow;
use Graph::Directed;  # Used for representation and manipulation of the frame layout structure
use Tk::IDElayoutDropSite;

use base qw/ Tk::Derived Tk::Frame/;

Tk::Widget->Construct("IDElayout");

sub Populate {
	my ( $cw, $args ) = @_;

	my $frameStructure;
	if ( defined( $args->{-frameStructure} ) ) {
		$frameStructure = $args->{-frameStructure};
	}
	my $frameGraph;
	if ( defined( $args->{-frameGraph} ) ) {
		$frameGraph = $args->{-frameGraph};
	}

	
	if( !defined($frameGraph) && !defined($frameStructure) ){
		croak("Error: -frameGraph or -frameStructure option not supplied when creating IDElayout widget\n");
	}
	
	my $widgets;
	if ( defined( $args->{-widgets} ) ) {
		$widgets = $args->{-widgets};
                $cw->{Configure}{-widgets} = $widgets; # Make sure $widgets is populated before other options

	}
	else {
		croak("Error: -widgets not supplied when creating IDElayout widget\n");
	}

        # Get the default tabFrame config, for setting if IDEtabFrameConfig not supplied
        my $defaultIDEtabFrameConfig = $cw->defaultIDEtabFrameConfig();

        # Set the default IDEpanedwindow config. This is not broken out as a separate method,
        #    because it is not used outside of this routine.
        my $defaultIDEpanedwindowConfig = 
            [   -sashpad   => 1,
                -sashwidth => 6,
                -sashrelief=> 'ridge'
            ];
        
	# Create Placeholder frames
        # We use the grid geometry manager here for better control
        #    Using the pack geom manager, the status line along the bottom would disappear when
        #    the frame was shrunk vertically.
	my $menuFrame       = $cw->Frame()->grid( -column => 0, -row => 0, -sticky => 'ew');
	my $toolbarFrame    = $cw->Frame()->grid( -column => 0, -row => 1, -sticky => 'ew');
	my $mainPW          = $cw->Frame()->grid( -column => 0, -row => 2, -sticky => 'nsew');
	my $statusLineFrame = $cw->Frame()->grid( -column => 0, -row => 3, -sticky => 'ew');

        # 
        $cw->gridColumnconfigure(0, -weight => 1); # Allow the whole column to expand
        $cw->gridRowconfigure(2, -weight => 1); # The mainPW window can expand, anything else doesn't
	
	$cw->SUPER::Populate($args);
	$cw->ConfigSpecs(	
		-frameStructure =>
		               [ qw/ METHOD frameStructure frameStructure /, $frameStructure ],
		-frameGraph => [ qw/ METHOD frameGraph frameGraph /, $frameGraph ],
		-widgets    => [ qw/ PASSIVE widgets widgets /,      $widgets ],
		-menu       => [ qw/ METHOD menu menu /,             undef ],
		-toolbar    => [ qw/ METHOD toolbar toolbar /,       undef ],
		-statusLine => [ qw/ METHOD statusLine statusLine /, undef ],
		-toolbar    => [$frameStructure],
		-IDEtabFrameConfig    => [ qw/ PASSIVE IDEtabFrameConfig IDEtabFrameConfig /,      $defaultIDEtabFrameConfig ],
		-IDEpanedwindowConfig => [ qw/ PASSIVE IDEpanedwindowConfig IDEpanedwindowConfig /,      $defaultIDEpanedwindowConfig ],
		-ResizeOnReconfig    => [ qw/ PASSIVE ResizeOnReconfig ResizeOnReconfig /, undef ],
        );

	# Advertise subwidgets
	$cw->Advertise( 'menuFrame'  => $menuFrame );
	$cw->Advertise( 'mainPW' => $mainPW );
	$cw->Advertise( 'toolbarFrame' => $toolbarFrame );
	$cw->Advertise( 'statusLineFrame' => $statusLineFrame );

	# Drop Indicator:
	$cw->{indicator} = $cw->toplevel->Frame(-bg     => 'blue', -relief => 'flat');

        #### Create Dropsite for entire widget ############
        ####   This is used for moving widgets around in the enviroment by drag/dropping ###
        my $site;
        $site = $cw->IDElayoutDropSite
           (-droptypes     => ['Local'],
                   -entercommand => sub{
                        my $flag = shift;
                        #print "############ In Enter Command $flag\n";
                        if( $flag == 1){
                                # Save the current side/frame for use later
                                $cw->{currentSide}  = $site->{currentSide};
                                $cw->{currentFrame} = $site->{currentFrame};
                        }
                   }, 
                   -dropcommand => [$cw, 'Drop'],
                        
        
           );
	

        ######## These bindings make all windows (including toolwindow) close/open when the main IDE 
        ########   window is closed/opened.
        
        $cw->toplevel->bind('<Unmap>', sub{ 
        
                my $widget = shift;
                return unless($widget->isa("Tk::MainWindow")); # Only response to mainwindow unmaps
                my @childs = $widget->children();
                #print "Childs = ".join(", ", @childs)."\n";
                # Minimize all of our toplevels
                foreach my $child(@childs){
                        eval{ $child->MainWindow::attributes() }; # This will only work for toplevels
                        unless( $@ ){
                                #print "Child can attrib\n";
                                $child->MainWindow::withdraw;
                        }
                }
        });
        
        $cw->toplevel->bind('<Map>', sub{ 
                # restore all of our toplevels
                my $widget = shift;
                return unless($widget->isa("Tk::MainWindow")); # Only response to mainwindow unmaps
        
                my @childs = $widget->children();
                foreach my $child(@childs){
                        eval{ $child->MainWindow::attributes() }; # This will only work for toplevels
                        unless( $@ ){
                                $child->MainWindow::deiconify;
                        }
                }});
           
}


#----------------------------------------------
# Sub called when -frameStructure option changed
#
sub frameStructure{
	my ($cw, $frameStructure) = @_;


	if(! defined($frameStructure)){ # Handle case where $widget->cget(-frameStructure) is called
		
		return $cw->{Configure}{-frameStructure};
		
	}
	
	unless( ref($frameStructure) eq 'HASH' && defined( $frameStructure->{nodes})){
		croak("Error: -frameStructure option supplied doesn't have a 'nodes' key\n");
	}
	
	my $nodes = $frameStructure->{nodes};

	unless( ref($frameStructure) eq 'HASH' && defined( $frameStructure->{edges})){
		croak("Error: -frameStructure option supplied doesn't have a 'edges' key\n");
	}

	my $edges = $frameStructure->{edges};
	
	my $widgets = $cw->cget(-widgets); # get the list of all widgets
	unless( ref($widgets) eq 'HASH' && scalar(keys %$widgets) > 0){
		croak("Error: -widgets option is empty. Populate it with some widgets before\nsetting the -frameStructure option\n");
	}
	
	# Create the directed graph structure used to store the layout
        my @createArgs = ();
        @createArgs = ( compat02 => 1 ) if( defined($Graph::VERSION) and $Graph::VERSION > .3);
	my $frameGraph = Graph::Directed->new(@createArgs);

 	# Build Graph Struct
	foreach my $node (@$nodes) {  # Build Nodes
		$frameGraph->add_vertex( $node->{name} );

		# Set any attributes
		my $attr = {};
		foreach my $attrName ( sort keys %$node ) {
			next if ( $attrName eq 'name' );    # skip name, we are already using that for the vertex name
			$attr->{$attrName} = $node->{$attrName};
		}
		$frameGraph->set_attribute( 'attr', $node->{name}, $attr );
	}
	foreach my $edge (@$edges) {  # Build Edges
		$frameGraph->add_edge(@$edge);
	}
	
	# Set the frameGraph option from the Graph::Directed object we just built
	$cw->configure(-frameGraph => $frameGraph);
}

#----------------------------------------------
# Sub called when -frameGraph option changed
#
sub frameGraph{
	my ($cw, $frameGraph) = @_;


	if(! defined($frameGraph)){ # Handle case where $widget->cget(-frameGraph) is called
		
		return $cw->{Configure}{-frameGraph};
		
	}
	
	unless( ref($frameGraph) && $frameGraph->isa('Graph::Directed')){
		croak("Error: -frameGraph option supplied isn't a Graph::Directed object\n");
	}
	
	
	my $widgets = $cw->cget(-widgets); # get the list of all widgets
	unless( ref($widgets) eq 'HASH' && scalar(keys %$widgets) > 0){
		croak("Error: -widgets option is empty. Populate it with some widgets before\nsetting the -frameStructure option\n");
	}
	
	# Get the toplevel frame
	my $mainPW = $cw->Subwidget('mainPW');
	
	# Get the name of the toplevel node
	my ($topPaneWindowName) = $frameGraph->predecessorless_vertices();
	
	# Populate the structure, using the supplied frameGraph
	$cw->populateWindow($mainPW, $cw, $frameGraph, $topPaneWindowName, $widgets);

	
}

############## 
##  Recursive sub to build/populate a PanedWindow layout
##  Based on a structure and already built widgets
sub populateWindow{
	my $cw     = shift;
	my $window = shift;
	my $top    = shift;  # Top level widget
	my $frameStruct = shift;
	my $name = shift;  # node we are populating
	my $widgets = shift;
	
	# Create Paned Window
	my $attr = $frameStruct->get_attribute('attr', $name); # Get the attribute hash
	my $dir =  ($attr->{dir} =~ /v/i) ? 'vertical' : 'horiz';
	
	my @kids = $frameStruct->successors($name);  # get the childs
	my $childOrder = $attr->{childOrder}; # Get the order of the childs
		
        my $expandfactors = $attr->{expandfactors} || [map 0, @$childOrder]; # Resize behavoir of the childs, defaults to all zeros
        

        my $IDEpanedwindowConfig = $cw->cget(-IDEpanedwindowConfig);
        my $pw = $top->IDEpanedwindow( -orient => $dir, @$IDEpanedwindowConfig);
	$pw->pack(-in => $window, qw/-side top -expand yes -fill both /);
	
	$widgets->{$name} = $pw; # save name
	
	# Pack or create Each Child
	my @widgetsToAdd;
        my $childIndex = 0;
	foreach my $childName(@$childOrder){	
		my $childAttr = $frameStruct->get_attribute('attr', $childName);
		if( defined( $childAttr->{childOrder})){ # Another paned window, recurse
			my $childPW = $cw->populateWindow($pw, $top, $frameStruct, $childName, $widgets);
			push @widgetsToAdd, $childPW;
		}
		else{ # not a child, just pack the widget
			my $widget = $widgets->{$childName};
			push @widgetsToAdd, $widget;
                        
                        # Add callback to any Tk::IDEtabFrame widgets to handle when all tabs in the widget
                        #   are closed
                        if( $widget->isa("Tk::IDEtabFrame")){
                                $widget->configure( 
                                        -lastTabDeleteCallback => 
                                                [ $cw, 'deleteWidget', $childName]
                                );
                        }
			
			# Specific Tk::Widget package called out here, because Tk::DynaTabFrame overrides the raise
			#   method to something different than what Tk::Widget::raise does.
			$widget->Tk::Widget::raise; # Needed for widgets to show up that were created before the panedwindow
		}
                # Add expandFactors option, if they exist
                if( defined (my $expandfactor = $expandfactors->[$childIndex])){
                        push @widgetsToAdd, -expandfactor => $expandfactor;
                }
                $childIndex++;
	}
	$pw->add(@widgetsToAdd);
	
	return $pw;
}
	
#----------------------------------------------
# Sub called when -menu option changed
#
sub menu{
	my ($cw, $menu) = @_;


	if(! defined($menu)){ # Handle case where $widget->cget(-frameStructure) is called
		
		return $cw->{Configure}{-menu};
		
	}


	my $menuFrame = $cw->Subwidget('menuFrame');

	$menu->pack(-in => $menuFrame, -side => 'top', -fill => 'x', -expand => 0);	
	$menu->raise(); # Raise needed, because menuFrame might have been created after menu, and it would obsure the menu
	
}

#----------------------------------------------
# Sub called when -statusLine option changed
#
sub statusLine{
	my ($cw, $statusLine) = @_;


	if(! defined($statusLine)){ # Handle case where $widget->cget(-statusLine) is called
		
		return $cw->{Configure}{-statusLine};
		
	}


	my $statusLineFrame = $cw->Subwidget('statusLineFrame');

	$statusLine->pack(-in => $statusLineFrame, -side => 'bottom', -expand => 'no', -fill => 'x', -anchor => 'sw');
	$statusLine->raise(); # Raise needed, because statusLineFrame might have been created after statusLine, and it would obsure the menu
	
}

#----------------------------------------------
# Sub called when -toolbar option changed
#
sub toolbar{
	my ($cw, $toolbar) = @_;


	if(! defined($toolbar)){ # Handle case where $widget->cget(-toolbar) is called
		
		return $cw->{Configure}{-toolbar};
		
	}


	my $toolbarFrame = $cw->Subwidget('toolbarFrame');

	$toolbar->pack(-in => $toolbarFrame, -side => 'top', -fill => 'x', -expand => 0);	
	$toolbar->raise(); # Raise needed, because Frame might have been created after widget, and it would obsure the widget
	
	
}

############################################################

=head2 findFrame

Given the current x/y position, return
the frame (if any) (and the bounding box coord) that the x/y position is within

B<Usage:>

   my ($frameName, $x1,$y1, $x2,$y2) = $self->findFrame($x,$y);
   
   returns an empty list if x/y position is not within any frame


=cut

sub findFrame{
	my $self      = shift;
	my @pxy       = (shift, shift);
	my $frameList = $self->cget(-widgets);
	
	my $frame; # Current frame we are looking at
	my $geometry; # text geometry of the frame
	my ( $width, $height); # Current frame width / height
	my ( $rootX, $rootY);  # root x/y coords of the current frame
	my ( $x, $y, $x2, $y2); # Bounding box for the frame
	#print "Framelist names = ".join(", ", keys %$frameList)."\n";
	my %frameMatches; # hash of matches for frames we are in (i.e. we could be in multiple frames at once)
	foreach my $frameName ( sort keys %$frameList ) {
		$frame    = $frameList->{$frameName};
		$geometry = $frame->geometry;
		( $width, $height) = $geometry =~ /(\d+)x(\d+)\+\d+\+\d+/;
		( $rootX, $rootY ) = ( $frame->rootx, $frame->rooty );

		#print "$frameName rootX/Y = $rootX/$rootY\n";
		# convert Upper left corner to absolute coords
		$x = $rootX;
		$y = $rootY;

		#print "frame $frameName = $geometry\n";
		#print "frame $frameName x/y/w/h = $x $y $width $height\n";
		( $x2, $y2 ) = ( ( $x + $width ), ( $y + $height ) );

		# Check to see if we are within this frame
		if (     $pxy[0] >= $x
		      && $pxy[0] <= $x2
		      && $pxy[1] >= $y
		      && $pxy[1] <= $y2 ) {
			#print "pointer is within $frameName\n";
			$frameMatches{$frameName} = [$x,$y, $x2, $y2];

		}
	}

	if( %frameMatches){
		#print "We are in frames ".join(", ", sort keys %frameMatches)."\n";
		
		# If multiple matches/frames, give priority to sink vertexes. These
		#   will frames that are inside of other frames. We are inside of the inner
		#    frames first. (e.g. A Text widget could be inside of a PanedWindow widget.
		#  We would count ourselves as being inside of the text widget first.)
		my @frameMatches = sort keys %frameMatches;
		my ($frameMatch) = @frameMatches; # default if no sink vertexes is the first one.
		my $frameGraph = $self->cget('-frameGraph');
		foreach my $frame(sort keys %frameMatches){
			if( $frameGraph->is_sink_vertex($frame)){
				$frameMatch = $frame;
				last;
			}
		}
		my $matchInfo = $frameMatches{$frameMatch};
                #print "FindFrame Returning $frameMatch, ".join(", ",@$matchInfo)."\n";
		return ($frameMatch, @$matchInfo);
	}
	
	return ();

}


#######################################################################

=head2 findSide

Method to find the side of a frame we are "close" to. Used for dragging, where the edges of
the IDElayout frames are drop targets.

B<Usage:>

   my $side = $self->findSide($pointerx,$pointery, $frameName,
                  $x1, y1, $x2, $y2);


     where: $pointerx   x coord of the current pointer
            $pointery   y coord of the current pointer
	    $frameName  Name of frame
	    $x1/y1/x2/y2 Frame Coords
	    
    Returns $side (top/bot/left/right) if we
    are close to a side.

=cut

sub findSide{

	my $self= shift;
	my @pxy = (shift,shift);
	
	my ( $frameName, $x1, $y1, $x2, $y2 ) = @_;
	
	my $frameList = $self->cget(-widgets);
	
	#print "In $frameName \n";
	
	my $side;  # side we are flashing, if any

	# coords for top/bot left right sides
	my @topCoord   = ( $x2, $y1, $x1, $y1 );
	my @botCoord   = ( $x1, $y2, $x2, $y2 );
	my @leftCoord  = ( $x1, $y1, $x1, $y2 );
	my @rightCoord = ( $x2, $y2, $x2, $y1 );

	my %coords = (               top   => \@topCoord,
		       bot   => \@botCoord,
		       left  => \@leftCoord,
		       right => \@rightCoord
	);

	# Find min distance and the side
	my ( $minDist, $dist, $minSide );
	foreach my $side ( keys %coords ) {
		$dist = $self->distanceToPoint( @pxy, @{ $coords{$side} } );
		#print "$side Dist $dist\n";
		if ( !defined $minDist || $dist < $minDist ) {
			$minDist = $dist;
			$minSide = $side;
		}
	}

        if( $minDist < 20){ # If we are close to a side, return it, else return undef
                return $minSide;
        }
        else{
                return undef;
        }

}			

########################################################################################

=head2 flashSide

Flash the drop indicator at a side of a frame.

B<Usage:>

  $self->flashSide($side, $frame);

   where: 
     $side: Name of side (e.g. top/bot/left/right)
     $frame: Name of frame (as it appears in the frameList


=cut

sub flashSide{
        my $self   = shift;
	my $side   = shift;
        my $frameName = shift;
       
	my $indicator = $self->{indicator};
        
	my $frameList = $self->cget(-widgets);

        my $lastSide = $self->{lastSide};
        
        #print "##### Flashing side $side, Frame $frameName\n";
	# Flash a heavy line on this side, if close to it
	if ( defined($side) && defined($frameName) ) {

                $indicator->placeForget if( !defined($lastSide) || $lastSide ne $side);

		# figure out where to place indicator
		my ( $op, $pp );
		if ( $side =~ /top/ ) {
			$op = [qw/-height 5/];
			$pp = [qw/-relx 0 -relwidth 1 -y 0 -x 0 -rely 0/];
		}
		elsif ( $side =~ /bot/ ) {
			$op = [qw/-height 5/];
			$pp = [qw/-relx 0 -relwidth 1 -y -5 -x 0 -rely 1/];
		}
		elsif ( $side =~ /left/ ) {
			$op = [qw/-width 5/];
			$pp = [qw/-x 0 -relheight 1 -y 0 -relx 0/];
		}
		elsif ( $side =~ /right/ ) {
			$op = [qw/-width 5/];
			$pp = [qw/-x -5 -relx 1 -relheight 1 -y 0/];
		}

		#print "Indicator configuring " . join( ", ", @$pp ) . "\n";
		#print "Indicator is a $indicator\n";
		#print "Indicator exists\n" if $indicator->Exists();
		#print "Framename = $frameName " . ( $frameList->{$frameName} ) . "\n";

		$indicator->configure(@$op);
		$indicator->place( -in => $frameList->{$frameName}, @$pp );
		$indicator->raise;
		$self->{lastSide} = $side;

	}
	else {
		$indicator->placeForget if( defined($lastSide) ); # Only placeforget after we have been placed
	}

}




#############################
#  Sub to find the shortest from a point (x0,y0) to a line (defined by x1,y1  x2,y2).
#    See reference http://mathworld.wolfram.com/Point-LineDistance2-Dimensional.html

sub distanceToPoint{
	
	my $self = shift;
	
	my ($x0,$y0, $x1,$y1, $x2, $y2) = @_;
	
	my $denom = sqrt( ($x2-$x1)**2 + ($y2-$y1)**2);
	
	my $distance =  (($x2-$x1)*($y1-$y0) - ($x1-$x0)*($y2-$y1)) / $denom;
	
	return $distance;
}

###############################################################################

=head2 addWidgetAtSide

Method to add a widget to the Panedwindow arrangement at the frame side.

B<Usage:>

   $self->addWidgetAtSide($widget, $widgetName, $currentFrame, $currentSide, $attr);

	where: 
	  $widget:       Widget to add.
          $widgetName:   Name of the widget to add
	  $currentFrame: Name of the current frame we are adding to
	  $currentSide:  Name of the side of the frame we are adding to (e.g. top/bot/left/right)
          $attr:         Optional hash ref of options for the widget to add
                          (Only -expandfactor supported at this time)

=cut

sub addWidgetAtSide{
        my $self         = shift;
        my $widget       = shift;
        my $widgetName   = shift;
	my $currentFrame = shift;
	my $currentSide  = shift;
        my $attr         = shift || {};
        
	my $widgets      = $self->cget('-widgets');

	my $frameStruct  = $self->cget('-frameGraph');

        # Add callback to any Tk::IDEtabFrame widgets to handle when all tabs in the widget
        #   are closed
        if( $widget->isa("Tk::IDEtabFrame")){
                $widget->configure( 
                        -lastTabDeleteCallback => 
                                [ $self, 'deleteWidget', $widgetName]
                );
        }

        # Attributes that apply to the panewindow->add method
        my %addAttr;
        my $expandfactor = 0; # default expandFactor is 0
        foreach ( '-expandfactor' ){ # Only expand factor recognized now
                $addAttr{$_} = $attr->{$_};
        }
        $expandfactor = defined( $addAttr{-expandfactor} ) ?   $addAttr{-expandfactor} : 0;
        
	# Determine case (Compatible Direction or Incompatible direction add)
	my ($parent) = $frameStruct->predecessors($currentFrame);

	my $topLevelAdd = 0;    # Flag = 1 if adding to the top level PW

	if ( !defined($parent) ) {    # parent not defined, must be top-level add
		($parent) = $frameStruct->source_vertices();
                
                # If we can't get parent using source_vertices, we must just have one node left
                #    in the structure
                if( !defined($parent)){
                        ($parent) = $frameStruct->vertices();
                }
		$topLevelAdd = 1;
		#print "Top level add parent = $parent\n";
	}

	if ( defined($parent) ) {

		# Find parent direction
		my $pAttr = $frameStruct->get_attribute( 'attr', $parent );
		my $dir   = $pAttr->{dir} || '';
		if (     $dir eq 'H' && ( $currentSide eq 'left' || $currentSide eq 'right' )
		      || $dir eq 'V' && ( $currentSide eq 'top'  || $currentSide =~ 'bot' ) ) {
			#print "compatible Direction Add\n";

			$widgets->{$widgetName} = $widget;

			# Add this new frame to the current paned window
			my $pw = $widgets->{$parent};

			# Figure out if we are adding before/after the current widget
			my $beforeAfter = '-after';
			if (     ( $dir eq 'H' && $currentSide eq 'left' )
			      || ( $dir eq 'V' && $currentSide eq 'top' ) ) {
				$beforeAfter = '-before';
			}

			my $childOrder    = $pAttr->{childOrder};
			my $expandfactors = $pAttr->{expandfactors} || [map 0, @$childOrder]; # default expandFactors is all zereoes

			my $frameIndex;    # Frame index we are adding before/after

			if ($topLevelAdd) {    # top level add is either at the beginning or end
				if ( $beforeAfter eq '-before' ) {
					$pw->add( $widget, $beforeAfter => $widgets->{ $childOrder->[0] },
                                               %addAttr);
					$frameIndex = 0;
				}
				else {
					$pw->add($widget, %addAttr);
					$frameIndex = $#$childOrder;
				}
			}
			else {                 # Normal non-topLevel add
				$pw->add( $widget, $beforeAfter => $widgets->{$currentFrame},
                                        %addAttr);
			}

			# Update Structure
			$frameStruct->add_edge( $parent, $widgetName );

			unless ($topLevelAdd) {    # find frame index, if not adding from top level
				($frameIndex) = grep $childOrder->[$_] eq $currentFrame,
				  ( 0 .. $#$childOrder );    # get index of currentFrame
			}

			if ( $beforeAfter eq '-before' ) {
				splice @$childOrder,    $frameIndex, 0, $widgetName;
				splice @$expandfactors, $frameIndex, 0, $expandfactor;
			}
			else {
				splice @$childOrder,    $frameIndex + 1, 0, $widgetName;
				splice @$expandfactors, $frameIndex + 1, 0, $expandfactor;
			}

			#print "New childOrder = ".join(", ", @$childOrder);
                        # Make sure we can see the widget added
                        $widget->Tk::Widget::raise unless ( $widget->isa('Tk::Panedwindow') ); # Needed for widgets to show up that were created before the panedwindow

		}
		else {
			#print "In-compatible Direction Add\n";
			$widgets->{$widgetName} = $widget;

			# Forget widget that we are adding to (unless toplevel)
			my $pw;
			unless ($topLevelAdd) {
				$pw = $widgets->{$parent};
				$pw->forget( $widgets->{$currentFrame} );
			}
			else {
				$widgets->{$currentFrame}->packForget();
				$pw = $self->Subwidget('mainPW');
			}

			$frameStruct->delete_edge( $parent, $currentFrame )
			  unless ($topLevelAdd);    # delete the widget in the structure

			# Replace with a panedWindow in the incompatible direction
			my $dir   = 'V';
			my $pwDir = "vertical";
			if ( $currentSide eq 'left' || $currentSide eq 'right' ) {
				$dir   = 'H';
				$pwDir = "horizontal";
			}
                        
                        my $IDEpanedwindowConfig = $self->cget(-IDEpanedwindowConfig);

			my $subPw = $self->IDEpanedwindow(  -orient => $pwDir,
						            @$IDEpanedwindowConfig );
                        
			$subPw->pack( -in => $pw, qw/-side top -expand yes -fill both / );

			# Give this new PW a name and save it in the widget structure
                        
                        #  Create a new PW name
                        my $PWname = $self->_createNewPWname();
                        $widgets->{$PWname} = $subPw;

			# find out where the current frame was in the parent PW, so
			#   we know where to replace it with the subPW
			my ( $childOrder, $frameIndex);
			unless ($topLevelAdd) {
				$childOrder          = $pAttr->{childOrder};
				($frameIndex) = grep $childOrder->[$_] eq $currentFrame,
				  ( 0 .. $#$childOrder );    # get index of currentFrame
				                             # Update Child Order for the PW we are replacing
				$childOrder->[$frameIndex] = $PWname;
                                
                                
			}

			# Update Structure for the PW we are replacing
			$frameStruct->add_vertex($PWname);
			$frameStruct->add_edge( $parent, $PWname ) unless ($topLevelAdd);

			my @beforeAfter;
			if ($topLevelAdd) {                  # top level add needs no beforeAfter
				@beforeAfter = ();
			}
			elsif ( $frameIndex == 0 ) {
                                if( defined( $childOrder->[1]) ){ # before the second entry, if it exists
                                                @beforeAfter = ( -before => $widgets->{ $childOrder->[1] } );
                                }
			}
			else {
				@beforeAfter = ( -after => $widgets->{ $childOrder->[ $frameIndex - 1 ] } );
			}

			# Add new widget and forgotten widget to the new panedWindow
			my @order       = ( $widget, $widgets->{$currentFrame} );
                        my %addOptions  = ( "$widget" => { %addAttr });
                                                
			my @newChildOrder    = ( $widgetName,   $currentFrame );
                        my @newExpandfactors = ( $expandfactor, 0);  # Current frame expandfactor defaults to zero
			if ( $currentSide eq 'right' || $currentSide =~ /bot/ ) {
				@order         = reverse @order;
				@newChildOrder = reverse @newChildOrder;
				@newExpandfactors = reverse @newExpandfactors;
			}
                        
                        # Do the actual adding, also check to include options for each widget added
                        my @addArgs;
                        foreach (@order){
                                push @addArgs, $_;
                                if( defined( $addOptions{"$_"})){
                                        my $widgetAddOptions = $addOptions{"$_"};
                                        push @addArgs, %$widgetAddOptions;
                                }
                        }
			$subPw->add(@addArgs);
                        
			foreach ( $widget, $widgets->{$currentFrame} ) {    # make sure added widgets can be seen
                                # Specific Tk::Widget package called out here, because Tk::DynaTabFrame overrides the raise
                                #   method to something different than what Tk::Widget::raise does.
                                $_->Tk::Widget::raise unless ( $widget->isa('Tk::Panedwindow') ); # Needed for widgets to show up that were created before the panedwindow
				# Panedwindows aren't raised
				# These will obscure widgets if raised
			}

			$pw->add( $subPw, @beforeAfter )
			  unless ($topLevelAdd)
			  ;          # This has to be done after the $subPW add, or the subPW isn't visible

			# Add attributes for the new PW vertex in the frameStruct
			my $attr = { dir => $dir, childOrder => [@newChildOrder],
                                     expandfactors => [@newExpandfactors] };
			$frameStruct->set_attribute( 'attr', $PWname, $attr );

			# Add edges for the leaf nodes
			$frameStruct->add_edge( $PWname, $widgetName );
			$frameStruct->add_edge( $PWname, $currentFrame );

			# For top level add, we have to raise all the
			#   non Panedwindow widgets, or they won't be visible
			if ($topLevelAdd) {
				foreach my $widgetName ( keys %$widgets ) {
					my $widget = $widgets->{$widgetName};
                                        # Specific Tk::Widget package called out here, because Tk::DynaTabFrame overrides the raise
                                        #   method to something different than what Tk::Widget::raise does.
                                        $widget->Tk::Widget::raise unless ( $widget->isa('Tk::Panedwindow') ); # Needed for widgets to show up that were created before the panedwindow
				}
			}

		}
	}

        $self->adjustGeom if( $self->cget(-ResizeOnReconfig)); # Resize to requested width/height if ResizeOnConfig true
        
        # Fix the Dropsites so that the IDELayout dropsite is allways last in the order
        #   Otherwise, the background IDElayout dropsites will show up first before others
        #    (like the IDEtabFrame dropsites).
        my $DropSites = $self->toplevel->{DropSites}{Local};
        my @IDElayoutDropSites = grep $_->isa("Tk::IDElayoutDropSite"),    @$DropSites;
        my @otherDropSites =     grep !($_->isa("Tk::IDElayoutDropSite")), @$DropSites;
        @$DropSites = (@otherDropSites, @IDElayoutDropSites);

}

###############################################################################

=head2 _createNewPWname()

Method create a unique Paned-Window name from the existing Paned-Window widgets being managed
by this widget. 
        
For example, if there are Paned-Window P1, P2, P3 being managed, then this method will return P4.

B<Usage:>

   my $newName = $self->_createNewPWname();


=cut

sub _createNewPWname{
        
        my $self = shift;
        
	my $frameGraph  = $self->cget('-frameGraph');
        
        my @nodes = $frameGraph->vertices();
        
        my @pwNodes;
        # Find the PaneWindow nodes
        foreach my $node(@nodes){
                my $attr = $frameGraph->get_attribute('attr', $node); # Get the attribute hash
                push @pwNodes, $node if( defined($attr->{childOrder}));
        }
        
        # Find the highest index of Panedwindow like 'P1', 'P2', ...
        my $maxPWindex = -1;
        foreach my $node(@pwNodes){
                if( $node =~ /^P(\d+)/){
                        $maxPWindex = $1 if( $1 > $maxPWindex);
                }
        }
        
        $maxPWindex++; # increment for new name
        
        return "P$maxPWindex";
}
                        
###############################################################################

=head2 deleteWidget

Method to delete a widget from being managed by L<Tk::IDElayout>

B<Usage:>

   my $widget $self->deleteWidget($widgetName);

	where: 
          $widgetName:   Name of the widget to delete
	  $widget:       Widget deleted

=cut

sub deleteWidget{
        my $self         = shift;
        my $widgetName   = shift;

	my $frameStruct  = $self->cget('-frameGraph');
	my $widgets      = $self->cget('-widgets');
        
	# Get the PW name that manages this widget
        my ($pwName) = $frameStruct->predecessors($widgetName);
        
        unless( defined($pwName)){
                croak("Error Can't find PanedWindow that $widgetName is in\n");
        }
        
        # Delete widget from structures
        my $widget = $widgets->{$widgetName};
        my $pw = $widgets->{$pwName};
        $pw->forget($widget);
        delete $widgets->{$widgetName};

        # Perform simplification after the delete
        #   (i.e. don't end up with a Panedwindow with just one element)
       $self-> simplifyAfterDelete($pwName, $widgetName);
 
        $self->adjustGeom if( $self->cget(-ResizeOnReconfig)); # Resize to requested width/height if ResizeOnConfig true

        return $widget;
}

################################################################################

=head2 simplifyAfterDelete

Sub to simplify the window structure after a delete. 

This checks to see if there is a Panewindow with only one element, and if there is, gets
rid of it.

B<Usage:>

   $self->simplifyAfterDelete($pwName, $widgetName);
     
   where:
      $pwName:      Parent panedwindow name of the widget just deleted
      $widgetName:  Name of the widget just deleted


=cut

sub simplifyAfterDelete{
        my $self        = shift;
	my $pwName      = shift;
	my $frameName   = shift;

	my $frameStruct  = $self->cget('-frameGraph');
	my $widgets      = $self->cget('-widgets');
	
	my $pw          = $widgets->{$pwName};

	# Find Siblings in the graph structure of the frame we are deleting
	my @kids = $frameStruct->successors($pwName);

	my @siblings = grep $_ ne $frameName, @kids;

	# delete frame from structure
	$frameStruct->delete_vertex($frameName);
	
	# Remove frame from parent childorder
	my $pwAttr = $frameStruct->get_attribute( 'attr', $pwName );
	my $childOrder = $pwAttr->{childOrder};
	@$childOrder = grep $_ ne $frameName, @$childOrder;
	
	# Structure will need simplification if there is only one sibling
	#   (i.e. no need to have a panedwindow with only one child)
	if ( @siblings == 1 ) {
		my $siblingName = $siblings[0];
		my $sibling     = $widgets->{$siblingName};

		# Forget Sibling in the parent node
		$pw->forget($sibling);

		# Parent's-Parent (P2)
		my ($p2Name) = $frameStruct->predecessors($pwName);
		if( $p2Name){ 
			my $p2 = $widgets->{$p2Name};
			my $p2Attr = $frameStruct->get_attribute( 'attr', $p2Name );


			# Find Parents place in Parents's parent (p2)
			my $p2ChildOrder = $p2Attr->{childOrder};
			my @positionDesc;    # This is of the form -before => $widgetName
		                     	     #    or -after => $widgetName
			if ( $p2ChildOrder->[0] eq $pwName ) {    # Case where pwName is first
                                if( defined( $p2ChildOrder->[1]) ){ # Add before the second entry, if it exists
                                        @positionDesc = ( -before => $widgets->{ $p2ChildOrder->[1] } );
                                }
			}
			else {
				my $after;
				foreach my $nodeName (@$p2ChildOrder) {
					last if ( $nodeName eq $pwName );
					$after = $nodeName;
				}
				@positionDesc = ( -after => $widgets->{$after} );
			}

			# Forget Parents window in its parent (p2)
			$p2->forget($pw);
		
			delete $widgets->{$pwName};

			# Delete parent window node in the graph structure
			$frameStruct->delete_vertex($pwName);

			# add sibling node to parent-parent (p2) panewindow, after the place defined above
			$p2->add( $sibling, @positionDesc );

			# Add the sibling node to the parent-parent node (i.e. make an edge)
			$frameStruct->add_edge( $p2Name, $siblingName );

			# Update parent-parent node (p2)
			#     attribute childorder to replace the deleted pw with the sibling
			foreach (@$p2ChildOrder) {
				$_ = $siblingName if ( $_ eq $pwName );
			}
		}
		else{   # Parent has no predecessors, must be a top level node
                        
                        # Get the toplevel frame
                        my $mainPW = $self->Subwidget('mainPW');
                        
			my $deletedPW = delete $widgets->{$pwName};
                        $deletedPW->packForget; # Remove deleted PW from packing order

			# Delete parent window node in the graph structure
			$frameStruct->delete_vertex($pwName);
			
                        # pack the sibling in the toplevel frame
			$sibling->pack(	-in => $mainPW, (qw/-side top -expand yes -fill both /));
		}

			

	}

}

########################################################################

=head2 displayStruct

Debug-only method to display the structure of the managed widgets as a Directed Graph using L<GraphViz>
and L<Tk::GraphVizViewer>.
 
Requires the L<Tk::GraphVizViewer> widget.

B<Usage:>

   $self->displayStruct($title);
   
      where: $title: Optional title to give the display window


=cut

sub displayStruct{
	
        my $self = shift;
        my $title = shift;
	my $graph = $self->cget('-frameGraph');

	my $widgets      = $self->cget('-widgets');

        require Tk::GraphVizViewer;
        require GraphViz;
        
	my $g = new GraphViz;
	my @edges = $graph->edges();
	
	while (@edges){
		my $from = shift @edges;
		my $to   = shift @edges;
		$g->add_edge($from,$to);
	}
	
	my $gviewer = $self->Toplevel->GraphVizViewer( 
 	-graphviz => $g,
	-nodefill => 'lightsteelblue1',
	 )->pack(-expand => 1, -fill => 'both');
         
         $gviewer->toplevel->title($title) if( defined $title);
	 
	 # Printout attr of all panedwindow widgets
	 print "#########################\n";
	 foreach my $widget(sort keys %$widgets){
		 if( $widget =~ /^P\d+/){
			 my $attr = $graph->get_attribute('attr', $widget); # Get the attribute hash
			 my $dir =  $attr->{dir};
			 my $childOrder = $attr->{childOrder};
			 print "$widget: $dir  ".join(", ", @$childOrder)."\n";
		 }
	 }
}	 

########################################################################

=head2 Drop

Method called when accepting a drop from a drag-drop operation.
        
Creates and populates a new L<Tk::IDEtabFrame> widget to hold the dragged widget.


=cut

sub Drop{
        my $cw  = shift;
        my $selection = shift;
        my ($sel) = $cw->toplevel->SelectionGet('-selection'=>$selection);
        my $DropBox = Tk::IDElayout::DropBox->instance();
        my $object = $DropBox->delete($sel);
        #print "############ In drop Command object keys = ".join(", ", sort keys %$object)."\n"; 
        
        my ($DragSource, $IDEobject, $Caption, $Contents, $PackInfo) = 
                @$object{qw/DragSource Object Caption Contents PackInfo/};

        my ($currentSide, $currentFrame) = @$cw{ qw/ currentSide currentFrame /};

        #print "############## In Dropcommand: currentSide = $currentSide / $currentFrame\n";

        # Create new IDEtabFrame for the dropped widget
        my $IDEtabFrameConfig = $cw->cget(-IDEtabFrameConfig);
        my $tabFrame = $cw->toplevel->IDEtabFrame( @$IDEtabFrameConfig);

        my $widgets = $cw->cget(-widgets);

        my $widgetFrame = $tabFrame->add(
                -caption => $object->{Caption},
                -label   => $object->{Caption}
        );

        # If the source is a toolwindow, capture the window (i.e. make it a non-toplevel again)
        if( $DragSource =~ /toolwindow/i ){

                # Get rid of the dragArea in the toolwindow
                my ($dragArea) = $Contents->packSlaves;
                $dragArea->packForget();

                $Contents->wmCapture;
        }
        
        my %packOptions = (@$PackInfo, -in => $widgetFrame); # Override the '-in' in the packInfo
        $Contents->pack(%packOptions);


        # Make sure the tabFrame is updated to propagate its geometry
        #print "TabFrame W/H = ".$tabFrame->reqwidth."/".$tabFrame->reqheight."\n";
        #print "widgetframe W/H = ".$widgetFrame->reqwidth."/".$widgetFrame->reqheight."\n";
        $widgetFrame->idletasks;
        $tabFrame->TabRaise($object->{Caption});
        $tabFrame->idletasks;
        #print "TabFrame W/H = ".$tabFrame->reqwidth."/".$tabFrame->reqheight."\n";
        #print "widgetframe W/H = ".$widgetFrame->reqwidth."/".$widgetFrame->reqheight."\n";
 
        # Find new tab name
        my $tabIndex = 0;
        foreach my $widgetName(keys %$widgets){
                if( $widgetName =~ /tab(\d+)/){
                        $tabIndex = $1 if( $1 > $tabIndex);
                }
        }
        $tabIndex++; 
        my $tabName = "tab$tabIndex";
        
        $cw->addWidgetAtSide($tabFrame, $tabName, $currentFrame, $currentSide);


}

########################################################################

=head2 defaultIDEtabFrameConfig

Cleas method that returns the default L<Tk::IDEtabFrame> options that will be used
to set the -IDEtabFrameConfig options if not supplied.
        
This is broken out as a class method so the defaults can be used for initial setup of
the L<Tk::IDEtabFrame> widgets for simple example scripts.

B<Usage:>

   my $tabFrameConfig = Tk::IDElayout->defaultIDEtabFrameConfig()

=cut

sub defaultIDEtabFrameConfig{
        my $class = shift;
        
        return [
                -tabclose => 1,
                -tabcolor => 'white',
                -raisecolor => 'grey90',
                -tabpady => 1,
                -tabpadx => 1,
                -padx => 0,
                -pady => 0,
                -bg => 'white',
                -raisedfg => 'black',                        
                -raisedCloseButtonfg => 'black',
                -raisedCloseButtonbg => 'lightgrey',
                -raisedCloseButtonActivefg => 'red',
                -noraisedfg => 'grey60',
                -noraisedActivefg => 'black',
                -noraisedCloseButtonfg => 'lightgrey',
                -noraisedCloseButtonbg => 'white',
                -noraisedCloseButtonActivefg => 'red',
         ];
}

#######################################################################

=head2 adjustGeom

Method to resize the main window of the GUI to the requested width/height of the window. 
        
This is called at the end of the I<deleteWidget> and I<addWidgetAtSide> methods if the I<ResizeOnReconfig>
option is 1.


B<Usage:>

   $self->adjustGeom()

=cut


sub adjustGeom{
        my $self         = shift;
        
        $self->afterIdle( sub{
                        
                        my $mw = $self->toplevel;
        
                        $mw->idletasks;
                        my ($reqW, $reqH) = ($mw->reqwidth, $mw->reqheight);
                        my ($w, $h) = ($mw->width, $mw->height);
        
                        #print "Req W/H = $reqW $reqH\n";
                        #print "Actual W/H = $w $h\n";
                        
                        #$mw->configure(-width => $reqW, -height => $reqH);
                        $mw->geometry($reqW."x".$reqH);
        }
        );
        
}
        


1;

