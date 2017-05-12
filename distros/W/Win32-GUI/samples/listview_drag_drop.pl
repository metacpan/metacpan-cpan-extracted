#!perl -w

# Listview with drag and drop capaility
# Authors: Chris Wearn, Jez White, Robert May
# July 2005

use strict;
use warnings;

use Win32::GUI 1.03_03, qw(TPM_LEFTALIGN TPM_TOPALIGN TPM_RIGHTBUTTON
                            ILC_COLOR ILC_COLOR24 ILC_MASK
			    WM_CONTEXTMENU CW_USEDEFAULT
			    LVS_ICON LVS_REPORT LVS_SMALLICON LVS_LIST
			    LVIR_SELECTBOUNDS LVSIL_SMALL);

use Win32::GUI::BitmapInline ();

our $VERSION = "0.01";

my $DEBUG=0;  # set to a false value to turn off debugging output

my $NUM_ITEMS = 20; # set to the number of items you want in the listview

my $dragInfo = {
	dragging       => 0,       # flag to indicate whether we are dragging or not
	cursor_start_x => undef,   # cursor x position in view coordinates at start of move
	cursor_start_y => undef,   # cursor y position in view coordinates at start of move
};

######################################################################
# Cursor for use when dragging
my $curDrag = newCursor Win32::GUI::BitmapInline( q(
AAACAAEAICAAABAACAAwAQAAFgAAACgAAAAgAAAAQAAAAAEAAQAAAAAAAAEAAAAAAAAAAAAAAAAA
AAAAAAAAAAAA////AAAACqoAABVVAAAIAgAAEAEAAAgCAAAQgQAACMIAABWVAAAJqgAAAwAAAEMA
AABmAAAAfgAAAH4AAAB/wAAAf4AAAH8AAAB+AAAAfBAAAHgoAABwbAAAYIIAAEBsAAAAKAAAABAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA///gAP//4AD//+f8///n/P//53z//+Yc///mHP//
4CD//2QA//84f///GH///wD///8A////AA///wAf//8AP///AH///wD///8B7///A8f//weD//8P
Af//H4P//z/H////7/////////////////////////////////////8=
) );

######################################################################
# Create Main window
my $mw = Win32::GUI::Window->new(
	-title    => "ListView Drag and Drop Sample",
	-left     => CW_USEDEFAULT,  # let the window manager select the position
	-size     => [500,500],
	-onResize => \&resize
);

######################################################################
# Create ImageLists
my($ilLarge, $ilSmall) = CreateImageLists();

######################################################################
# Create ListView
my $lv = $mw->AddListView(
	-imagelist        => $ilLarge,
	-width            => $mw->ScaleWidth(),
	-height           => $mw->ScaleHeight(),
	-editlabel        => 1,
	-onBeginDrag      => \&beginDrag,
	-onBeginLabelEdit => sub { return 1;},
	-onEndLabelEdit   => sub { $_[0]->SetItemText($_[1],$_[2]) if defined $_[2] ; return 1; },
	-onMouseMove      => \&drag,
	-onMouseUp        => \&endDrag,
	-onMouseDown      => \&preDrag,
);

# Set the small icon imagelist (-imagelist option to AddListView
# sets both imagelists to be the same)
$lv->SetImageList($ilSmall, LVSIL_SMALL);
# Set large icon view (report view is the default)
$lv->View(LVS_ICON);

######################################################################
# Add columns for the 'report' view
$lv->InsertColumn( -text => "Column1", -width => 100);
$lv->InsertColumn( -text => "Column2", -width => 100);
$lv->InsertColumn( -text => "Column3", -width => 100);

######################################################################
# Add items to the listview
# Currently undocumented that -text item can take an array ref
# containing text for multiple columns
for my $i (1..$NUM_ITEMS) {
	$lv->InsertItem( -image => 0, -text  => ["Item ".$i, "Phone", 1024*$i],);
}

######################################################################
# Hook WM_CONTEXTMENU as the procedure to show our context menu
# WM_CONTEXTMENU is better that onMouseRightUp, as it is also
# generated for the keyboard menu key
$lv->Hook(WM_CONTEXTMENU, \&lvPopup);

