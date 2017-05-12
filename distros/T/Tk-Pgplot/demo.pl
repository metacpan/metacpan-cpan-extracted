#!/usr/bin/perl -w

use strict;

use blib;

use Tk;
use Tk::Pgplot;
use PGPLOT;

use constant IMAGE_SIZE => 129;
use constant SLICE_SIZE => 100;
use constant XA => int -(IMAGE_SIZE)/2;
use constant XB => int  IMAGE_SIZE/2;
use constant YA => int -(IMAGE_SIZE)/2;
use constant YB => int  IMAGE_SIZE/2;
use constant SCALE => 40/IMAGE_SIZE;

sub create_main_menubar ($);
sub create_image_area ($);
sub create_slice_area ($);
sub create_save_dialog ($);
sub create_help_dialog ($);
sub create_world_labels ($);
sub create_option_menu ($$);

# Define some colour tables.

# Define single-colour ramp functions.
my $grey_l  = [0.0,1.0];
my $grey_c  = [0.0,1.0];


# Define a rainbow colour table.
my $rain_l = [-0.5, 0.0, 0.17, 0.33, 0.50, 0.67, 0.83, 1.0, 1.7];
my $rain_r = [ 0.0, 0.0,  0.0,  0.0,  0.6,  1.0,  1.0, 1.0, 1.0];
my $rain_g = [ 0.0, 0.0,  0.0,  1.0,  1.0,  1.0,  0.6, 0.0, 1.0];
my $rain_b = [ 0.0, 0.3,  0.8,  1.0,  0.3,  0.0,  0.0, 0.0, 1.0];


# Iraf "heat" colour table.
my $heat_l = [0.0, 0.2, 0.4, 0.6, 1.0];
my $heat_r = [0.0, 0.5, 1.0, 1.0, 1.0];
my $heat_g = [0.0, 0.0, 0.5, 1.0, 1.0];
my $heat_b = [0.0, 0.0, 0.0, 0.3, 1.0];


# AIPS tvfiddle discrete rainbow colour table.

my $aips_l = [0.0, 0.1, 0.1, 0.2, 0.2, 0.3, 0.3, 0.4, 0.4, 0.5,
	      0.5, 0.6, 0.6, 0.7, 0.7, 0.8, 0.8, 0.9, 0.9, 1.0];
my $aips_r = [0.0, 0.0, 0.3, 0.3, 0.5, 0.5, 0.0, 0.0, 0.0, 0.0,
	      0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0];
my $aips_g = [0.0, 0.0, 0.3, 0.3, 0.0, 0.0, 0.0, 0.0, 0.8, 0.8,
	      0.6, 0.6, 1.0, 1.0, 1.0, 1.0, 0.8, 0.8, 0.0, 0.0];