######################################################################
# Some menu definitions, used for the context menus
my $Menus = Win32::GUI::Menu->new(
	"General Menu"       => "General",
	"> &Select All"       => { -name => "SelectAll",   -onClick => sub { select_all  ($lv); }, },
	"> &Deselect All"     => { -name => "DeselectAll", -onClick => sub { deselect_all($lv); }, },
	"> &Arrange"          => { -name => "Arrange",     -onClick => sub { arrange     ($lv); }, },
	"> -"                 => 0,
	"> View"              => "View",
	">> Lar&ge Icons"      => { -name => "Large",       -onClick => sub { change_view ($lv, LVS_ICON); }, },
	">> S&mall Icons"      => { -name => "Small",       -onClick => sub { change_view ($lv, LVS_SMALLICON); }, },
	">> &List"             => { -name => "List",        -onClick => sub { change_view ($lv, LVS_LIST); }, },
	">> &Details"          => { -name => "Details",     -onClick => sub { change_view ($lv, LVS_REPORT); }, },
	"Item Menu"          => "Item",
	"> &Edit Label"       => { -name => "EditLabel",   -onClick => sub { edit_label  ($lv); }, },
	"> &Change Icon"      => { -name => "ChangeIcon",  -onClick => sub { change_icon ($lv); }, },
	"> &Invert Selection" => { -name => "Invert",      -onClick => sub { invert_sel  ($lv); }, },
);

######################################################################
# Show the window and enter the dialog phase
$mw->Show();
Win32::GUI::Dialog();

exit(0);

######################################################################
# Event Handlers
######################################################################

######################################################################
# Called on left mouse down, before starting a drag
# use this to record the drag start position, as by the time we see a
# BeginDrag event, the cursor has moved (4 pixels I think).
sub preDrag
{
	my($control, $x, $y) = @_;
	print "Thinking about dragging? ($x, $y) - client coordinates\n" if $DEBUG;

	#convert cursor position into listview view coordinates
	my ($vox, $voy) = $control->GetOrigin();
	($vox, $voy) = (0,0) if not defined $vox; # GetOrigin returns undef for list and report views
	my ($cvx, $cvy) = ($x + $vox, $y + $voy);
	print "\tCursor at ($cvx, $cvy) - listview view coordinates\n" if $DEBUG;

	# store the potential start cursor position
	$dragInfo->{cursor_start_x} = $cvx;
	$dragInfo->{cursor_start_y} = $cvy;

	return 1;
}

######################################################################
# Called when a selected set of items is starting to be dragged
sub beginDrag
{
	my ($control, $item) = @_;

	my $dix;        # left corner of drag image
	my $diy;        # top corner of drag image
	my $dimagelist; # the drag image we create

	print "BeginDrag Event received for item $item (zero-based index)\n" if $DEBUG;

	# we're going to need to do a number of client to listview view coordinate
	# conversions, so get the listview origin here, once
	my ($vox, $voy) = $control->GetOrigin();
	($vox, $voy) = (0,0) if not defined $vox; # GetOrigin returns undef for list and report views

	# create the drag image
	for my $i ($control->SelectedItems()) {

		# Get the position of the image that will be created by CreateDragImage
		# NOTE: This is the top left of the rect around the icon and label, NOT
		# the top left of the item rect as returned by GetItemPosition
		# LVIR_SELECTBOUNDS returns the union of LVIR_ICON and LVIR_LABEL.
		# GetItemRect returns it's value in client coordinates, not listview
		# view coordinates
		my ($ix, $iy, undef, undef) = $control->GetItemRect($i, LVIR_SELECTBOUNDS);
		print "\tIcon for item $i at ($ix, $iy) - client coordinates\n" if $DEBUG;
		# convert to listview coordinates
	  ($ix, $iy) = ($ix + $vox, $iy + $voy);
		print "\tIcon for item $i at ($ix, $iy) - listview view coordinates\n" if $DEBUG;

		# create a temporary drag image for the item
		# NOTE: scoping of $tmp_imagelist is important so that destructors get called
		# NOTE: it really doesn't matter where we create this temporary image, as we never show it
		my $tmp_imagelist = $control->CreateDragImage($i, $ix, $iy);

		if(defined $dimagelist) {
			# Merge the existing drag image with the image for the item we are adding in this loop
			# NOTE: re-assinging a new imagelist to $dimagelist causes the ref count of the old one to go
			# to zero, so it's destructor gets called impicitly.
			$dimagelist = Win32::GUI::ImageList::Merge($dimagelist, 0, 0, $ix - $dix, $iy - $diy, $tmp_imagelist);

			# maintain the top left corner of the drag image (view coordinates)
			if($ix < $dix) { $dix = $ix; }
			if($iy < $diy) { $diy = $iy; }
		}
		else {
			# initialise the drag image
			$dimagelist = $tmp_imagelist;

			# initialise the top left corner of the drag image (view coordinates)
			$dix = $ix;
			$diy = $iy;
		}
	}

	# Temporarily change the cursor to the drag cursor
	# NOTE: Using SetCursor, the image gets changed immediatly
	# without having to move cursor again ... but we must repeat
	# the call on each mouse event, or it changes back (which is
	# what we want on mouseup, of course)
	Win32::GUI::SetCursor($curDrag);
	# Restrict cursor to listview client area while dragging
	# NOTE: could capture mouse (SetCapture), and then handle
	# not moving the icon if mouseup is outside client area
	my ($cl, $ct, $cr, $cb) = $control->GetClientRect();
	my ($sl, $st) = $control->ClientToScreen($cl, $ct);
	my ($sr, $sb) = $control->ClientToScreen($cr, $cb);
	Win32::GUI::ClipCursor($sl, $st, $sr, $sb);

	# Get the Cursor position
	my ($csx, $csy) = Win32::GUI::GetCursorPos();
	print "\tCursor at ($csx, $csy) - screen coordinates\n" if $DEBUG;
	my ($ccx, $ccy) = $control->ScreenToClient($csx, $csy);
	print "\tCursor at ($ccx, $ccy) - client coordinates\n" if $DEBUG;

	# Convert cursor position into listview view coordinates
	my ($cvx, $cvy) = ($ccx + $vox, $ccy + $voy);
	print "\tCursor at ($cvx, $cvy) - listview view coordinates\n" if $DEBUG;

	# Offset of cursor from where we draw the image. The Hotspot.
	my $offset_hx = $dragInfo->{cursor_start_x} - $dix;
	my $offset_hy = $dragInfo->{cursor_start_y} - $diy;
	print "\tHotspot offset ($offset_hx, $offset_hy)\n" if $DEBUG;

	# Create the temporary drag image
	Win32::GUI::ImageList::BeginDrag($dimagelist, 0, $offset_hx, $offset_hy);
	# Start dragging: lock updates to window and display drag image
	# NOTE: window coordinates not client coordinates
	Win32::GUI::ImageList::DragEnter( $control, $control->ClientToWindow($ccx, $ccy));

	# We're dragging
	$dragInfo->{dragging} = 1;

	return 0; # we processed the message, so don't pass it on
}

######################################################################
# Called on mouse move events - when dragging, move the drag image
sub drag
{
	my($control, $x, $y) = @_;

	# If dragging ...
	if($dragInfo->{dragging}) {
		# Maintain the drag cursor
		Win32::GUI::SetCursor($curDrag);

		# Move the drag image 
		# NOTE: window coordinates not client coorinates
		Win32::GUI::ImageList::DragMove($control->ClientToWindow($x, $y));

		return 0; # we processed the message, so don't pass it on
	}

	return 1; # we didn't process the message, so pass to default handler
}

######################################################################
# Called on mouse up events - when dragging, remove the drag image
# and move the dragged items to their new positions
sub endDrag
{
	my($control, $x, $y) = @_;

	# If dragging ...
	if($dragInfo->{dragging}) {

		# Convert client coordinates of mouse to view coordinates, and
		# calculate offset from initial cursor position
		my ($vox, $voy) = $control->GetOrigin();
		($vox, $voy) = (0,0) if not defined $vox; # GetOrigin returns undef for list and report views
		my $move_x = $vox + $x - $dragInfo->{cursor_start_x};
		my $move_y = $voy + $y - $dragInfo->{cursor_start_y};

		# re-position each selected item
		for my $i ($control->SelectedItems()) {
			my($ox, $oy) = $control->GetItemPosition($i);
			$control->ItemPosition($i, $ox + $move_x, $oy + $move_y);
		}

		print "Ending Drag ($x, $y) - client coordinates\n" if $DEBUG;
		# unlock window and hide drag image
		Win32::GUI::ImageList::DragLeave($control);
		# end the drag, destroying the temporary drag image
		Win32::GUI::ImageList::EndDrag();

		# free the cursor from the client area
		Win32::GUI::ClipCursor();

		$dragInfo->{dragging} = 0;  # not dragging any more

		return 0; # we processed the message, so don't pass it on
	}

	return 1; # we didn't process the message, so pass to default handler
}