my $aips_b = [0.0, 0.0, 0.3, 0.3, 0.7, 0.7, 0.7, 0.7, 0.9, 0.9,
	      0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

# List the supported colour tables.
my %cmap = ("grey",    [$grey_l, $grey_c, $grey_c, $grey_c, scalar(@$grey_l)],
	    "rainbow", [$rain_l, $rain_r, $rain_g, $rain_b, scalar(@$rain_l)],
	    "heat",    [$heat_l, $heat_r, $heat_g, $heat_b, scalar(@$heat_l)],
	    "aips",    [$aips_l, $aips_r, $aips_g, $aips_b, scalar(@$aips_l)],
	    );

my $mw = MainWindow->new(-title => 'Pgptkdemo');
$mw->iconname("Pgtkdemo");
$mw->configure(-cursor => 'top_left_arrow');

# Override selected widget defaults.

$mw->optionAdd('*font' => '-Adobe-Times-Medium-R-Normal-*-140-*',
	       'widgetDefault');

# Set default widget colours.

my $bg = '#bfe5ff';
my $alt_bg = '#00ddff';
$mw->configure(bg => $bg);
$mw->optionAdd('*background' => $bg, 'widgetDefault');
$mw->optionAdd('*activeBackground' => $bg, 'widgetDefault');
$mw->optionAdd('*activeForeground' => 'blue', 'widgetDefault');
$mw->optionAdd('*highlightBackground' => $bg, 'widgetDefault');
$mw->optionAdd('*troughColor' => $bg, 'widgetDefault');
$mw->optionAdd('*Scrollbar.width' => '3m', 'widgetDefault');
$mw->optionAdd('*Scrollbar.background' => $alt_bg, 'widgetDefault');
$mw->optionAdd('*Scrollbar*Foreground' => $alt_bg, 'widgetDefault');
$mw->optionAdd('*Button*Background' => $alt_bg, 'widgetDefault');
$mw->optionAdd('*Button*activeBackground' => $alt_bg, 'widgetDefault');
$mw->optionAdd('*Button*activeForeground' => 'black', 'widgetDefault');
$mw->optionAdd('*Menubutton*activeForeground' => 'black', 'widgetDefault');

# Create the menu-bar
my $menubar = create_main_menubar($mw);

# Create label widgets for use in displaying image world coordinates
my ($world, $xworld, $yworld) = create_world_labels($mw);

# Create a PGPLOT window with scroll bars, and enclose them in a frame.
# This is the image window.
my ($imagearea, $pgimage) = create_image_area($mw);

# Create a PGPLOT window, and enclose it in a frame.
# This is the slice window.
my ($slicearea, $pgslice) = create_slice_area($mw);

my %demodata = initialize_demo();

# Create the function-selection option menu.
my $function = create_option_menu($mw, $pgimage);

# Create dialogs for later display.

my $save_dialog = create_save_dialog($mw);
my $help_dialog = create_help_dialog($mw);

# Place the menubar at the top of the main window and the work-areas
# underneath it.
$world->pack(-side => 'top',  -anchor => 'w');
$imagearea->pack(-side => 'top', -fill => 'both', -expand => 1);
$function->pack(-side => 'top',  -fill => 'x');
$slicearea->pack(-side => 'top', -fill => 'both', -expand => 1);

# Windows in Tk do not take on their final sizes until the whole
# application has been mapped. This makes it impossible for the
# PGPLOT widget to correctly guess what size of pixmap to allocate
# when it starts the first page. To avoid this problem, force Tk
# to create all of the windows before drawing the first plot.
$mw->idletasks;

# Draw the initial image.
draw_image($mw, 0);

MainLoop;

# This procedure creates the main menubar of the application.
sub create_main_menubar ($) {
  my $mw = shift;

  my $menubar = $mw->Menu;
  $mw->configure(-menu => $menubar);

  # Create the file menu.
  my $filemenu = $menubar->cascade(-label => 'File',
				   -tearoff => 0,
				   -menuitems => [
	 [Button => 'Save image as ...',
	  -command => sub {$save_dialog->deiconify;
			   $save_dialog->raise}],
	 [Separator => ''],
	 [Button => 'Quit',
	  -command => sub {exit}]
						 ]);
  # Arrange that Alt-Q will abort the application.
  $mw->bind('all', '<Alt-KeyPress-q>' => sub {exit});

  # Create the help menu
  my $helpmenu = $menubar->cascade(-label => 'Help',
				   -tearoff => 0,
				   -menuitems => [
	 [Button => 'Usage',
	  -command => sub {$help_dialog->deiconify;
			   $help_dialog->raise}]]);

  return $menubar;
}

# Create an area in which to display the world coordinates of the cursor
# when it is over the image window.
sub create_world_labels ($) {
  my $mw = shift;

  # Enclose the area in a frame.
  my $world = $mw->Frame(-width => '11c', -height => '1c');

  # Create a static title label.
  my $title = $world->Label(-text => 'World coordinates:');

  # Create the X and Y labels for displaying the respective coordinates.
  my $x = $world->Label(-width => 12,
		    -anchor => 'w');
  my $y = $world->Label(-width => 12,
		    -anchor => 'w');

  # Pack the widgets
  $title->pack(-side => 'left',
	       -anchor => 'w');
  $x->pack(-side => 'left',
	   -anchor => 'w',
	  -padx => '2m');
  $y->pack(-side => 'left',
	   -anchor => 'w',
	  -padx => '2m');

  return $world, $x, $y;
}

# This procedure is called whenever cursor motion is detected in the
# the image widget. It displays the world coordinates of the cursor
# in previously created label widgets.
sub report_motion {
  my $pg = shift;
  my $e = $pg->XEvent;
  my $x = $e->x;
  my $y = $e->y;
  my $xx = sprintf "X=%.2f", $pg->world('x', $x);
  my $yy = sprintf "Y=%.2f", $pg->world('y', $y);
  $xworld->configure(-text => $xx);
  $yworld->configure(-text => $yy);
}

# Create the area that contains the image PGPLOT window.
sub create_image_area ($) {
  my $mw = shift;

  # Frame the workarea
  my $w = $mw->Frame(-width => '11c', -height => '11c');

  # Create the PGPLOT image window.
  my $pgplot = $w->Pgplot(-name => 'image',
			  -share => 1,
			  -width => '10c',
			  -height => '10c',
			  -mincolors => 25,
			  -maxcolors => 64,
			  -bd => 2,
			  -bg => 'black',
			  -fg => 'white',
			  -cursor => ['crosshair', 'black', 'white']);

  # Create horizontal and vertical scroll-bars and have them
  # call the pgplot xview and yview scroll commands to scroll the
  # image within the window.
  my $xscroll = $w->Scrollbar(-orient => 'horizontal',
			      -command => ['xview', $pgplot]);
  my $yscroll = $w->Scrollbar(-orient => 'vertical',
			      -command => ['yview', $pgplot]);

  # Tell the PGPLOT widget how to update the scrollbar sliders.
  $pgplot->configure(-xscrollcommand => ['set', $xscroll]);
  $pgplot->configure(-yscrollcommand => ['set', $yscroll]);


  # Position the PGPLOT widget and the scrollbars.
  $xscroll->pack(-side => 'bottom', -fill => 'x');
  $yscroll->pack(-side => 'right', -fill => 'y');
  $pgplot->pack(-side => 'left',
		-fill => 'both',
		-expand => 1);

  # Bind motion events to the world coordinate x and y label widgets.
  $pgplot->bind('<Motion>' => \&report_motion);

  return ($w, $pgplot);
}

# A sinc(radius) function.
sub sinc_fn ($$) {
  my ($x, $y) = @_;

  my $radius = sqrt($x*$x + $y*$y);
  return (abs($radius) < 1.0e-6) ? 1.0 : sin($radius)/$radius;
}

# A exp(-(x^2+y^2)/20) function.
sub gaus_fn ($$) {
  my ($x, $y) = @_;

  return exp(-(($x*$x)+($y*$y))/20.0);
}

# A cos(radius)*sin(angle) function.
sub ring_fn ($$) {
  my ($x, $y) = @_;
  return cos(sqrt($x*$x + $y*$y)) *
    sin(($x==0.0 && $y==0.0) ? 0.0 : atan2($x,$y));
}

 # A sin(angle) function.
sub sin_angle_fn ($$) {
  my ($x, $y) = @_;
  return sin(($x==0.0 && $y==0.0) ? 0.0 : atan2($x,$y));
}

# A cos(radius) function.
sub cos_radius_fn () {
  my ($x, $y) = @_;
  return cos(sqrt($x*$x + $y*$y));
}

# A (1+sin(6*angle))*exp(-radius^2 / 100)function.
sub star_fn ($$) {
  my ($x, $y) = @_;
  return (1.0 + sin(($x==0.0 && $y==0.0) ? 0.0 : 6.0*atan2($x,$y)))
    * exp(-(($x*$x)+($y*$y))/100.0);
}

sub draw_image {
  my $mw = shift;
  my $plotid = shift;

  # Display a busy-cursor.
  $mw->Busy();

  # Install the new function
  if ($plotid==0) {
    $demodata{fn} = \&ring_fn;
  } elsif ($plotid==1) {
    $demodata{fn} = \&sinc_fn;
  } elsif ($plotid==2) {
    $demodata{fn} = \&gaus_fn;
  } elsif ($plotid==3) {
    $demodata{fn} = \&sin_angle_fn;
  } elsif ($plotid==4) {
    $demodata{fn} = \&cos_radius_fn;
  } elsif ($plotid==5) {
    $demodata{fn} = \&star_fn;
  }
  my $fn = $demodata{fn};

  # Display a "please wait" message in the slice window.
  display_busy(%demodata);

  # Fill the image array via the current display function.
  my $value;
  my $pixel = $demodata{image};
  my $vmin = my $vmax = &$fn(XA*SCALE, YA*SCALE);
  my $i = 0;
  for (my $iy = YA; $iy<=YB; $iy++) {
    for (my $ix = XA; $ix<=XB; $ix++) {
      $value = &$fn($ix*SCALE, $iy*SCALE);
      $pixel->[$i] = $value;
      if ($value<$vmin) {
	$vmin = $value;
      } elsif ($value>$vmax) {
	$vmax = $value;
      }
      $i++;
    }
  }

  # Record the min and max values of the data array.
  $demodata{datamin} = $vmin;
  $demodata{datamax} = $vmax;

  # Display the new image.
  display_image($demodata{image_id});

  # Display instructions in the slice window.
  display_help(%demodata);

  # No slice has been selected yet.
  $demodata{have_slice} = 0;

  # Reset the cursor.
  $mw->Unbusy;

  # Arm the cursor of the image window for the selection of a slice.
  prepare_for_slice(\%demodata);
}

# Display the current image function in a specified PGPLOT device.
sub display_image ($) {
  my $id = shift;

  # Select the specified PGPLOT device and display the image array.
  pgslct($id);
  pgask(0);
  pgpage();
  pgsch(1.0);
  pgvstd();
  pgwnad(XA*SCALE, XB*SCALE, YA*SCALE, YB*SCALE);

  my @tr = (); # Coordinate definition matrix
  $tr[0] = (XA - 1) * SCALE;
  $tr[1] = SCALE;
  $tr[2] = 0.0;
  $tr[3] = (YA - 1) * SCALE;
  $tr[4] = 0.0;
  $tr[5] = SCALE;

  if ($demodata{monochrome}) {
    pggray($demodata{image}, IMAGE_SIZE, IMAGE_SIZE, 1, IMAGE_SIZE,
	   1, IMAGE_SIZE, $demodata{datamax}, $demodata{datamin}, \@tr);
  } else {
    pgimag($demodata{image}, IMAGE_SIZE, IMAGE_SIZE, 1, IMAGE_SIZE, 1, 
	   IMAGE_SIZE, $demodata{datamin}, $demodata{datamax}, \@tr);
  }
  pgsci(1);
 
  pgbox("BCNST", 0.0, 0, "BCNST", 0.0, 0);
  pglab("X", "Y", "Image display demo");
}

# Create a labelled option menu.
sub create_option_menu ($$) {
  my $mw = shift;
  my $pgimage = shift;

  # Create a frame to enclose the menu.
  my $w = $mw->Frame();
  my $w1 = $w->Frame()->pack(-side => 'top', -fill => 'x');
  my $w2 = $w->Frame()->pack(-side => 'top', -fill => 'x');

  # Create the option-menu label.
  my $dlabel = $w1->Label(-text => 'Select a display function:');

  # Create the option menu.
  my ($menutext, $function_menu);
  my $dmenu = $w1->Optionmenu(-command => [\&draw_image, $mw],
			      -variable => \$function_menu,
			      -textvariable => \$menutext);
  $dmenu->addOptions(['cos(R)sin(A)' => 0],
		     ['sinc(R)' => 1],
		     ['exp(-R^2/20.0)' => 2],
		     ['sin(A)' => 3],
		     ['cos(R)' => 4],
		     ['(1+sin(6A))exp(-R^2/100)' => 5]);

  # Create the colormap-selection option menu and label
  my $clabel = $w2->Label(-text => 'Select a color table:');
  my $cmenu = $w2->Optionmenu(-command => [\&recolour_image, $mw, $pgimage, \$function_menu]);
  $cmenu->addOptions(qw(grey rainbow heat aips));

  # Place the label to the left of the menu button.
  $dlabel->pack(-side => 'left');
  $dmenu->pack(-side => 'left');

  $clabel->pack(-side => 'left');
  $cmenu->pack(-side => 'left');

  return $w;
}

# Implement the demo "redraw_slice" command.
sub redraw_slice {
  if ($demodata{have_slice}) {
    display_slice(\%demodata, $demodata{va}, $demodata{vb});
  } else {
    display_help(%demodata);
  }
}

# Implement the demo "recolour_image" command. This takes one of a set of
# supported colour-table names and redisplays the current image with the
# specified colour table.
#
#    "aips"    -  AIPS tvfiddle colour table.
#    "grey"    -  A grey-scale colour table.
#    "heat"    -  The IRAF "heat" colour table.
#    "rainbow" -  A red colour table.
sub recolour_image {
  my $mw = shift; # Main window
  my $pgimage = shift;  # The pgplot widget
  my $fn = shift; # Current displayed function
  my $name = shift;  # The name of the desired colour table

  # If the colour table is found, install it
  if (exists($cmap{$name})) {
    pgslct($demodata{image_id});
    pgctab(@{$cmap{$name}}, 1.0, 0.5);
  } else {
    warn "Unknown colour map name $name\n";
    return;
  }

  # Redraw the current image if necessary.
  if ($pgimage->cget(-share)) {
    draw_image($mw, $$fn);
  }
}

# Create the area that contains the slice PGPLOT window.
sub create_slice_area ($) {
  my $mw = shift;

  # Frame the workarea.
  my $w = $mw->Frame(-width => '11c', -height => '6c');

  # Create the PGPLOT slice window.
  my $pgplot = $w->Pgplot(-name => 'slice',
			  -share => 1,
			  -width => '10c',
			  -height => '5c',
			  -maxcolors => 2,
			  -bd => 2,
			  -bg => 'black',
			  -fg => 'white');

  # Position the PGPLOT widget.
  $pgplot->pack(-side => 'left',
		-fill => 'both',
		-expand => 1);

  # Arrange for the plot to be redrawn whenever the widget is resized.
  $pgplot->bind('<Configure>' => \&redraw_slice);

  return ($w, $pgplot);
}

sub initialize_demo {
  my %demo = ();

  $demo{image_id} = -1;
  $demo{slice_id} = -1;
  $demo{image} = [];
  $demo{slice} = [];
  $demo{fn} = undef;
  $demo{datamin} = undef;
  $demo{datamax} = undef;
  $demo{have_slice} = 0;
  $demo{monochrome} = 0;

  # Attempt to open the image and slice widgets.
  (($demo{image_id} = pgopen('image/ptk')) >= 0) ||
    die "Unable to open pgplot image widget ($demo{image_id})";

  (($demo{slice_id} = pgopen('slice/ptk')) >= 0) ||
    die "Unable to open pgplot slice widget";

  # Now initialize the 2D image array as a 1D array to be indexed in
  # as a FORTRAN array
  for (my $i=0; $i<IMAGE_SIZE*IMAGE_SIZE; $i++) {
    $demo{image}[$i] = 0.0;
  }

 # Initialize an array to be used when constructing slices through the
 # displayed image
  for (my $i=0; $i<SLICE_SIZE; $i++) {
    $demo{slice}[$i] = 0.0;
  }

  # If there are fewer than 2 colours available for plotting images,
  # mark the image as monochrome so that pggray can be asked to
  # produce a stipple version of the image.
  pgslct($demo{image_id});
  my ($minind, $maxind);
  pgqcir($minind, $maxind);
  $demo{monochrome} = $maxind-$minind+1 <= 2;

  return %demo;
};

# Display usage instructions in the slice window
sub display_help (%) {
  my %demo = @_;

  # Clear the slice plot and replace it with instructional text
  pgslct($demo{slice_id});
  pgask(0);
  pgpage();
  pgsch(3.0);
  pgsvp(0.0, 1.0, 0.0, 1.0);
  pgswin(0.0, 1.0, 0.0, 1.0);
  pgmtxt("T", -2.0, 0.5, 0.5, "See the help menu for instructions");
}

# This image-window pgplot-cursor callback is registered by start_slice.
# It receives the start coordinates of a slice from start_slice and
# the coordinate of the end of the slice from the callback arguments
# provided by the pgplot widget.
# Input:
#  pg          The pgplot widget
#  x1,y1       The coordinate of the start of the slice in the image
#               window. These values were supplied when the callback
#               was registered by start_slice.
#  wx2,wy2     The X-window coordinate of the end of the slice.
#  demodata demo hash
sub end_slice ($$$$$%) {
  my ($pg, $x1, $y1, $wx2, $wy2, $demodata) = @_;

  prepare_for_slice($demodata);
  slice($x1, $y1, $pg->world('x',$wx2), $pg->world('y',$wy2), $demodata);
}

# This is used as a pgplot image-widget cursor callback. It augments the
# cursor in the image window with a line rubber-band anchored at the
# selected cursor position and registers a new callback to receive both
# the current coordinates and coordinates of the end of the slice when
# selected.
# Input:
#  pg       pgplot widget
#  x,y      X-window coordinates of the position that the user selected
#           with the cursor.
#  demodata demo hash
sub start_slice ($$$%) {
  my ($pg, $x, $y, $demodata) = @_;

  # Convert from X coordinates to world coordinates.
  $x = $pgimage->world('x', $x);
  $y = $pgimage->world('y', $y);
  $pgimage->setcursor('line', $x, $y, 3);
  $pgimage->bind('<ButtonPress>'
		 => [\&end_slice, $x->[0], $y->[0],
		     Ev('x'), Ev('y'),
		     $demodata]);
}


# Arm the image-widget cursor such that when the user next presses a
# mouse button or key within the image window the start of a slice
# will be selected.
sub prepare_for_slice ($) {
  my $demodata = shift;
  $pgimage->setcursor('norm', 0.0, 0.0, 1);
  $pgimage->bind('<ButtonPress>'
		 => [\&start_slice, Ev('x'), Ev('y'), $demodata]);
}

# Implement the demo "slice" command. This takes two pairs of image
# world coordinates and plots a 1D representation of the currently
# displayed function in the slice window.
#
# Input:
#  x1, x2, x3, x4   The two end points of the slice line.
#  demodata         Demo hash
sub slice ($$$$\%){
  # Read the four coordinate values.
  my %va = (); # The coordinates of one end of the slice
  my %vb = (); # The coordinates of the other end of the slice
  $va{x} = shift;
  $va{y} = shift;
  $vb{x} = shift;
  $vb{y} = shift;
  my $demodata = shift;

  # Record the slice vertices so that the slice can be redrawn
  # when the widget is resized.
  $demodata->{va} = \%va;
  $demodata->{vb} = \%vb;
  $demodata->{have_slice} = 1;

  # Plot the new slice.
  display_slice($demodata, \%va, \%vb);
}

# Display a new slice in the slice window.
# Input:
#  demodata   Demo hash
#  va         The vertex of one end of the slice line.
#  vb         The vertex of the opposite end of the slice line.
sub display_slice ($$$) {
  my ($demodata, $va, $vb) = @_;

  # Determine the slice pixel assignments.
  my $xa = $va->{x};
  my $dx = ($vb->{x} - $va->{x}) / SLICE_SIZE;
  my $ya = $va->{y};
  my $dy = ($vb->{y} - $va->{y}) / SLICE_SIZE;

  # Make sure that the slice has a finite length by setting a
  # minimum size of one pixel.
  my  $min_delta =SCALE / SLICE_SIZE;
  if(abs($dx) < $min_delta && abs($dy) < $min_delta) {
    $dx = $min_delta;
  }

  # Construct the slice in demo->{slice} and keep a tally of the
  # range of slice values seen.
  my ($value, $smin, $smax);
  my $fn = $demodata->{fn};
  for(my $i=0; $i<SLICE_SIZE; $i++) {
    $value = &$fn($xa + $i * $dx, $ya + $i * $dy);
    $demodata->{slice}[$i] = $value;
    if($i==0) {
      $smin = $smax = $value;
    } elsif($value < $smin) {
      $smin = $value;
    } elsif($value > $smax) {
      $smax = $value;
    }
  }

  # Determine the length of the slice.
  my $xlen = $dx * SLICE_SIZE;
  my $ylen = $dy * SLICE_SIZE;
  my $slice_length = sqrt($xlen * $xlen + $ylen * $ylen);

  # Determine the extra length to add to the Y axis to prevent the
  # slice plot hitting the top and bottom of the plot.
  my $ymargin = 0.05 * ($demodata->{datamax} - $demodata->{datamin});

  # Set up the slice axes.
  pgslct($demodata->{slice_id});
  pgask(0);
  pgpage();
  pgbbuf();
  pgsch(2.0);
  pgvstd();
  pgswin(0.0, $slice_length, $demodata->{datamin} - $ymargin,
	 $demodata->{datamax} + $ymargin);
  pgbox("BCNST", 0.0, 0, "BCNST", 0.0, 0);
  pglab("Radius", "Image value", "A 1D slice through the image");

  # Draw the slice.
  for(my $i=0; $i<SLICE_SIZE; $i++) {
    if($i==0) {
      pgmove(0.0, $demodata->{slice}[0]);
    } else {
      pgdraw($slice_length * $i / SLICE_SIZE, $demodata->{slice}[$i]);
    }
  }
  pgebuf();
}

# Display a "Please wait" message in the slice window.
sub display_busy (%) {

  my %demodata = @_;
  # Clear the slice plot and replace it with instructional text.

  pgslct($demodata{slice_id});
  pgask(0);
  pgpage();
  pgsch(3.5);
  pgsvp(0.0, 1.0, 0.0, 1.0);
  pgswin(0.0, 1.0, 0.0, 1.0);
  pgmtxt("T", -2.0, 0.5, 0.5, 'Please wait.');
}

# Create an unmapped help dialog.
#
# Note that the dialog is not initially mapped. To display it temporarily
# use the command {wm deiconify $w} and then when it is no longer required
# call {wm withdraw $w}.
sub create_help_dialog ($) {
  my ($mw) = @_;

  # Create the dialog container and tell the window-manager what to call
  # both it and its icon.
  my $w = $mw->Toplevel(-class => 'dialog');
  $w->withdraw;
  $w->title('Usage information');
  $w->iconname('Dialog');

  # Create the top-half of the dialog and display display the usage message
  # in it.
  my $top = $w->Frame(-relief => 'raised',  -bd => 1);

  my $msg = $top->Message(-width => '12c', -text => 'To see a slice'.
			  ' through the displayed image, move the mouse'.
			  ' into the image display window and use any'.
			  ' mouse button to select the two end points'.
			  ' of a line.'."\n\n". 'To display a different'.
			  ' image select a new image function from the'.
			  ' "Select a display function" option menu.');
  $msg->pack(-side => 'left', -expand=> 1, -fill => 'both');

  # Create the bottom half of the dialog and place a single OK button in
  # it. Arrange that pressing the OK button unmaps the dialog.
  my $bot = $w->Frame(-relief => 'raised',  -bd => 1);
  my $ok = $bot->Button(-text => 'OK', -command => sub {$w->withdraw});
  $ok->pack(-pady => '2m');

  # Arrange for carriage-return to invoke the OK key.
  $w->bind('<Return>' => sub {$ok->invoke});

  # Place the widgets in their assigned places top and bottom.
  $top->pack(-side => 'top', -fill => 'both', -expand => 1);
  $bot->pack(-side => 'top', -fill => 'both', -expand => 1);

  return($w);
}

# Create an unmapped save-image dialog.
# Note that this dialog is not initially mapped. To display it
# temporarily use the command {wm deiconify $w} and then when it is no
# longer required call {wm withdraw $w}.

sub create_save_dialog ($) {
  my $mw = shift;

  # Create the toplevel dialog window withdrawn.
  my $w = $mw->Toplevel(-class => 'dialog');
  $w->withdraw;
  $w->title('Save image');
  $w->iconname('Dialog');

  # Create the top and bottom frames.
  my $top = $w->Frame(-relief => 'raised', -bd => 1);
  $top->pack(-side => 'top', -fill => 'both', -expand => 1);
  my $bot = $w->Frame(-relief => 'raised', -bd => 1);
  $bot->pack(-side => 'bottom',  -fill => 'both', -expand => 1);

  # Create a label and an entry widget in the top frame.
  my $msg = $top->Message(-justify => 'left', -width => '8c',
			  -anchor => 'w', 
			  -text => 'Enter a PGPLOT device string:');
  my $entry = $top->Entry(-relief => 'sunken', -bd => 2, -width => 30);
  $msg->pack(-side => 'top', -anchor => 'w');
  $entry->pack(-side => 'top', -anchor => 'w');

  # Create three buttons in the bottom frame.
  my $ok = $bot->Button(-text => 'OK');
  my $cancel = $bot->Button(-text => 'Cancel', -command => sub {$w->withdraw});
  my $help = $bot->Button(-text => 'Help', -state => 'disabled');
  $ok->pack(-side => 'left', -expand => 1, -pady => '2m', -padx => '2m');
  $cancel->pack(-side => 'left', -expand => 1, -pady => '2m', -padx => '2m');
  $help->pack(-side => 'left', -expand => 1, -pady => '2m', -padx => '2m');

  # Arrange for carriage-return to invoke the OK key.
  $w->bind('<Return>' => [$ok => 'invoke']);

  $ok->configure(-command => sub {$w->withdraw; $mw->idletasks;
				  save_image($entry)});

  return $w;
}

sub save_image ($) {
  my $entry = shift;

  my $device = $entry->get();

  # Open the new PGPLOT device.
  my $device_id = pgopen($device);

  # If the device was successfully opened, plot the current image
  # within it and close the device.
  if($device_id > 0) {
    display_image($device_id);
    pgclos();
  } else {
    warn "cpgopen(\"$device\") failed.\n";
  }
}