######################################################################
# main window resize handler
sub resize
{
	my $self = shift;

	$lv->Resize($self->ScaleWidth(), $self->ScaleHeight());

	return 1;
}

######################################################################
# WM_CONTEXTMENU handler: Called on right mouse up, keyboard context
# menu key and shift-F10
sub lvPopup
{
  my ($self, $wparam, $lparam, $type, $msgcode) = @_;

	# if it isn't the event we are expecting, ignore it
  return if($type != 0);
  return if($msgcode != WM_CONTEXTMENU);

	print "Context menu called\n" if $DEBUG;

  my $hwnd = $wparam; # handle to the window clicked in

  # don't process if it's not in our window (i.e. over a child window)
  return if($hwnd != $self->{-handle});

  my $x = $lparam & 0xFFFF;  # in screen coordinates
  my $y = $lparam >> 16;     # in screen coordinates
  # convert to signed values to cope with multiple monitors
  # where screen coordinates can be negtive
  if($x > 32767) { $x -= 65536; }
  if($y > 32767) { $y -= 65536; }

	my $menu;  # which menu we'll display

  if(($x == -1) and ($y == -1)) {
    # One of Shift-F10 or VK_APP pressed

    # Our decision what to do ...
    # if no selected items, we'll display general menu at 0,0
    # if selected items, ensure first selected item is
    # visible and draw menu centered on it.

    my $selected_items = $self->GetSelectedCount();

    if($selected_items == 0) {
    	$x=0;
    	$y=0;
    	$menu=$Menus->{General};
		}
		else {
			my $item = ($self->SelectedItems())[0];
			$self->EnsureVisible($item);
			# get top left of icon, in view coordinates
			($x, $y) = $self->GetItemPosition($item);
			# convert view coordinates to client coordinates
			my ($vox, $voy) = $self->GetOrigin();
			($x, $y) = ($x - $vox, $y - $voy);
			# offset the menu from the top left of the icon
			$x += 20;
			$y += 20;
			$menu=$Menus->{Item};
		}
  }
  else {
    # if mouse over an item, select that item (other items
    # get deselected) and display item menu.  If not over
    # an item, show general menu
		($x, $y) = $self->ScreenToClient($x, $y);
    my $item = $self->HitTest($x, $y);
    if($item == -1) {
    	$menu=$Menus->{General};
		}
		else {
			$menu=$Menus->{Item};
		}
	}

	# disable the edit name item if more than one item selected
	if($self->GetSelectedCount() > 1) {
		$Menus->{EditLabel}->Enabled(0);
	}
	else {
		$Menus->{EditLabel}->Enabled(1);
	}


  # Display and process the menu (screen co-ordinates)
  $mw->TrackPopupMenu(
    $menu,
	  $self->ClientToScreen($x, $y),
    TPM_LEFTALIGN | TPM_TOPALIGN | TPM_RIGHTBUTTON, # right-click menus should allow right selection
  );

  return 0; # don't pass on as we handled it
}

######################################################################
# Menu item processing functions
######################################################################

######################################################################
# Selects all items in the listview
sub select_all
{
	my $self = shift;
	print "Got Popup Menu SELECT ALL command\n" if $DEBUG;
	$self->SelectAll();
	return 0;
}

######################################################################
# Deselects all items in the listview
sub deselect_all
{
	my $self = shift;
	print "Got Popup Menu DESELECT ALL command\n" if $DEBUG;
	$self->DeselectAll();
	return 0;
}


######################################################################
# Arrange all the icons
sub arrange
{
	my $self = shift;
	print "Got Popup Menu ARRANGE command\n" if $DEBUG;
	$self->Arrange();
	return 0;
}

######################################################################
# Edit the text label
# See also BeginEdit and EndEdit listview events
sub edit_label
{
	my $self = shift;

	my $item = ($self->SelectedItems())[0];
	print "Got Popup Menu EDIT LABEL command for Item $item\n" if $DEBUG;
	
	$self->EditLabel($item);
	return 0;
}

######################################################################
# Change the icon
sub change_icon
{
	my $self = shift;

	for my $item ($self->SelectedItems()) {
		print "Got Popup Menu CHANGE ICON command for Item $item\n" if $DEBUG;
	
		my %info = $self->GetItem($item);

		my $image = $info{-image};

		$self->ChangeItem(
			-item		=> $item,
			-image 	=> not $image,
		);
		$self->Update($item);
	}

	return 0;
}

######################################################################
# Invert the selection
sub invert_sel
{
	my $self = shift;
	print "Got Popup Menu INVERT SELECCTION command\n" if $DEBUG;
	my @items = $self->SelectedItems();
	$self->SelectAll();
	for my $item (@items) {
		$self->Deselect($item);
	}
	return 0;
}

######################################################################
# change the view type
sub change_view
{
	my $self = shift;
	my $type = shift;

	$self->View($type); # set view type
	$self->Arrange();
	return 0;
}

######################################################################
# Helper function to convert client coordinates to window
# coordinates
# Takes a 2 element list in client coordinates as input, and returns
# a 2 element list in window coordinates
sub Win32::GUI::ClientToWindow
{
	my $win = shift;
	my $x = shift;
	my $y = shift;

	my ($wl, $wt, undef, undef) = $win->GetWindowRect();
	my ($cl, $ct, undef, undef) = $win->GetAbsClientRect();

	return ($x + $cl - $wl,
	        $y + $ct - $wt);
}

######################################################################
# Function to create and return the imagelists that we will use

sub CreateImageLists
{
	my $bmpMobile = new Win32::GUI::BitmapInline( q(
	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
	) );

	my $bmpMobileMask = new Win32::GUI::BitmapInline( q(
	Qk2+AAAAAAAAAD4AAAAoAAAAIAAAACAAAAABAAEAAAAAAIAAAAAjCwAAIwsAAAIAAAACAAAAAAAA
	AP///wD//////+A////gB///4AP//8AD///AA///wAP//8AD///AA///wAP//8AD///AA///wAP/
	/8AD///AA///wAP//8AD///AA///wAP//8AD///AA///wAP//8AD///AA///wAP//8AD///AB///
	4f///+H////h////4f////H//w==
	) );

	my $bmpMobileSmall = new Win32::GUI::BitmapInline( q(
	Qk02AwAAAAAAADYAAAAoAAAAEAAAABAAAAABABgAAAAAAAADAAATCwAAEwsAAAAAAAAAAAAAAAAH
	AxMaAAAGAAAEAAUIBxQWAAEBAQUGBQABEwIGFQADHAEKDwAHAgAGAAAHAAAAAAQLAAEHETc5IE5P
	FUZEAB8dKFJRFzk4MEdJFyYpOEFFIisvKjg+AAIIAA4VAAAAAAAGFTs9J3t3GId/DIN6D4R7JI6H
	FXVvLIB+MH98Ln16NoWCKHd0CEZGAAMGAAAAAAIJFjw+j/PtQ83CDKOZAJGIdP/9Gp+cgPv5JZqZ
	if77IJGND3lzAE9MAAIGAAAABQAEKEFDr///be7nOtDKACMfM83MABETUNveACMmRsHDYNDQMJGP
	ACwsBQ4SAAAABAADJDc6vf/+lv//WfDtKc/OdP//RNXdZu76Q8rShf//Vs3PLn+CDTY5AAAEAAAA
	AA0MIzg62///nfH2YP/9ABQVUOLuABEjfvX/AAoZQd3iB4qNP3Z/OkVNAgAGAAAAAAQBAAgIFy42
	x///Z+3xT/X6cP//WOj6dv//RNHgeP//B3mAGz5LAAAHAAAEAAAAAAUBAA0MAAAIHUBNp/n/AAsW
	U///ABQdMPT+ABAbX9blADZFAAANCAcRAAEGAAAAAAsGED89ADEyAD1Fwf//ju38QtrlRv3/Itnj
	OdPeFXSDB0RSDEFLBC0wAAIEAAAAGTs6jM/KKKugAIJ8ADc/K3B/TqOzJoWVGXuNHnuKAC88JoGI
	AIB6MauhBzg2AAAAESoswv//WObZBqSYFIKCAEBJADZEADtLCktaACs2NpacHJmXROnca/fqADQx
	AAAANEJI0vn7r///fPbuc/z0effyrP//rfn/nPD1m///a//5W/vvFJ+UiurkGDc6AAAAAAEIJDg9
	BiwwneHgoP//k/32uv//rfHwk9/eqP//OMK2AHVpAFBLCTo8AAAGAAAAAAAHAAAHBwAGSUBKDxoe
	LkNFITg6JENCG0NCAC4sB0I+EkNBAAYLAAAHAAAHAAAAAAAHAQAKHgAGKQAGIAAIFgEJAgABAAMD
	AAUDAAQBABESAAADDgAGEQAJAwIMAAAA
	) );

	my $bmpMobileMaskSmall = new Win32::GUI::BitmapInline( q(
	Qk1+AAAAAAAAAD4AAAAoAAAAEAAAABAAAAABAAEAAAAAAEAAAAAjCwAAIwsAAAIAAAACAAAA////
	AAAAAAAAAAAAP/wAAH/8AAB//AAAf/wAAH/8AAB//AAAH/gAAB/wAAB/+AAAf/wAAH/8AAB//AAA
	H/wAAAAAAAAAAAAA
	) );

	my $bmpPhone = new Win32::GUI::BitmapInline( q(
	Qk02DAAAAAAAADYAAAAoAAAAIAAAACAAAAABABgAAAAAAAAMAAAAAAAAAAAAAAAAAAAAAAAA////
	////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////
	////////////////8/Pzy8vLy8vL1tbW+fn5////////////////////////////////////////
	////////////////////////////////////////////////////////////8/Pzy8vLp6etTU1/
	TU1tYWF0ubm61tbW+fn5////////////////////////////////////////////////////////
	////////////////////////////8/Pzy8vLrKyxVlaIR0ecCwvVCwuMHBx7Tk5ybGx8vLy91tbW
	+fn5////////////////////////////////////////////////////////////////////8/Pz
	y8vLp6etTU2FOzugAAD/AAD/AADjAACRAACEAACEEBB+RERsYWF0ubm61tbW+fn5////////////
	////////////////////////////////////////8/Pzy8vLrKyxVlaIR0ecCwvtCAjxAAD/AAD/
	AADjAACRAACEAACEAgKDCQmAHBx7Tk5ybGx8vLy91tbW+fn5////////////////////////////
	////////8/Pzy8vLp6etTU2FOzugAAD/AAD/AAD/AAD/AAD/DAz8KyvcBgaQAACEAACEAACEAACE
	AACEAACEEBB+RERsYWF0ubm61tbW+fn5////////////////////////y8vLrKyxVlaIR0ecCwvt
	CAjxAAD/AAD/AAD/DAz8ODj1XV3vsLDHGRmNAACEAACEAACEAACEAACEAACEAgKDCQmAHBx7Tk5y
	bGx8vLy91tbW+fn5////////////////Xl5qPj6cAAD/AAD/AAD/AAD/AAD/DAz8ODj1ZGTu///W
	8vLYmprQFhagAACEAACEAACEAACEAACEAACEAACEAACEAACEBASCJiZ2Wlplb29vurq6y8vL1tbW
	////////T0+BEhLiAAD/AAD/AAD/DAz8ODj1XV3v4uLa29vbxsbeoKDkFhb4AwPfAACYAACGAACE
	AACEAACEAACEAACEAACEBASCISF4VVVtTk6BTk5/VlZyVlZwbGx81tbW+fn5TU2FCwvtAAD/DAz8
	ODj1ZGTu///W8vLYxsbfmprlAAD/AAD/AAD/AAD/AADpAACjAACEAACEAACEAACEAACEAACEFRV8
	UlJuOzugCAjxAADjAACRAACEEBB+YWF0ubm6TU2FFxfrODj1XV3v4uLa29vbxsbeoKDkHBz6FRX1
	AADdAADVAAD/AAD/AAD7AADgAACYAACGAACEAACEAACEBASCISF4NzeJCAjrAQHkBATMEhKIFRV8
	EhJ9ISF6YGBsTU2FQ0Pk///W8vLYxsbfmprlAAD/AAD4AADdDQ2/ODh/KytiAADpAAD7AAD/AAD/
	AADpAACjAACEAACEAACEFRV8TU1qCwuUAADUAACmEBCTRERwTU1qQEBtJiZ2WlplYWGFR0fNxsbe
	oKDkHBz6FRX1AADdDAzBOTmRVFRxra20lZWjAACdAADMAAD/AAD/AAD7AADgAACYAACGAACEFRV8
	UVFoGRmEAAC7AADpAgLYCQmMCwuAFhZ7SEhqX19k1dXVbGyMEBDkAgL7AAD/DAznODh/V1dbyMjA
	qamvLS2Bi4ubODh/KytiAADpAAD7AAD/AAD/AADpAACjAACEFRV8Xl5kPj6JAAD/AAD/AADjAACR
	AACEAACEFRV8V1dm+fn5xsbHWlqRGxvWAAD/JSX1qanSioq7PT2HhISVPj6DYGBpra20lZWjAACd
	AADMAAD/AAD/AAD7AADgAACYFRV/T09pEhKYAAD/AAD/AADpAACjAACEAACEFRV8V1dm////////
	1tbWbGyLEBDkAgL7AAD/DAznODh/V1dbyMjAqamvLS2Bi4ubODh/KytiAADpAAD7AAD/AAD/AADp
	FRWcTU1qCwuaAAD/AAD/DAz8MjLhODiWKyuSFRV8V1dm////////+fn5xsbHWlqRGxvWAAD/JSX1
	qanSioq7PT2HhISVPj6DYGBpqam9g4O/AAC+AAD1AAD/AAD4AADgFRW9TU1qCwuaAAD/DAz8UVHx
	nZ3iqanVkJDHQUGKXl5o////////////////1tbWbGyLEBDkAgL7AAD/DAznODh/V1dbxsbJmprN
	AAC0AAD0AAD/BAT3EBDkAgLfAACEFRV8TU1qCwuaAAD/ODj1xsbfHBz6AAD/MDDvv7+nfHx6////
	////////////7e3toKCjSEiLFxfYAAD/JSX1qanSiorBHBy5FRXvAAD0BAT1FRXcIyPFUFCQLy/N
	AACEFRV8TU1wCwutDAz8UVHxmprlFRX7BAT3LS3Fjo6M09PT////////////8/Pzra2seXl+VFR4
	VlZyEBDkAgL7AAD/AAD/AAD4AADmBATiHx/DTU1qUVFohYV8wcG6MDCQJSV7OzuKFRXsV1fwioro
	AAD/BAT3LCy/gICO////////////////////0dHRhIR8sLC9NjakaWlHNzeQFRXZAAD/AAD/AADm
	AACdExOLPDx5CwuAGRmBbGyRxcWzo6OjT099QECoUlLmioroJSX4BAT3JyfGgICO2dnZ////////
	////////////y8vLfX12rq6lTU2FOzuEEBB+ODiGEBDkDg74KyvcBgaQFRV8QUFzAACfAACzEBDk
	UFCQdHSBYGCixsbfmprlBAT3ExPgLCy/gICO////////////////////////////y8vLbm5rcXGa
	CwvtCAjbAgKXFRWCNzeQR0fQvLzLQ0OXISF+NTWcAADxDAzxOjrxW1vhsrLSi4vcISHyKCjcKirD
	Y2OJgICO2dnZ////////////////////////////1tbWhYWAqam9Kyv3Bgb9AADpAACjEBB+Y2N/
	3Ny8vLyvSEieOjrpODj1V1fwxsbfmprlBAT3ExPgLCy/a2t8iIiI6enp////////////////////
	////////////////+fn5xMTEj4+NoaHMOjrxAAD7DAzeOjqVVFSQlpaJg4OdWVnjnp7jqanjj4/g
	MTHXKyvYKirDY2OJgICO09PT6enp/Pz8////////////////////////////////////////////
	1tbWhYWAoaG4EBDkLS3zxsbfxsbfxsbfxsbfn5/eKSncFRXcLCy/dHR0dHR0iIiI6enp////////
	////////////////////////////////////////////////////+fn5xMTEgoKEWlqRJibOMTHX
	MTHXMTHXMTHXPz+/ZmaIa2uBgICO5OTk5OTk6enp/Pz8////////////////////////////////
	////////////////////////////////////////1tbWfX19dHR0dHR0dHR0dHR0iIiI6enp////
	////////////////////////////////////////////////////////////////////////////
	////////////////+fn55ubm5OTk5OTk5OTk5OTk6enp/Pz8////////////////////////////
	////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////
	) );

	my $bmpPhoneMask = new Win32::GUI::BitmapInline( q(
	Qk2+AAAAAAAAAD4AAAAoAAAAIAAAACAAAAABAAEAAAAAAIAAAAATCwAAEwsAAAIAAAACAAAAAAAA
	AP///wD///////P////A////AD///AAH//AAA//AAAB/AAAAHwAAAAMAAAABAAAAAAAAAAAAAAAA
	AAAAAAAAAACAAAAAwAAAAOAAAADwAAAA+AAAAPAAAAPgAAAD4AAAD+AAAB/gAAB/8AAA//gAB//8
	AD///wH//////////////////w==
	) );

	my $bmpPhoneSmall = new Win32::GUI::BitmapInline( q(
	Qk02AwAAAAAAADYAAAAoAAAAEAAAABAAAAABABgAAAAAAAADAAATCwAAEwsAAAAAAAAAAAAA//v/
	/v3/8fX2+v//4ezq9P//8v//8///6ff29P//9v//7vb2+/7//fz/+vn///7///v//fr/7+//8PL/
	9Pv/8fv/7f3/5/f/7fz/7ff/8/v/8vb/9Pf/+/v/+Pf///7///r/T0hpOjNgVk6DSkV8SEp6NDlm
	R0x5Q0d3QT52S0Z9VE59UU1wamp8+/7//f//6+b7h3yuemuva1ytaV6ud3K3dHWydHWyXFufeXDB
	dGe7dWmxRj9yJyc/+v3//f//+vb/saPjh3TLrZn8iHrYhoHMjo7OiYjKkIzYl4rslIPqrp/7c2mv
	WVp87vL9/f//8vH/pprce2nEiXbdh3ja39v/e3q+0NH/hIHR1Mf/eGjTiHrahn7FUlR29v3/+///
	7vP/9O//in7Kb2K+iH3ZtbH9k5PZsbH3rar5ppv7joHji4PWODZxsLvR8/7/+v//5e738/T/rqnm
	amGxd27E2dT/nJrmzsv/v7v/z8b/e3PKfHi/ZWmZ5vL/8///+v7/8v7/8/f/6en/ranraWOywrv/
	jYTepZ75l5Hqp6L3ammzQEJ87PX/3uz/8f3/+vz/Ki9IMzhZaWmXz83/kY7TxsD/pZ/xxr//zcn/
	zMr/dne7g4W/foO0Rkx1JClI6+r+i4XGrajlKCVdkI/Hp6jgdXawhYXBkZDOamqqY2OjXFudq6nv
	ZmKugHrMR0KHbGiLTD6WenC9Qzx/lZLK0tX/P0NsoKfO7/P/3+T/e3y0YF+jsav8bmPDdGbQTECY
	k422fGrHfm7FU0eTQDp17O7/4Of/5fH/7PX/6vL/2tv/qqbtfXLOcGHKi3nqLR55sazTmI/SfXK7
	q6DpTkaFGhdIU1dzbniKbneLYWWIZmKdXlajkITejIHefnTOS0SH9vX/8fr/sbDalo/MmI3TiX/B
	h4O0R0dvT054Pjtycmi0h33Qg3rKe3i2pq/RzNbn9v7/6fzt8/j/8+7/7eH/7uL/zcX/4Nv/19L/
	7OT/0MP/2Mr/4tv/7/H/3vD38f/79P/8
	) );

	my $bmpPhoneMaskSmall = new Win32::GUI::BitmapInline( q(
	Qk1+AAAAAAAAAD4AAAAoAAAAEAAAABAAAAABAAEAAAAAAEAAAAAjCwAAIwsAAAIAAAACAAAAAAAA
	AP///wD//wAA//8AAIADAACAAwAAgAMAAIADAADAAwAAwAcAAMAPAAAAAQAAAAAAAAAAAAAAAAAA
	AAEAAIABAADgAwAA
	) );

	# Cretae the NORMAL imagelist (large icons)
	my $ilLarge = Win32::GUI::ImageList->new(32, 32, ILC_COLOR|ILC_COLOR24|ILC_MASK, 2, 0);
	$ilLarge->Add($bmpMobile, $bmpMobileMask);
	$ilLarge->Add($bmpPhone, $bmpPhoneMask);

	# Cretae the SMALL imagelist (small icons)
	my $ilSmall= Win32::GUI::ImageList->new(16, 16, ILC_COLOR|ILC_COLOR24|ILC_MASK, 2, 0);
	$ilSmall->Add($bmpMobileSmall, $bmpMobileMaskSmall);
	$ilSmall->Add($bmpPhoneSmall, $bmpPhoneMaskSmall);

	return ($ilLarge, $ilSmall);
}
