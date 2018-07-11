#  Copyright (c) 1990 The Regents of the University of California.
#  Copyright (c) 1994-1997 Sun Microsystems, Inc.
#  See the file "license.terms" for information on usage and redistribution
#  of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
#

=head1 NAME

Tk::HListbox - Tk Listbox widget supporting images and text entries, Tk::HList based drop-in replacement for Tk::Listbox.

=for category  Tk Widget Classes

=head1 SYNOPSIS

I<$listbox> = I<$parent>-E<gt>B<HListbox>(?I<options>?);

=head1 STANDARD OPTIONS

B<-background> B<-borderwidth> B<-cursor> B<-disabledforeground>
B<-exportselection> B<-font> B<-foreground> B<-height>
B<-highlightbackground> B<-highlightcolor> B<-highlightthickness>
B<-offset> B<-relief> B<-selectbackground> B<-selectborderwidth>
B<-selectforeground> B<-setgrid> B<-state> B<-takefocus> B<-tile>
B<-width> B<-xscrollcommand> B<-yscrollcommand>

See L<Tk::options> for details of the standard options.

=head1 WIDGET-SPECIFIC OPTIONS

=over 4

=item Name: B<Entries>

Entries are added to HListbox vertically as rows, one per row (line) 
using either the B<insert> method or inserting into a tied array.
Entries can be either a text string (just like a standard L<Tk::Listbox> 
entry, an image (a L<Tk::Photo> object), or a hashref containing options 
specifying both, along with any other desired L<Tk::HList>-valid options.
Example:  $listbox->insert('end', {-image => $image, -text => 'string'});
Other interesting options include:

=over 4

=item B<-hidden> => 1 | 0 

Specifies whether or not the entry should be visible or hidden (0 (false) 
for visible, 1 (true) for hidden) (default 0 - visible).

=item B<-indicatoritemtype> => 'image'

Specify an "indicator" image

=item B<-indicatorimage => $image

Special image to be displayed next to entry.

=item B<-textanchor> => 'n', 's', 'e', 'w'

Side of text the IMAGE is displayed on.  (Default: 'e' (East))

=item B<-anchor> => 'e', 'w'

Left or Right-justification of entry (Default: 'e')

=item B<-style> => $ImageStyleObject

Use an HList Style object (see Tk::ItemStyle and Tk::DItem)

=item B<-sort>, B<-user> => 'value'

These options not passed to functions, but retained with data, useful for saving info with an entry for one's own use.

For example, one could put text in a I<-sort> option of say, an image-only entry and then retrieve it in a sort function like "sort { $a->{-sort} cmp $b->{-sort} }".

=back

=item Name:	B<browsecmd>

=item Class:	B<BrowseCmd>

=item Switch:	B<-browsecmd>

Specifies a perl/Tk L<callback|Tk::callbacks> to be executed when the user browses through the
entries in the HList widget.

=item Name:	B<command>

=item Class:	B<Command>

=item Switch:	B<-command>

Specifies the perl/Tk L<callback|Tk::callbacks> to be executed when the user invokes a list
entry in the HList widget. Normally the user invokes a list
entry by double-clicking it or pressing the Return key.

=item Name:	B<height>

=item Class:	B<Height>

=item Switch:	B<-height>

Specifies the desired height for the window, in number of characters.
If zero or less, then the desired height for the window is based on 
the default for HList, which seems to be about 7 lines.

=item Name:	B<indicator>

=item Class:	B<Indicator>

=item Switch B<-indicator>

Reserves space for and allows for another image next to the entry, which 
HList calls an "indicator", which, unlike a normal "image" in an entry, 
can be attached to a callback routine (-indicatorcmd) to be invoked when 
the indicator image is clicked with the mouse, rather than the entry 
simply being selected.  By default (if no I<-textanchor> option given, 
the indicator image will appear to the left of the entry.

=item Name:	B<indicatorCmd>

=item Class:	B<IndicatorCmd>

=item Switch B<-indicatorcmd>

Subroutine reference to be invoked when an indicator image is clicked.

=item Name:	B<itemType>

=item Class:	B<ItemType>

=item Switch:	B<-itemtype>

Specifies the default type of display item.  Can be "text", "image", or 
"imagetext".  The default is "text", though "imagetext" allows for either 
or both an image or text.

=item Name:	B<listVariable>

=item Class:	B<Variable>

=item Switch:	B<-listvariable>

Specifies the reference of a variable. The value of the variable is an array 
to be displayed inside the widget; if the variable value changes then the 
widget will automatically update itself to reflect the new value. Attempts 
Attempts to unset a variable in use as a -listvariable may fail without error.

The listvariable reference is "TIEd" to the HListbox widget just as if one 
has done: "tie @listvariable, 'Tk::HListbox', $HListboxwidget, (ReturnType => 'index);" 
immediately after defining $HListboxwidget using the "tie @array" feature. 

=item Name:	B<selectMode>

=item Class:	B<SelectMode>

=item Switch:	B<-selectmode>

Specifies one of several styles for manipulating the selection.
The value of the option may be arbitrary, but the default bindings
expect it to be either B<single>, B<browse>, B<multiple>, 
B<extended> or B<dragdrop>;  the default value is B<browse>.

=item Name:	B<state>

=item Class:	B<State>

=item Switch:	B<-state>

Specifies one of two states for the listbox: B<normal> or B<disabled>.
If the listbox is disabled then items may not be inserted or deleted,
items are drawn in the B<-disabledforeground> color, and selection
cannot be modified and is not shown (though selection information is
retained).

=item Name:	B<width>

=item Class:	B<Width>

=item Switch:	B<-width>

Specifies the desired width for the window in characters.
If the font doesn't have a uniform width then the width of the
character ``0'' is used in translating from character units to
screen units.
If zero or less, then the desired width for the window is made just
large enough to hold all the elements in the listbox.

=back

=head1 LISTBOX OPTIONS AND METHODS NOT (YET?) SUPPORTED BY HLISTBOX

=over 4

=item Name:	B<activeStyle>

Ignored (not implemented in HList).

For the most part, Tk::HListbox can be used as drop-in replacement 
for the Tk::Listbox widget when you need to use images instead of or 
in addition to text values, or need other Tk::HListbox - specific 
features such as hidden or disabled entries, callbacks, etc.

=back

=head1 DESCRIPTION

The B<HListbox> method creates a new window (given by the
$widget argument) and makes it into an HListbox widget.
Additional options, described above, may be specified on 
the command line or in the option database
to configure aspects of the listbox such as its colors, font,
text, and relief.  The B<HListbox> command returns its
$widget argument.  At the time this command is invoked,
there must not exist a window named $widget, but
$widget's parent must exist.

An HListbox is a widget that displays a list of strings, images, or both 
one per line.  When first created, a new HListbox has no elements.
Elements may be added or deleted using methods described
below.  In addition, one or more elements may be selected as described
below.
If an HListbox is exporting its selection (see B<exportSelection>
option), then it will observe the standard X11 protocols
for handling the selection.
HListbox selections are available as type B<STRING>;
the value of the selection will be the "text" of the selected elements, 
returned as an array of zero or more elements.

It is not necessary for all the elements to be
displayed in the HListbox window at once;  commands described below
may be used to change the view in the window.  HListboxes allow
scrolling in both directions using the standard B<xScrollCommand>
and B<yScrollCommand> options.
They also support scanning, as described below.

=head1 INDICES

Many of the methods for HListboxes take one or more indices
as arguments.
An index specifies a particular element of the listbox, in any of
the following ways:

=over 4

=item I<number>

Specifies the element as a numerical index, where 0 corresponds
to the first element in the listbox.

=item B<active>

Indicates the element that has the location cursor.  This element
will be displayed with a dashed-line frame border when the listbox 
has the keyboard focus, and it is specified with the B<activate>
method.  

=item B<anchor>

Indicates the anchor point for the selection, which is set with the
B<selection anchor> method.

=item B<end>

Indicates the end (last element) of the HListbox.
For most commands this refers to the last element in the HListbox,
but for a few commands such as B<index> and B<insert>
it refers to the element just after the last one.

=item B<@>I<x>B<,>I<y>

Indicates the element that covers the point in the HListbox window
specified by I<x> and I<y> (in pixel coordinates).  If no
element covers that point, then the closest element to that
point is used.

=back

In the method descriptions below, arguments named I<index>,
I<first>, and I<last> always contain text indices in one of
the above forms.

=head1 WIDGET METHODS

The B<HListbox> method creates a widget object.
This object supports the B<configure> and B<cget> methods
described in L<Tk::options> which can be used to enquire and
modify the options described above.
The widget also inherits all the methods provided by the generic
L<Tk::Widget|Tk::Widget> class.

The following additional methods are available for HListbox widgets:

=over 4

=item I<$listbox>-E<gt>B<activate>(I<index>)

Sets the active element and the selection anchor 
to the one indicated by I<index>.
If I<index> is outside the range of elements in the listbox
then the closest element is activated.
The active element is drawn similar to a "selected" element 
with a thin hashed border, and its index may be retrieved 
with the index B<active> or B<anchor>.

=item I<$listbox>-E<gt>B<bbox>(I<index>)

Returns a list of four numbers describing the bounding box of
the text in the element given by I<index>.
The first two elements of the list give the x and y coordinates
of the upper-left corner of the screen area covered by the text
(specified in pixels relative to the widget) and the last two
elements give the width and height of the area, in pixels.
If no part of the element given by I<index> is visible on the
screen,
or if I<index> refers to a non-existent element,
then the result is an empty string;  if the element is
partially visible, the result gives the full area of the element,
including any parts that are not visible.

=item I<$listbox>-E<gt>B<curselection>

Returns a list containing the numerical indices of
all of the elements in the HListbox that are currently selected.
If there are no elements selected in the listbox then an empty
list is returned.

=item I<$listbox>-E<gt>B<delete>(I<first, >?I<last>?)

Deletes one or more elements of the HListbox.  I<First> and I<last>
are indices specifying the first and last elements in the range
to delete.  If I<last> isn't specified it defaults to
I<first>, i.e. a single element is deleted.

=item I<$listbox>-E<gt>B<findIndex>(I<string>?)

Given the text of an entry, return the index of the first 
entry whose text matches the string, or I<<undef>> if no matches.

=item I<$listbox>-E<gt>B<get>(I<first, >?I<last>?)

If I<last> is omitted, returns the contents of the listbox
element indicated by I<first>,
or an empty string if I<first> refers to a non-existent element.
If I<last> is specified, the command returns a list whose elements
are all of the listbox elements between I<first> and I<last>,
inclusive.
Both I<first> and I<last> may have any of the standard
forms for indices.

=item I<$listbox>-E<gt>B<getEntry>(I<index>?)

Given an index, returns the HList "entry" value, only useful with 
lower-level HList functions.  Returns I<<undef>> if no matches.

=item I<$listbox>-E<gt>B<hide>([I<-entry> => ] I<index>)

Given an index, sets the entry to "hidden" so that it does not 
display in the listbox (but maintains it's index.  The "-entry" 
argument is unnecessary, but retained for Tk::HList compatability.

=item I<$listbox>-E<gt>B<show>([I<-entry> => ] I<index>)

Given an index, sets the entry to "not hidden" (the default) so 
that it is displayed in the listbox.

=item I<$listbox>-E<gt>B<index>(I<index>)

Returns the integer index value that corresponds to I<index>.
If I<index> is B<end> the return value is a count of the number
of elements in the listbox (not the index of the last element).

=item I<$listbox>-E<gt>B<insert>(I<index, >?I<element, element, ...>?)

Inserts zero or more new elements in the list just before the
element given by I<index>.  If I<index> is specified as
B<end> then the new elements are added to the end of the
list.  Returns an empty string.  If the I<index> is not "end", 
the list will be automatically inserted in reverse order so that 
the entire list is inserted in the proper order before the 
element currently identified by the I<index>.

=item I<$listbox>-E<gt>B<itemcget>(I<index>, I<option>)

Returns the current value of the item configuration option given by
I<option>. Option may have any of the values accepted by the listbox
B<itemconfigure> command or by HList, including ItemStyles.

=item I<$listbox>-E<gt>B<itemconfigure>(I<index, >?I<option, value,
option, value, ...>?)

Query or modify the configuration options of an item in the HListbox.
If no option is specified, returns a list describing all of the
available options for the item (see Tk_ConfigureInfo for information
on the format of this list). If option is specified with no value,
then the command returns a list describing the one named option (this
list will be identical to the corresponding sublist of the value
returned if no option is specified). If one or more option-value pairs
are specified, then the command modifies the given widget option(s) to
have the given value(s); in this case the command returns an empty
string. The following options are currently supported for items:

=item I<$listbox>-E<gt>B<ItemStyle>(I<itemtype, >?I<option, value, option, value, ...>?)

HList method to create a display style for the I<-style> entry option.
NOTE:  It's better to change most display properties by listing them 
and their values when inserting entries since any HListbox-wide style 
options specified when creating the HListbox widget, ie. I<-foreground>, 
etc. are NOT copied over into the style object.

=over

=item B<-background> =E<gt> I<color>

I<Color> specifies the background color to use when displaying the
item. It may have any of the forms accepted by Tk_GetColor.

=item B<-foreground> =E<gt> I<color>

I<Color> specifies the foreground color to use when displaying the
item. It may have any of the forms accepted by Tk_GetColor.  NOTE: 
may be returned as "-fg".

=item B<-selectbackground> =E<gt> I<color>

I<Color> specifies the background color to use when displaying the
item while it is selected. It may have any of the forms accepted by
Tk_GetColor.

=item B<-selectforeground> =E<gt> I<color>

I<Color> specifies the foreground color to use when displaying the
item while it is selected. It may have any of the forms accepted by
Tk_GetColor.

=back

=item I<$listbox>-E<gt>B<nearest>(I<y>)

Given a y-coordinate within the listbox window, this command returns
the index of the (visible) listbox element nearest to that y-coordinate.

=item I<$listbox>-E<gt>B<scan>(I<option, args>)

This command is used to implement scanning on listboxes.  It has
two forms, depending on I<option>:

=over 8

=item I<$listbox>-E<gt>B<scanMark>(I<x, y>)

Records I<x> and I<y> and the current view in the listbox
window;  used in conjunction with later B<scan dragto> commands.
Typically this command is associated with a mouse button press in
the widget.  It returns an empty string.

=item I<$listbox>-E<gt>B<scanDragto>(I<x, y>.)

This command computes the difference between its I<x> and I<y>
arguments and the I<x> and I<y> arguments to the last
B<scan mark> command for the widget.
It then adjusts the view by 10 times the
difference in coordinates.  This command is typically associated
with mouse motion events in the widget, to produce the effect of
dragging the list at high speed through the window.  The return
value is an empty string.

=back

=item I<$listbox>-E<gt>B<see>(I<index>)

Adjust the view in the HListbox so that the element given by I<index>
is visible.
If the element is already visible then the command has no effect;
if the element is near one edge of the window then the listbox
scrolls to bring the element into view at the edge;  otherwise
the listbox scrolls to center the element.

=item I<$listbox>-E<gt>B<selection>(I<option, arg>)

This command is used to adjust the selection within a listbox.  It
has several forms, depending on I<option>:

=over 8

=item I<$listbox>-E<gt>B<selectionAnchor>(I<index>)

Sets the selection anchor to the element given by I<index>.
If I<index> refers to a non-existent element, then the closest
element is used.
The selection anchor is the end of the selection that is fixed
while dragging out a selection with the mouse.
The index B<anchor> may be used to refer to the anchor
element.

=item I<$listbox>-E<gt>B<selectionClear>(I<first, >?I<last>?)

If any of the elements between I<first> and I<last>
(inclusive) are selected, they are deselected.
The selection state is not changed for elements outside
this range.

=item I<$listbox>-E<gt>B<selectionIncludes>(I<index>)

Returns 1 if the element indicated by I<index> is currently
selected, 0 if it isn't.

=item I<$listbox>-E<gt>B<selectionSet>(I<first, >?I<last>?)

Selects all of the elements in the range between
I<first> and I<last>, inclusive, without affecting
the selection state of elements outside that range.

=back

=item I<$listbox>-E<gt>B<size>

Returns a decimal string indicating the total number of elements
in the listbox.

=item I<$listbox>-E<gt>B<xview>(I<args>)

This command is used to query and change the horizontal position of the
information in the widget's window.  It can take any of the following
forms:

=over 8

=item I<$listbox>-E<gt>B<xview>

Returns a list containing two elements.
Each element is a real fraction between 0 and 1;  together they describe
the horizontal span that is visible in the window.
For example, if the first element is .2 and the second element is .6,
20% of the listbox's text is off-screen to the left, the middle 40% is visible
in the window, and 40% of the text is off-screen to the right.
These are the same values passed to scrollbars via the B<-xscrollcommand>
option.

=item I<$listbox>-E<gt>B<xview>(I<index>)

Adjusts the view in the window so that the character position given by
I<index> is displayed at the left edge of the window.
Character positions are defined by the width of the character B<0>.

=item I<$listbox>-E<gt>B<xviewMoveto>( I<fraction> );

Adjusts the view in the window so that I<fraction> of the
total width of the listbox text is off-screen to the left.
I<fraction> must be a fraction between 0 and 1.

=item I<$listbox>-E<gt>B<xviewScroll>( I<number, what> );

This command shifts the view in the window left or right according to
I<number> and I<what>.
I<Number> must be an integer.
I<What> must be either B<units> or B<pages> or an abbreviation
of one of these.
If I<what> is B<units>, the view adjusts left or right by
I<number> character units (the width of the B<0> character)
on the display;  if it is B<pages> then the view adjusts by
I<number> screenfuls.
If I<number> is negative then characters farther to the left
become visible;  if it is positive then characters farther to the right
become visible.

=back

=item I<$listbox>-E<gt>B<yview>(I<?args>?)

This command is used to query and change the vertical position of the
text in the widget's window.
It can take any of the following forms:

=over 8

=item I<$listbox>-E<gt>B<yview>

Returns a list containing two elements, both of which are real fractions
between 0 and 1.
The first element gives the position of the listbox element at the
top of the window, relative to the listbox as a whole (0.5 means
it is halfway through the listbox, for example).
The second element gives the position of the listbox element just after
the last one in the window, relative to the listbox as a whole.
These are the same values passed to scrollbars via the B<-yscrollcommand>
option.

=item I<$listbox>-E<gt>B<yview>(I<index>)

Adjusts the view in the window so that the element given by
I<index> is displayed at the top of the window.

=item I<$listbox>-E<gt>B<yviewMoveto>( I<fraction> );

Adjusts the view in the window so that the element given by I<fraction>
appears at the top of the window.
I<Fraction> is a fraction between 0 and 1;  0 indicates the first
element in the listbox, 0.33 indicates the element one-third the
way through the listbox, and so on.

=item I<$listbox>-E<gt>B<yviewScroll>( I<number, what> );

This command adjusts the view in the window up or down according to
I<number> and I<what>.
I<Number> must be an integer.
I<What> must be either B<units> or B<pages>.
If I<what> is B<units>, the view adjusts up or down by
I<number> lines;  if it is B<pages> then
the view adjusts by I<number> screenfuls.
If I<number> is negative then earlier elements
become visible;  if it is positive then later elements
become visible.

=back

=back

=head1 EXAMPLES

#!/usr/bin/perl

	use Tk;
	use Tk::HListbox;

	my ( @array, $scalar, $other );
	my %options = ( ReturnType => "index" );

	my $MW = MainWindow->new();
	my $licon=$MW->Photo(-file => '/usr/share/pixmaps/smallicons/Penguin.xpm');  #ICON IMAGE
	my $wicon=$MW->Photo(-file => '/usr/share/pixmaps/smallicons/tiny_windowsxp.xpm');  #ICON IMAGE
	my $lbox = $MW->Scrolled('HListbox',
			-scrollbars => 'se', 
			-selectmode => 'extended',
			-itemtype => 'imagetext',
			-indicator => 1,
			-indicatorcmd => sub {
				print STDERR "---indicator clicked---(".join('|',@_).")\n";
			},
			-browsecmd => sub { 
				print STDERR "---browsecmd!---(".join('|',@_).")\n";
			},
	)->pack(-fill => 'y', -expand => 1);

	$MW->Button(   #MAIN WINDOW BUTTON TO QUIT.
			-text => 'Bonus Tests', 
			-underline => 0,
			-command => sub
	{
	#FETCH AND PRINT OUT THE SELECTED ITEMS:
		my @v = $lbox->curselection;
		print "--SELECTED=".join('|', @v)."= vcnt=$#v= MODE=".$lbox->cget('-selectmode')."=\n";
		for (my $i=0;$i<=$#v;$i++)
		{
			print "--selected($i)=".$lbox->get($v[$i])."=\n";
		}
	#PRINT WHETHER THE LAST ITEM IS CURRENTLY SELECTED (2 WAYS):
		print "--select includes last one =".$lbox->selectionIncludes('end')."=\n";
		print "--select includes last one =".$lbox->selection('includes','end')."=\n";
	#FETCH THE OLD ANCHOR AND SET THE ANCHOR TO THE 2ND ITEM:
		my $anchorWas = $lbox->index('anchor');
		$lbox->selectionAnchor(8);
		my $anchorNow = $lbox->index('anchor');
	#DELETE THE 4TH ITEM & ****TURN OFF INDICATORS!**** TO SHOW NORMAL VIEW:
		$lbox->delete(4);
		$lbox->configure(-indicator => 0);
	#SET THE VIEWPORT TO SHOW THE FIRST SELECTED ITEM:
		$lbox->yview($v[0]);
	#PRINT THE DATA RETURNED BY yview() AND THE LAST ITEM;
		my @yview = $lbox->yview;
		my $last = $lbox->index('end');
		print "--YVIEW=".join('|',@yview)."= last=$last=\n";
	#FETCH THE INDEX OF THE LAST ITEM:
		#FETCH AND DISPLAY SOME ATTRIBUTES:
		print "--anchor was=$anchorWas= now=$anchorNow= yview=".join('|',@yview)."=\n";
		print "-reqheight=".$lbox->reqheight."= height=".$lbox->cget('-height')."= size=".$lbox->size."=\n";
	#PRINT OUT THE VALUES OF THE TIED VARIABLES:
		print "-scalar=".join('|',@{$scalar})."= array=".join('|',@array)."= other=".join('|',@{$other})."=\n";
	#RECONFIGURE 2ND ITEM TO FOREGROUND:=GREEN:
		$lbox->itemconfigure(1,'-fg', 'green');
	#FETCH THE HList STYLE OBJECT FOR 2ND ITEM:
		print "-itemcget(1)=".$lbox->itemcget(1, '-style')."=\n";
	#FETCH JUST THE Listbox FOREGROUND COLOR FOR 2ND ITEM:
		print "-itemcget(2)=".$lbox->itemcget(1, '-fg')."=\n";
	#FETCH THE "NEAREST" INDEX TO THE 2ND ITEM:
		print "-nearest(1)=".$lbox->nearest(1)."=\n";
	#ADD AN ELEMENT VIA THE TIED ARRAY:
		push @array, {-image => $licon, -text => 'ArrayAdd!'};
	#DELETE THE LAST ITEM USING THE TIED ARRAY:
		pop @array;
	#FIND AND DISPLAY THE INDEX OF THE TEXT ENTRY "Y":
		print "-Index of 'Y' =".$lbox->findIndex('Y')."=\n";
	}
	)->pack(
			-side => 'bottom'
	);
	$MW->Button(   #MAIN WINDOW BUTTON TO QUIT.
			-text => 'Quit', 
			-underline => 0,
			-command => sub { print "ok 5\n..done: 5 tests completed.\n"; exit(0) }
	)->pack(
			-side => 'bottom'
	);

	#ADD SOME ITEMS (IMAGE+TEXT) TO OUR LISTBOX THE TRADITIONAL WAY:
		my @list = ( 
			{-image => $licon, -text => 'a' },
			{-image => $wicon, -text => 'bbbbbbbbbbbbbbbbbbbB', -foreground => '#0000FF' },
			{-text => 'c', -image => $licon },
			{-text => 'd:image & indicator!', -image => $licon, -indicatoritemtype, 'image', -indicatorimage => $wicon },
			{-image => $licon, -text => 'e' },
			{-image => $licon, -text => 'f:Switch sides!', -textanchor => 'w' },
			{-image => $licon, -text => 'z:Next is Image Only!' },
			$licon
		);
		$lbox->insert('end', @list );
		@list = ();
	#ADD A BUNCH MORE JUST BEFORE THE 7TH ITEM ("
		foreach my $i ('G'..'Y')
		{
			push @list, {-image => $licon, -text => $i};
		}
		$lbox->insert(6, @list );

	#FETCH THE 2ND ITEM AND DISPLAY IT'S TEXT:
		$_ = $lbox->get(1);
		if (ref $_) {
			print "-2nd value=$_= TEXT=".$_->{'-text'}."=\n";
		} else {
			print "-2nd value=$_=\n";
		}
	#SET THE 3RD AND 5TH ITEMS AS INITIALLY-SELECTED:
		$lbox->selectionSet(2,4);
	#AND ONE WITH AN "INDICATOR IMAGE" JUST BEFORE THE 4TH ITEM:
		$lbox->insert(3, 'TextOnly at 3', 
				{'-text' => '<Click Indicator Icon', '-indicatoritemtype', 'image', '-indicatorimage' => $wicon});
	#DISPLAY A LIST OF ALL THE CURRENT ITEMS IN THE LISTBOX:
		print "--current choices=".join('|',$lbox->get(0, 'end'))."=\n";

	#TIE SOME VARIABLES TO THE LISTBOX:
		tie @array, "Tk::HListbox", $lbox;
		tie $scalar, "Tk::HListbox", $lbox;
		tie $other, "Tk::HListbox", $lbox, %options;

		MainLoop;

__END__

=head1 DEFAULT BINDINGS

Tk automatically creates class bindings for listboxes that give them
Motif-like behavior.  Much of the behavior of a listbox is determined
by its B<selectMode> option, which selects one of four ways
of dealing with the selection.

If the selection mode is B<single> or B<browse>, at most one
element can be selected in the listbox at once.
In both modes, clicking button 1 on an element selects
it and deselects any other selected item.
In B<browse> mode it is also possible to drag the selection
with button 1.

If the selection mode is B<multiple> or B<extended>,
any number of elements may be selected at once, including discontiguous
ranges.  In B<multiple> mode, clicking button 1 on an element
toggles its selection state without affecting any other elements.
In B<extended> mode, pressing button 1 on an element selects
it, deselects everything else, and sets the anchor to the element
under the mouse;  dragging the mouse with button 1
down extends the selection to include all the elements between
the anchor and the element under the mouse, inclusive.

Most people will probably want to use B<browse> mode for
single selections and B<extended> mode for multiple selections;
the other modes appear to be useful only in special situations.

Any time the selection changes in the listbox, the virtual event
B<<< <<ListboxSelect>> >>> will be generated. It is easiest to bind to this
event to be made aware of any changes to listbox selection.


In addition to the above behavior, the following additional behavior
is defined by the default bindings:

=over 4

=item [1]

In B<extended> mode, the selected range can be adjusted by pressing
button 1 with the Shift key down:  this modifies the selection to
consist of the elements between the anchor and the element under
the mouse, inclusive.
The un-anchored end of this new selection can also be dragged with
the button down.

=item [2]

In B<extended> mode, pressing button 1 with the Control key down
starts a toggle operation: the anchor is set to the element under
the mouse, and its selection state is reversed.  The selection state
of other elements isn't changed.
If the mouse is dragged with button 1 down, then the selection state
of all elements between the anchor and the element under the mouse
is set to match that of the anchor element;  the selection state of
all other elements remains what it was before the toggle operation
began.

=item [3]

If the mouse leaves the HListbox window with button 1 down, the window
scrolls away from the mouse, making information visible that used
to be off-screen on the side of the mouse.
The scrolling continues until the mouse re-enters the window, the
button is released, or the end of the listbox is reached.

=item [4]

Mouse button 2 may be used for scanning.
If it is pressed and dragged over the listbox, the contents of
the listbox drag at high speed in the direction the mouse moves.

=item [5]

If the Up or Down key is pressed, the location cursor (active
element) moves up or down one element.
If the selection mode is B<browse> or B<extended> then the
new active element is also selected and all other elements are
deselected.
In B<extended> mode the new active element becomes the
selection anchor.

=item [6]

In B<extended> mode, Shift-Up and Shift-Down move the location
cursor (active element) up or down one element and also extend
the selection to that element in a fashion similar to dragging
with mouse button 1.

=item [7]

The Left and Right keys scroll the listbox view left and right
by the width of the character B<0>.

Control-Left and Control-Right scroll the listbox view left and
right by the width of the window.

=item [8]

The Prior and Next keys scroll the listbox view up and down
by one page (the height of the window).

Control-Prior and Control-Next scroll the listbox view up 
and down by one page while selecting a page's worth of items.

=item [9]

The Home and End keys scroll the listbox horizontally to
the left and right edges, respectively.

=item [10]

Control-Home sets the location cursor to the the first element in
the listbox, selects that element, and deselects everything else
in the listbox.

=item [11]

Control-End sets the location cursor to the the last element in
the listbox, selects that element, and deselects everything else
in the listbox.

=item [12]

In B<extended> mode, Control-Shift-Home extends the selection
to the first element in the listbox and Control-Shift-End extends
the selection to the last element.

=item [13]

In B<multiple> mode, Control-Shift-Home moves the location cursor
to the first element in the listbox and Control-Shift-End moves
the location cursor to the last element.

=item [14]

The space and Select keys toggle a selection at the location cursor
(active element) just as if mouse button 1 had been pressed over
this element.

=item [15]

In B<extended> mode, Control-Shift-space and Shift-Select
extend the selection to the active element just as if button 1
had been pressed with the Shift key down.

=item [16]

In B<extended> mode, the Escape key cancels the most recent
selection and restores all the elements in the selected range
to their previous selection state.  NOTE:  This may not be 
fully working correctly.

=item [17]

Control-slash selects everything in the widget, except in
B<single> and B<browse> modes, in which case it selects
the active element and deselects everything else.

=item [18]

Control-backslash deselects everything in the widget, except in
B<browse> mode where it has no effect.

=item [19]

The F16 key (labelled Copy on many Sun workstations) or Meta-w
copies the selection in the widget to the clipboard, if there is
a selection.

=item [20]

We've added <Ctrl-<Prior>> and <Ctrl-<Next>> bindings 
to scroll the listbox view up and down by one page while 
selecting a page's worth of items.

=back

The behavior of HListboxes can be changed by defining new bindings for
individual widgets or by redefining the class bindings.

=head1 TIED INTERFACE

The Tk::HListbox widget can also be tied to a scalar or array variable, with
different behaviour depending on the variable type, with the following
tie commands:

   use Tk;

   my ( @array, $scalar, $other );
   my %options = ( ReturnType => "index" );

   my $MW = MainWindow->new();
   my $lbox = $MW->HListbox()->pack();

   my @list = ( "a", "b", "c", "d", "e", "f" );
   $lbox->insert('end', @list );

   tie @array, "Tk::HListbox", $lbox
   tie $scalar, "Tk::HListbox", $lbox;
   tie $other, "Tk::HListbox", $lbox, %options;

currently only one modifier is implemented, a 3 way flag for tied scalars
"ReturnType" which can have values "element", "index" or "both". The default
is "element".

=over 4

=item Tied Arrays

If you tie an array to the HListbox you can manipulate the items currently
contained by the box in the same manner as a normal array, e.g.

    print @array;
    push(@array, @list);
    my $popped = pop(@array);
    my $shifted = shift(@array);
    unshift(@array, @list);
    delete $array[$index];
    print $string if exists $array[$i];
    @array = ();
    splice @array, $offset, $length, @list

The delete function is implemented slightly differently from the standard
array implementation. Instead of setting the element at that index to undef
it instead physically removes it from the HListbox. This has the effect of
changing the array indices, so for instance if you had a list on non-continuous
indices you wish to remove from the HListbox you should reverse sort the list
and then apply the delete function, e.g.

     my @list = ( 1, 2, 4, 12, 20 );
     my @remove = reverse sort { $a <=> $b } @list;
     delete @array[@remove];

would safely remove indices 20, 12, 4, 2 and 1 from the HListbox without
problems. It should also be noted that a similar warning applies to the
splice function (which would normally be used in this context to perform
the same job).


=item Tied Scalars

Unlike tied arrays, if you tie a scalar to the HListbox you can retrieve the
currently selected elements in the box as an array referenced by the scalar,
for instance

    my @list = ( "a", "b", "c", "d", "e", "f" );
    $lbox->insert('end', sort @list );
    $lbox->selectionSet(1);

inserts @list as elements in an already existing listbox and selects the
element at index 1, which is "b". If we then

     print @$selected;

this will return the currently selected elements, in this case "b".

However, if the "ReturnType" argument is passed when tying the HListbox to the
scalar with value "index" then the indices of the selected elements will be
returned instead of the elements themselves, ie in this case "1". This can be
useful when manipulating both contents and selected elements in the HListbox at
the same time.

Importantly, if a value "both" is given the scalar will not be tied to an
array, but instead to a hash, with keys being the indices and values being
the elements at those indices

You can also manipulate the selected items using the scalar. Equating the
scalar to an array reference will select any elements that match elements
in the HListbox, non-matching array items are ignored, e.g.

    my @list = ( "a", "b", "c", "d", "e", "f" );
    $lbox->insert('end', sort @list );
    $lbox->selectionSet(1);

would insert the array @list into an already existing HListbox and select
element at index 1, i.e. "b"

    @array = ( "a", "b", "f" );
    $selected = \@array;

would select elements "a", "b" and "f" in the HListbox.

Again, if the "index" we indicate we want to use indices in the options hash
then the indices are use instead of elements, e.g.

    @array = ( 0, 1, 5 );
    $selected = \@array;

would have the same effect, selecting elements "a", "b" and "f" if the
$selected variable was tied with %options = ( ReturnType => "index" ).

If we are returning "both", i.e. the tied scalar points to a hash, both key and
value must match, e.g.

    %hash = ( 0 => "a", 1 => "b", 5 => "f" );
    $selected = \%hash;

would have the same effect as the previous examples.

It should be noted that, despite being a reference to an array (or possibly a hash), you still can not copy the tied variable without it being untied, instead
you must pass a reference to the tied scalar between subroutines.

=back

=head1 AUTHOR

Jim Turner, C<< <https://metacpan.org/author/TURNERJW> >>.

=head1 COPYRIGHT

Copyright (c) 2015-2018 Jim Turner C<< <mailto://turnerjw784@yahoo.com> >>.
All rights reserved.  

This program is free software; you can redistribute 
it and/or modify it under the same terms as Perl itself.

This is a derived work from Tk::Listbox and Tk::HList.

=head1 KEYWORDS

hlistbox, listbox, hlist

=head1 SEE ALSO

L<Tk::HList>, L<Tk::Listbox>, L<Tk::ItemStyle>, L<Tk::DItem>.

=cut

##### NOTE:  DO AN "export jwtlistboxhack=1" (env. variable) TO GET MY (MUCH BETTER) KEYBOARD FUNCTION BINDING!

package Tk::HListbox;
use Tk;
use Tk::ItemStyle;
use base qw(Tk::Derived Tk::HList);
use vars qw($VERSION @Selection $Prev $tixIndicatorArmed);
$VERSION = '2.0';

Tk::Widget->Construct('HListbox');

sub ClassInit
{
	my ($class,$mw) = @_;

	$class->SUPER::ClassInit($mw);
 # Standard Motif bindings:
 $mw->bind($class,'<1>',[sub {
		my $w = shift;
		if (Tk::Exists($w)) {
			$tixIndicatorArmed = -1;
			$w->BeginSelect(@_);
		}
 }, Ev('index',Ev('@'))]);
# $mw->bind($class, '<Double-1>' => \&Tk::NoOp);
 $mw->bind($class,'<Double-1>' => ['DoubleButton1',Ev('index',Ev('@'))]);
 $mw->bind($class,'<B1-Motion>',['Motion',Ev('index',Ev('@'))]);
# $mw->bind($class,'<B1-Motion>',['Button1Motion']);
 $mw->bind($class,'<ButtonRelease-1>','ButtonRelease_1');
 $mw->bind($class,'<Shift-1>',['BeginExtend',Ev('index',Ev('@'))]);  #JWT:ADDED 20091020!
 $mw->bind($class,'<Control-1>',['BeginToggle',Ev('index',Ev('@'))]);
 $mw->bind($class,'<B1-Leave>',['AutoScan',Ev('x'),Ev('y')]);
 $mw->bind($class,'<B1-Enter>','CancelRepeat');
 $mw->bind($class,'<Up>',['UpDown',-1]);
 $mw->bind($class,'<Shift-Up>',['ShiftUpDown',-1]);
 $mw->bind($class,'<Down>',['UpDown',1]);
 $mw->bind($class,'<Shift-Down>',['ShiftUpDown',1]);
 $mw->XscrollBind($class);
 $mw->bind($class,'<Prior>', sub {
		my $w = shift;
		$w->yview('scroll',-1,'pages');
		$w->activate('@0,0');
 });
 $mw->bind($class,'<Next>',  sub {
		my $w = shift;
		$w->yview('scroll',1,'pages');
		$w->activate('@0,0');
 });
#x	$mw->bind($class, '<Control-Prior>', ['Tk::HList::xview','scroll',-1, 'pages']);  #JWT:DIFFERENT FROM Listbox!:
#x	$mw->bind($class, '<Control-Next>', ['Tk::HList::xview','scroll',1, 'pages']);
	$mw->bind($class, '<Control-Prior>', ['CtrlPriorNext',-1]);  #JWT:DIFFERENT FROM Listbox!:
	$mw->bind($class, '<Control-Next>', ['CtrlPriorNext',1]);
 # <Home> and <End> defined in XscrollBind
#	$mw->bind($class, '<Home>',  ['Tk::HList::xview','moveto',0]);
#	$mw->bind($class, '<End>',   ['Tk::HList::xview','moveto',1]);
	$mw->bind($class, '<Control-Home>','Cntrl_Home');
 $mw->bind($class,'<Shift-Control-Home>',['DataExtend',0]);
	$mw->bind($class, '<Control-End>','Cntrl_End');
 $mw->bind($class,'<Shift-Control-End>',['DataExtend','end']);
 $mw->bind($class,'<space>',['SpaceSelect',Ev('index','active')]);
 $mw->bind($class,'<Select>',['BeginSelect',Ev('index','active')]);

 $mw->bind($class,'<Shift-space>',['ShiftSpace',Ev('index','active')]);  #JWT:ADDED 20091020!
 $mw->bind($class,'<Shift-Select>',['BeginExtend',Ev('index','active')]);  #JWT:ADDED 20091020!
	$mw->bind($class, '<Escape>', 'Cancel');
	$mw->bind($class, '<Control-slash>','SelectAll');
	$mw->bind($class, '<Control-backslash>','Cntrl_backslash');
 # Additional Tk bindings that aren't part of the Motif look and feel:
 $mw->bind($class,'<2>',['scan','mark',Ev('x'),Ev('y')]);
 $mw->bind($class,'<B2-Motion>',['scan','dragto',Ev('x'),Ev('y')]);
 $mw->bind($class,'<Return>', ['InvokeCommand']);
#x	$mw->bind($class, '<Prior>',  ['Tk::HList::yview','scroll',-1,'pages']);
#x	$mw->bind($class, '<Next>',   ['Tk::HList::yview','scroll',1,'pages']);
#	$mw->bind($class, '<Left>', ['Tk::HList::xview','scroll',-1, 'pages']);
#	$mw->bind($class, '<Right>', ['Tk::HList::xview','scroll',1, 'pages']);
	$mw->MouseWheelBind($class); # XXX Both needed?
	$mw->YMouseWheelBind($class);

	return $class; 
}

sub Populate {
	my ($w, $args) = @_;

	$w->SUPER::Populate($args);
	$w->ConfigSpecs(
			-background    => [qw/SELF background Background/, $Tk::NORMAL_BG],
			-foreground    => [qw/SELF foreground Foreground/, $Tk::NORMAL_FG],
			-updatecommand => ['CALLBACK'],
			-xscancommand  => ['CALLBACK'],
			-parent        => [qw/SELF parent parent/, undef],
#			-itemtype       => [qw/PASSIVE itemtype Itemtype text/],
			-itemtype       => [qw/PASSIVE itemType ItemType text/],
			-indicatorcmd  =>  ['CALLBACK'],
			-activestyle   => [qw/PASSIVE activeStyle ActiveStyle underline/],  #CURRENTLY IGNORED.
			-listvariable  => [qw/PASSIVE listVariable Variable undef/],
	);

	#EMULATE "-listvariable" USING THE TIE FEATURE:
	if (defined($args->{-listvariable}) && ref($args->{-listvariable})) {
		tie @{$args->{-listvariable}}, 'Tk::HListbox', $w, (ReturnType => 'index');
	}
}

sub selection {
	my $w = shift;
	my $opt = shift;
	if (defined $_[0]) {
		my $entry = $w->getEntry(shift);
		eval "return \$w->Tk::HList::selection\u\L$opt($entry, '".join("','", @_)."')";
	} else {	
		eval "return \$w->Tk::HList::selection\u\L$opt('".join("','", @_)."')";
	}
}
	
sub selectionSet {   #THIS SHOULD TAKE HList "ENTRIES":
	my ($w) = shift;

	return  unless (defined($_[0]) && $_[0] =~ /\S/o);
	my @args = @_;
	for (my $i=0;$i<=$#args;$i++) {
		$args[$i] = $w->index($args[$i])  if ($args[$i] =~ /\D/o);
	}
	my @indexRange = (@args);
	@indexRange = ($args[1] < $args[0]) ? reverse($args[1]..$args[0]) : ($args[0]..$args[1])  if (defined($args[1]) && !defined($args[2]));
	my @range;
	my $ent;
	#THE STUPID HList IS BROKEN - IT WILL SELECT ENTRIES THAT ARE DISABLED, SO WE HAVE TO FILTER 'EM OUT OURSELVES FIRST!: :(
	for (my $i=0;$i<=$#indexRange;$i++) {
		$ent = $w->getEntry($indexRange[$i]);
		$indexRange[$i] = $w->index($indexRange[$i])  if ($indexRange[$i] =~ /\D/o);
		push (@range, $ent)  unless ($w->entrycget($ent, '-state') eq 'disabled' || $w->info('hidden', $ent));
	}
	if ($range[0] =~ /\S/o) {
#		$w->Tk::HList::anchorSet($range[0])  if (scalar(@_) == 1);
		if ($#range < 2) {
			$w->Tk::HList::selectionSet(@range);
		} else {
			foreach my $i (@range) {
				$w->Tk::HList::selectionSet($i);
			}
		}
	}
}

sub selectionClear {
	my ($w) = shift;

	my $active = $w->index('active');
	my @range = $w->getEntryList(@_);

	$w->Tk::HList::selectionClear(@range);
	$w->activate($active);
}

sub anchorSet {  #HList's "anchor" is it's (active) cursor, so we use a "virtual anchor" for ours.
	return  unless (defined($_[1]) && $_[1] =~ /\S/o);

	my $ent = $_[0]->getEntry($_[1]);
	$_[0]->{'_vanchor'} = (!defined($ent) || $_[0]->entrycget($ent, '-state') eq 'disabled' || $_[0]->info('hidden', $ent))
			? undef : $_[0]->index($_[1]);
}

sub anchorClear {
	$_[0]->{'_vanchor'} = undef;
}

sub selectionAnchor {  #SET THE SELECTION ANCHOR (Listbox's version of HList's "anchorSet" function:
	$_[0]->anchorSet($_[1]);
}
sub activate {    #HListbox "anchor" == Listbox "active"!
	my ($w) = shift;
	my @v = @_;
	my $ent = $w->getEntry($v[0]);
	$w->Tk::HList::anchorSet($ent)
			unless ($w->entrycget($ent, '-state') eq 'disabled' || $w->info('hidden', $ent));
}

sub curselection { 
	my $v = $_[0]->info('selection');
	unless (defined $v) {
		return wantarray ? () : undef;
	}
	my $vcnt = 0;
	for (my $i=0;$i<=$#{$v};$i++) {
		$v->[$i] = $_[0]->indexOf($v->[$i]);
	}
	return wantarray ? @{$v} : $v
}

sub see {
	$_[0]->Tk::HList::see($_[0]->getEntry($_[1]));
}

sub yview {
	my $w = shift;

	if (!defined $_[0]) {
		my @v = $w->Tk::HList::yview;
		push (@v, 1)  unless (defined $v[1]);  #JWT:FOR SOME REASON, HList.yview() DOES NOT SEEM TO WORK AS DOC'ED?!
		return @v;
	} elsif (scalar(@_) == 1) {
		return $w->Tk::HList::yview($w->getEntry($_[0]));
	} elsif (defined($_[1]) && $_[1]) {
		$w->Tk::HList::yview(@_);
	}
}

{
	my ($x0, $y0);
	sub scan {    #JWT:UNDERLYING HList DOES NOT SEEM TO SUPPORT SCANNING AT THIS TIME, SO I HACKED MINE OWN!:
		my $w = shift;

		eval { my @r = $w->SUPER::scan(@_); };
		return @r  unless ($@);
		if ($_[0] =~ /^mark/o) {
			$x0 = $_[1];
			$y0 = $_[2];
		} else {
			$w->xview('scroll', ($_[1] <=> $x0), 'units');
			$w->yview('scroll', ($_[2] <=> $y0), 'units');
		}
	}
}

sub SpaceSelect   #JWT:THIS WORKS SLIGHTLY DIFFERENT THAN NORMAL LISTBOX B/C THE ONLY WAY IN AN HList TO SHOW THE CURSOR ON AN ITEM IS TO "SELECT" IT.
{
	my $w = shift;

	$w->BeginSelect(@_);
	$w->Callback(-indicatorcmd => $_[0])  if ($w->cget('-indicator') && $w->indicator('exists', $w->getEntry($_[0])));
	$w->activate($_[0]);
	if ($w->cget('-selectmode') =~ /^(?:multiple|extended)/o) {
		$w->Callback(-browsecmd);
	} else {
		$w->Callback(-browsecmd => $_[0]);
	}
}

sub size {
	my @children = $_[0]->info('children');
	return scalar(@children);
}

sub get {
	my ($w, @indx) = @_;
	if (defined $indx[1]) {
		my @colData = ();
		my $first = $w->getEntry($indx[0]);
		my $last = defined($indx[1]) ? $w->getEntry($indx[1]) : $first;
		$last = 999999  if ($last =~ /^end/io);
		my $next = $first;
		while ($w->info('exists', $next)) {
			push @colData, $w->info('data', $next);
			$next = $w->info('next', $next);
		}
		return @colData;
	} else {
		return $w->info('data', $w->getEntry($indx[0]));
	}
}

sub insert {     #INSERT ONE OR MORE ITEMS TO THE LIST:
	my ($c, $index, @data) = @_;

	# The listbox might get resized after insert/delete, which is a 
	# behaviour we don't like....
	my $itemType = $c->cget('-itemtype');
	my $entryID;
	my @atIndexArgs = ();
	unless ($index =~ /^end/io) {
		@atIndexArgs = ('-at', $c->index($index));
		@data = reverse @data;     #WE HAVE TO REVERSE THE LIST BEING ADDED IF THE INDEX IS NOT "end"!
	}
	my (@addArgs, @childData, $extraOpsHash, @dataParts, @indicatorOps, %styleOps, $haveStyle, $hideit);
	for (my $i=0;$i<=$#data;$i++) {
		@addArgs = ();
		@childData = ();
		$extraOpsHash = {};
		
		@indicatorOps = ();
		%styleOps = ();
		$haveStyle = 0;
		$hideit = 0;
		if (defined($data[$i]) && $data[$i] ne '') {
			if ($data[$i] =~ /^Tk\:\:.*HASH\(.+\)$/o && $itemType =~ /^image/o) {   #WE HAVE AN IMAGE:
				@addArgs = ('-itemtype', $itemType, '-image', $data[$i]);
			} elsif (ref($data[$i]) =~ /HASH/o) {    #WE HAVE A HASHREF (PBLY IMAGE+TEXT) OR ADDITIONAL HList OPTIONS:
				@addArgs = ('-itemtype', $data[$i]->{'-itemtype'}||$itemType);
				foreach my $op (keys %{$data[$i]}) {  #PUT EACH OBJECT IN IT'S PROPER BUCKET:
					if ($op =~ /^\-(?:data|state)$/o) {  # => addchild(@childData)
						push @childData, $op, $data[$i]->{$op};
					} elsif ($op =~ /^\-(?:text|itemtype|image|underline)$/o) {  # => ItemCreate(@addArgs)
						push @addArgs, $op, $data[$i]->{$op};
					} elsif ($op =~ /^\-style$/o) {  # => ItemCreate(@addArgs)
						push @addArgs, $op, $data[$i]->{$op};
						$haveStyle = $data[$i]->{$op};
					} elsif ($op =~ /^\-indicator(.*)$/o) {   # => indicator(@indicatorOps)
						my $indop = $1;
						if ($indop =~ /\w/o) {   #SPECIFIC INDICATOR OPTIONS
							push @indicatorOps, "-$indop", $data[$i]->{$op};
						} else {                 #(SIMPLE) - JUST GAVE "-indicator $image" (SET UP BARE NEEDED OPTIONS):
							push @indicatorOps, '-itemtype', 'image', '-image', $data[$i]->{$op};
						}
					} elsif ($op =~ /^\-hidden$/o) {
						$hideit = $data[$i]->{$op};
					} elsif ($op !~ /^\-(?:user|sort)/o) {    #DATA OPTIONS WE WISH TO RETAIN BUT ARE NOT VALID FOR USE IN CREATING OBJECTS:
						$styleOps{$op} = $data[$i]->{$op};
					}
				}
			} else {  #WE JUST HAVE A TRADITIONAL TEXT STRING TO DISPLAY:
				@addArgs = ('-itemtype', 'text', '-text', $data[$i]);
			}
			push @childData, '-data', $data[$i];
		} else {      #WE HAVE NOTHING, ADD A SPACE SO IT'LL DISPLAY PROPERLY!
			@addArgs = ('-itemtype', 'text', '-text', ' ');
			push @childData, '-data', ' ';
		}
		push @childData, @atIndexArgs  if ($#atIndexArgs >= 0);
		my $child = $c->addchild("", @childData);    #CREATE "CHILD".
		unless ($haveStyle && $haveStyle =~ /^Tk::ItemStyle/o) {  #WE ALSO HAVE AN ItemStyle, TRY RECONFIGURING IT:
			if (keys(%styleOps) > 0) {   #WE HAVE "STYLE" OPTIONS, FILL IN ANY MISSING W/LISTBOX-WIDE OPTIONS AS DEFAULTS:
				#THIS IS NEEDED B/C "-refwindow" DOESN'T SEEM TO DO WHAT IT SAYS:
				#CHGD TO NEXT 20180704 TO PREVENT ERROR IF itemtype==image:  foreach my $style (qw(-background -foreground -fg -selectforeground)) {
				foreach my $style (qw(-background -foreground -fg -selectforeground)) {
					$styleOps{$style} ||= $c->cget($style);
				}
				$styleOps{'-font'} ||= $c->cget('-font')  if ($itemType =~ /text/o);
				push @addArgs, '-style', $c->ItemStyle(($data[$i]->{'-itemtype'}||$itemType), '-refwindow' => $c, %styleOps);
			}
		}
		$c->itemCreate($child, 0, @addArgs);    #CREATE THE ENTRY:
		if (@indicatorOps) {
			$c->indicator('create', $child, @indicatorOps);   #WE HAVE AN "INDICATOR" IMAGE, CREATE IT TOO:
		}
		$c->hide(-entry => $child)  if ($hideit);
	}
	return '';
}

sub delete {        #DELETE ONE OR MORE ITEMS FROM THE LIST:
	my $w = shift;

	my $first = $_[0];
	my $last = defined($_[1]) ? $_[1] : $first;
	if (!$first && $last =~ /^end/io) {
		$w->Tk::HList::delete('all');
	} else {
		$first = $w->getEntry($first);
		$last = $w->getEntry($last);
		my $next = $first;
		while ($w->info('exists', $next)) {
			my $n = $w->info('next', $next);
			$w->Tk::HList::delete('entry', $next);
			last  if ($next eq $last);
			$next = $n;
		}
	}
}

sub findIndex {    #FIND THE INDEX THAT MATCHES 
	my ($w, $itemSaught) = @_;

	my $pos = 0;
	my $next = $w->getFirstEntry;  #HACK NEEDED TO GET 1ST ENTITY AFTER SUBSEQUENT RELOADS:
	my $item;
	while ($next =~ /\S/o) {
		if ($w->info('exists', $next) && !$w->info('hidden', $next)) {
			$item = $w->info('data', $next);
			return $pos  if (((ref($item) && defined($item->{-text})) ? $item->{-text} : $item) eq $itemSaught);
			++$pos;
		}
		$next = $w->info('next', $next);
	}
	return undef;
}

sub getFirstEntry {
	my ($firstChild) = $_[0]->info('children');
	return ($firstChild =~ /\S/o) ? $firstChild : '';
}

sub getLastEntry {
	my @children = $_[0]->info('children');
	return @children ? pop(@children) : '';
}

sub getEntry {    #GIVEN A VALID LISTBOX "INDEX", RETURN THE EQUIVALENT HList "ENTRY" (NUMERIC, BUT NOT ZERO-BASED!):
	my ($w, $index) = @_;

	return $w->getLastEntry  if ($index =~ /^end/io);
	$index = $w->index($index);
	my $next = $w->getFirstEntry;
	my $next0;
	for (my $pos=0;$pos<$index;$pos++) {
		unless (defined($next) && $next =~ /\S/o) {
			return ($next0) ? $w->nearest($next0) : undef;
		}
		$next0 = $next;
		$next = $w->info('next', $next);
	}
	unless (defined($next) && $next =~ /\S/o) {
		return ($next0) ? $w->nearest($next0) : undef;
	}
	return $next;
}

sub getEntryList {    #CONVERT A LIST OF INDICIES TO HList "ENTRIES":
	my $w = shift;

	my @entries;
	foreach my $i (@_) {
		push @entries, $w->getEntry($i);
	}
	return @entries;
}

sub indexOf {  #GIVEN A VALID HList "ENTRY", RETURN IT'S RELATIVE (TO ZERO=1ST) Listbox "INDEX":
	my $next = $_[0]->getFirstEntry;
	my $indx = '0';
	while (defined($next) && $next =~ /\S/o) {
		return $indx  if (!defined($_[1]) || $next == $_[1]);
		$next = $_[0]->info('next', $next);
		++$indx;
	}
	return undef;   #ENTRY DOES NOT EXIST!			
}

sub index {    #GIVEN A VALIE "LISTBOX INDEX", RETURN A ZERO-BASED "INDEX" (CONVERTS STUFF LIKE "@x,y", "end". etc:
	if ($_[1] =~ /^\d+$/o) {
		return $_[1];
	} elsif (!$_[1]) {
		return '0';
	} elsif ($_[1] =~ /^end/io) {
		return $_[0]->size-1;
	} elsif ($_[1] =~ /^anchor/o) {
		return $_[0]->{'_vanchor'};
	} elsif ($_[1] =~ /^active/o) {
		return $_[0]->indexOf($_[0]->info('anchor'));
	} elsif ($_[1] =~ /^\@\d+\,(\d+)/o) {
		return $_[0]->indexOf($_[0]->nearest($1));
	}
	return undef;
}

sub Cntrl_Home {
	my $w = shift;
	my $Ev = $w->XEvent;

	$w->activate(0);
	$w->see(0);
	$w->selectionClear(0,'end');
	if (!$ENV{jwtlistboxhack}) {
		$w->selectionSet(0);
		$w->Callback(-browsecmd => 0);
	}
	$w->eventGenerate("<<ListboxSelect>>");
}

sub Cntrl_End {
	my $w = shift;
	my $Ev = $w->XEvent;

	$w->activate('end');
	$w->see('end');
	$w->selectionClear(0,'end');
	if (!$ENV{jwtlistboxhack}) {
		$w->selectionSet('end');
		$w->Callback(-browsecmd => $w->index('end'));
	}
	$w->eventGenerate("<<ListboxSelect>>");
}

sub DataExtend {    #USER PRESSED Shift-Ctrl-Home/End, SELECT FROM ANCHOR TO TOP OR BOTTOM RESPECTIVELY:
	my ($w, $el) = @_;

	my $active = $w->index('active');
	my $indx = $w->index($el);
	if ($w->cget('-selectmode') =~ /^(?:multiple|extended)/o) {
		$w->see($indx);
		$w->selectionSet($indx, $active);
		$w->eventGenerate("<<ListboxSelect>>");
		$w->Callback(-browsecmd);
	} else {
		$w->selectionClear();
		$w->see($indx);
		$w->selectionSet($indx);
		$w->activate($indx);
		$w->eventGenerate("<<ListboxSelect>>");
		$w->Callback(-browsecmd => $indx);
	}
}

sub SelectAll {
	my $w = shift;

	if ($w->cget('-selectmode') =~ /^(?:single|browse)/) { 
		$w->selectionClear(0,'end');
		$w->selectionSet('active');
		$w->Callback(-browsecmd => $w->index('active'));
	} else {
		$w->selectionSet(0,'end');
		$w->Callback(-browsecmd);
	}
	$w->eventGenerate("<<ListboxSelect>>");
}

sub Cntrl_backslash {
	my $w = shift;
	my $Ev = $w->XEvent;

	$w->selectionClear(0,'end');
	$w->eventGenerate("<<ListboxSelect>>");
	$w->Callback(-browsecmd);
}

sub Button1    #USER PRESSED LEFT MOUSE-BUTTON or SPACEBAR
{
	$_[0]->BeginSelect(@_);	
}

sub DoubleButton1    #USER DOUBLE-CLICKED LEFT MOUSE-BUTTON (has already done a single click)
{
	$_[0]->InvokeCommand;
	$_[0]->selectionClear('0','end');
	$_[0]->selectionSet($_[0]->index('active'));
	$_[0]->eventGenerate("<<ListboxSelect>>");
}

sub ShiftButton1   #JWT:NOT SURE WHERE THIS IS BOUND, BUT IS *DOES* GET CALLED & IS NEEDED:
{
	$_[0]->BeginExtend(@_);	
}

{
	my $lastItem;
	sub Button1Motion {
		my $Ev = $_[0]->XEvent;

		return unless defined $Ev;

# delete $_[0]->{'shiftanchor'};

		my $mode = $_[0]->cget('-selectmode');
		return  if ($mode =~ /^(?:single|dragdrop)/o);

		#HANDLE THIS SILLY TIX STUFF:
		my $ent;
		if (defined $_[0]->info('anchor')) {
			$ent = $_[0]->GetNearest($Ev->y);
		} else {
			$ent = $_[0]->GetNearest($Ev->y, 1);
		}
		return  unless (defined($ent) and length($ent));

		if (exists $_[0]->{tixindicator}) {
			my $event_type = $_[0]->{tixindicator} eq $ent ? '<Arm>' : '<Disarm>';
			$_[0]->Callback(-indicatorcmd => $_[0]->{tixindicator}, $event_type );
			return;
		}

		my $indx = $_[0]->indexOf($ent);
		if ($mode =~ /^browse/o) {
			$_[0]->selectionClear;
			$_[0]->selectionSet($indx);
			$_[0]->eventGenerate("<<ListboxSelect>>");
			$_[0]->Callback(-browsecmd => $indx);
		} elsif ($mode =~ /^(?:multiple|extended)/o) {
			my $from = $_[0]->info('anchor');
			if(defined $from) {
				if ($mode =~ /^multiple/o) {
					if ($_[0]->{'deselecting'}) {
						$_[0]->selectionClear($indx);
					} else {
						$_[0]->selectionSet($_[0]->indexOf($from), $indx);
					}
				} else {
					$_[0]->selectionClear()  if ($mode eq 'extended');
					$_[0]->selectionSet($_[0]->indexOf($from), $indx);
				}
				if (!defined($lastItem) || $lastItem != $indx) {
					$_[0]->eventGenerate("<<ListboxSelect>>");
					$_[0]->Callback(-browsecmd);
					$lastItem = $indx;
				}
			} else {      #no anchor set.
				if ($mode =~ /^multiple/o) {
					if ($_[0]->{'deselecting'}) {
						$_[0]->selectionClear($indx);
					} else {
						$_[0]->selectionSet($indx);
						$_[0]->anchorSet($indx);
					}
				} else {
					$_[0]->selectionClear()  if ($mode =~ /^extended/o);
					$_[0]->anchorSet($indx);
					$_[0]->selectionSet($indx);
				}
				$_[0]->eventGenerate("<<ListboxSelect>>");
			}
		} else {
			$Prev = $_[0]->index('anchor');
			$_[0]->selectionClear;
			$_[0]->anchorSet($indx);
			$_[0]->selectionSet($indx);
			$_[0]->eventGenerate("<<ListboxSelect>>");
			$_[0]->Callback(-browsecmd => $indx);
		}
	}
}

sub ShiftUpDown {    #USER PRESSED UP OR DOWN ARROW WHILST HOLDING <SHIFT> KEY DOWN:
	my $w = shift;
	my $spec = shift;
	$spec = ($1 >= 0) ? 'next' : 'prev'  if ($spec =~ /^([\+\-]?\d+)/o);
	return $w->UpDown($spec)  if($w->cget('-selectmode') !~ /^extended/o);

	my $amount = ($spec =~ /^prev/o) ? -1 : 1;
	my $active = $w->index('active');

	if ($ENV{'jwtlistboxhack'}) {
		if ($w->selectionIncludes($active)) {
			$w->selectionClear($active);
		} else {
			$w->selectionSet($active);
		}
	} else {
		if (!@Selection) {
			$w->selectionSet($active);
			@Selection = $w->curselection;
		}
	}

	#BEFORE ADVANCING, SKIP OVER ANY ENTRIES THAT ARE DISABLED OR HIDDEN:
	#(THIS ALWAYS ADVANCES AT LEAST ONE ENTRY!):
	my $ent = $w->getEntry($active);

	while ( 1 ) { 
		$ent = $w->info($spec, $ent);
		last  unless(defined $ent);
		next  if( $w->entrycget($ent, '-state') eq 'disabled' );
		next  if( $w->info('hidden', $ent) );
		last;
	}
	unless( $ent =~ /\S/o ) {	
		$w->yview('scroll', $amount, 'unit');
		$w->eventGenerate("<<ListboxSelect>>");
		$w->Callback(-browsecmd => $active);
		return;
	}
	$active = $w->indexOf($ent);  #THE "NEXT" ENTRY.
	$w->activate($active);
	$w->see('active');
	if ($ENV{'jwtlistboxhack'}) {
		$w->selectionAnchor($active);
		$w->eventGenerate("<<ListboxSelect>>");
	} else {
		$w->Motion($w->index('active'));
	}
	$w->Callback(-browsecmd => $active);
}

sub ExtendUpDown  #COMPATABILITY W/Listbox:
{
	$_[0]->ShiftUpDown(@_);
}

sub UpDown   #USER PRESSED AN UP OR DOWN ARROW KEY:
{
	my $w = shift;
	my $spec = shift;
	if ($spec =~ /^([\+\-]?\d+)/o) {
		$spec = ($1 >= 0) ? 'next' : 'prev';
	}
	my $active = $w->index('active');
	my $ent = $w->getEntry($active);
	while ( 1 ) { 
		$ent = $w->info($spec, $ent);
		last unless( defined $ent );
		next if( $w->entrycget($ent, '-state') eq 'disabled' );
		next if( $w->info('hidden', $ent) );
		last;
	}
	unless (defined($ent) && $ent =~ /\S/o) {	
		my $amount = ($spec =~ /^prev/o) ? -1 : 1;
		$w->yview('scroll', $amount, 'unit');
		return;
	}
	$active = $w->indexOf($ent);
	$w->activate($active);
	$w->see('active');
	my $mode = $w->cget('-selectmode');
	if ($mode =~ /^browse/o)
	{
		$w->selectionClear(0,'end');
		$w->selectionSet('active');
		$w->eventGenerate("<<ListboxSelect>>");
		$w->Callback(-browsecmd => $active);
	} elsif ($mode =~ /^extended/o && !$ENV{'jwtlistboxhack'}) {
		$w->selectionClear(0,'end');
		$w->selectionSet('active');
		$w->selectionAnchor('active');
		$Prev = $w->index('active');
		@Selection = ();
		$w->eventGenerate("<<ListboxSelect>>");
	}
}

sub selectionIncludes {
#print "-???- selectionIncludes($_[1]): Entry=".$_[0]->getEntry($_[1])."=\n";
	return 0 unless ($_[0]->index($_[1]) =~ /\d/o);
	return $_[0]->Tk::HList::selectionIncludes($_[0]->getEntry($_[1]));
}

sub itemconfigure {   #SET OPTIONS ON INDIVIDUAL ITEMS:
	my $w = shift;
	my $entry = $w->getEntry(shift);
	if (defined $_[0]) {
		my $opt = shift;
		if ($opt =~ /^\-(?:style|text|itemtype|image|underline)$/o) {   #THESE OPTIONS CAN BE DIRECTLY CONFIGURED:
			return $w->itemConfigure($entry, 0, $opt, @_);
		} else {    #OTHER OPTIONS MUST BE CONFIGURED IN AN HList "ItemStyle" OBJECT:
			my @ops = ($opt, @_);
			for (my $i=0;$i<=$#ops;$i++) {
				$ops[$i] = '-fg'  if ($ops[$i] =~ /^\-foreground$/o);
			}
			my $itemtype = $w->itemCget($entry, 0, '-itemtype');
			return $w->itemConfigure($entry, 0, '-style', $w->ItemStyle($itemtype, @ops));
		}
	} else {   #NO OPTIONS SPECIFIED, SIMPLY RETURN THE ONES WE CAN CONFIGURE:
		return $w->itemConfigure($entry, 0);
	}
}

sub itemcget {   #GET PREVIOUSLY-SET OPTIONS ON INDIVIDUAL ITEMS:
	my $w = shift;
	my $entry = $w->getEntry(shift);
	if (defined $_[0]) {
		my $opt = shift;
		if ($opt =~ /^\-(?:style|text|itemtype|image|underline)$/o) {   #THESE OPTIONS CAN BE DIRECTLY CONFIGURED:
			return $w->itemCget($entry, 0, $opt, @_);
		} else {    #OTHER OPTIONS MUST BE CONFIGURED IN AN HList "ItemStyle" OBJECT:
			my $style = $w->itemCget($entry, 0, '-style');
			if ($style) {    #GET ANY "STYLE" OBJECT 
				$opt = '-fg'  if ($opt =~ /^\-foreground$/o);
				return $style->cget($opt);
			}
		}
		return undef;
	} else {
		return $w->itemCget($entry, 0, @_);
	}
}

sub BeginSelect   #Mouse button-press (button 1)
{
	my $w = shift;
	my $el = shift;

	#HANDLE THIS SILLY "TIX" STUFF:
	my $Ev = $w->XEvent;
	my @info = $w->info('item',$Ev->x, $Ev->y);
	if (defined($info[1]) && $info[1] eq 'indicator') { 
		$w->{tixindicator} = $el;
		$w->Callback(-indicatorcmd => $el, '<Arm>');
		return;
	}
	#TOGGLE SELECTION STATUS, SET ANCHOR IF "extended":
	if ($w->cget('-selectmode') =~ /^(?:multiple|extended)/o) {
		if ($w->selectionIncludes($el)) {  #TOGGLE SELECT-STATUS OF ENTRY CLICKED ON:
			$w->selectionClear($el);
		} else {
			$w->selectionSet($el);
		}
		$w->selectionAnchor($el);
	} elsif ($ENV{'jwtlistboxhack'}) {  #WE ALLOW SELECTION TO BE EMPTY IN SINGLE/BROWSE MODES!:
		if ($w->selectionIncludes($el)) {  #TOGGLE SELECT-STATUS OF ENTRY CLICKED ON:
			$w->selectionClear(0,'end');
		} else {
			$w->selectionClear(0,'end');
			$w->selectionSet($el);
		}
	} else {
		$w->selectionClear(0,'end');
		$w->selectionSet($el);
		$w->selectionAnchor($el);
	}
	@Selection = ();
	$Prev = $el;
#	$w->focus  if ($w->cget('-takefocus'));
	$w->eventGenerate("<<ListboxSelect>>");
}

sub CtrlPriorNext {   #USER PRESSED <CONTROL-<PgUp>/<PgDown>> - OUR SPECIAL SELECT NEXT SCREEN-FULL:
	my $w = shift;
	my $updown = shift;
	if ($w->cget('-selectmode') =~ /^(?:multiple|extended)/o) {
		my $anchor = $w->index('anchor');
		$selectTo = $anchor + ($updown * $w->cget('-height'));
		if ($updown >= 0) {
			my $lastIndex = $w->index('end');
			$selectTo = $lastIndex  if ($selectTo > $lastIndex);
		} else {
			$selectTo = 0  if ($selectTo < 0);
		}
		$w->selectionSet($anchor, $selectTo);
		$w->anchorSet($selectTo);
		$w->activate($selectTo);
		$w->see($selectTo);
		$w->eventGenerate("<<ListboxSelect>>");
		$w->Callback('-browsecmd');
	} else {
		#$w->Tk::HList::yview('scroll',$updown, 'pages');
		$w->yview('scroll',$updown, 'pages');
	}
}

#THESE FUNCTIONS SUPPORT THE "TIED" STUFF - DON'T KNOW HOW ANY OF THIS WORKS, BUT I COPIED IT FROM LISTBOX AND IT JUST WORKS:

sub TIEARRAY {
  my ( $class, $obj, %options ) = @_;
  return bless {
	    OBJECT => \$obj,
	    OPTION => \%options }, $class;
}

sub TIESCALAR {
  my ( $class, $obj, %options ) = @_;
  return bless {
	    OBJECT => \$obj,
	    OPTION => \%options }, $class;
}

# FETCH
# -----
# Return either the full contents or only the selected items in the
# box depending on whether we tied it to an array or scalar respectively
sub FETCH {
  my $class = shift;

  my $self = ${$class->{OBJECT}};
  my %options = %{$class->{OPTION}} if defined $class->{OPTION};;
  # Define the return variable
  my $result;

  # Check whether we are have a tied array or scalar quantity
  if ( @_ ) {
     my $i = shift;
     # The Tk:: Listbox has been tied to an array, we are returning
     # an array list of the current items in the Listbox
     $result = $self->get($i);
  } else {
     # The Tk::Listbox has been tied to a scalar, we are returning a
     # reference to an array or hash containing the currently selected items
     my ( @array, %hash );

     if ( defined $options{ReturnType} ) {

        # THREE-WAY SWITCH
        if ( $options{ReturnType} eq "index" ) {
           $result = [$self->curselection];
        } elsif ( $options{ReturnType} eq "element" ) {
	   foreach my $selection ( $self->curselection ) {
              push(@array,$self->get($selection)); }
           $result = \@array;
	} elsif ( $options{ReturnType} eq "both" ) {
	   foreach my $selection ( $self->curselection ) {
              %hash = ( %hash, $selection => $self->get($selection)); }
           $result = \%hash;
	}
     } else {
        # return elements (default)
        foreach my $selection ( $self->curselection ) {
           push(@array,$self->get($selection)); }
        $result = \@array;
     }
  }
  return $result;
}

# FETCHSIZE
# ---------
# Return the number of elements in the Listbox when tied to an array
sub FETCHSIZE {
  my $class = shift;
  return ${$class->{OBJECT}}->size();
}

# STORE
# -----
# If tied to an array we will modify the Listbox contents, while if tied
# to a scalar we will select and clear elements.
sub STORE {
  if ( scalar(@_) == 2 ) {
     # we have a tied scalar
     my ( $class, $selected ) = @_;
     my $self = ${$class->{OBJECT}};
     my %options = %{$class->{OPTION}} if defined $class->{OPTION};;

     # clear currently selected elements
     $self->selectionClear(0,'end');

     # set selected elements
     if ( defined $options{ReturnType} ) {

        # THREE-WAY SWITCH
        if ( $options{ReturnType} eq "index" ) {
           for ( my $i=0; $i < scalar(@$selected) ; $i++ ) {
              for ( my $j=0; $j < $self->size() ; $j++ ) {
                  if( $j == $$selected[$i] ) {
	             $self->selectionSet($j); last; }
              }
           }
        } elsif ( $options{ReturnType} eq "element" ) {
           for ( my $k=0; $k < scalar(@$selected) ; $k++ ) {
              for ( my $l=0; $l < $self->size() ; $l++ ) {
                 if( $self->get($l) eq $$selected[$k] ) {
	            $self->selectionSet($l); last; }
              }
           }
	} elsif ( $options{ReturnType} eq "both" ) {
           foreach my $key ( keys %$selected ) {
              $self->selectionSet($key)
	              if $$selected{$key} eq $self->get($key);
	   }
	}
     } else {
        # return elements (default)
        for ( my $k=0; $k < scalar(@$selected) ; $k++ ) {
           for ( my $l=0; $l < $self->size() ; $l++ ) {
              if( $self->get($l) eq $$selected[$k] ) {
	         $self->selectionSet($l); last; }
           }
        }
     }

  } else {
     # we have a tied array
     my ( $class, $index, $value ) = @_;
     my $self = ${$class->{OBJECT}};

     # check size of current contents list
     my $sizeof = $self->size();

#THIS SOMETIMES FAILS CAUSING THE FIRST ELEMENT TO NOT BE ADDED?!     if ( $index <= $sizeof ) {
#        # Change a current listbox entry
#        $self->delete($index);
#        $self->insert($index, $value);
#     } else {
        # Add a new value
#        if ( defined $index ) {
#           $self->insert($index, $value);
#        } else {
           $self->insert("end", $value);
#        }
#     }
     $self->activate('end')  unless ($self->index('active') =~ /\d/o); #MAKE SURE SOMETHING'S ACTIVE.
   }
}

sub STORESIZE
{

	my $class = shift;
	my $w = ${$class->{OBJECT}};
	my $newsz = shift;
	my $cursz = $w->size;

	return  if ($newsz >= $cursz);

	${$class->{OBJECT}}->delete($newsz, $cursz);
	$#{$class->{-ptr}} = $newsz - 1;
}

# CLEAR
# -----
# Empty the Listbox of contents if tied to an array
sub CLEAR {
  my $class = shift;
  ${$class->{OBJECT}}->delete(0, 'end');
}

# EXTEND
# ------
# Do nothing and be happy about it
sub EXTEND { }

# PUSH
# ----
# Append elements onto the Listbox contents
sub PUSH {
  my ( $class, @list ) = @_;
  ${$class->{OBJECT}}->insert('end', @list);
}

# POP
# ---
# Remove last element of the array and return it
sub POP {
   my $class = shift;

   my $value = ${$class->{OBJECT}}->get('end');
   ${$class->{OBJECT}}->delete('end');
   return $value;
}

# SHIFT
# -----
# Removes the first element and returns it
sub SHIFT {
   my $class = shift;

   my $value = ${$class->{OBJECT}}->get(0);
   ${$class->{OBJECT}}->delete(0);
   return $value
}

# UNSHIFT
# -------
# Insert elements at the beginning of the Listbox
sub UNSHIFT {
   my ( $class, @list ) = @_;
   ${$class->{OBJECT}}->insert(0, @list);
}

# DELETE
# ------
# Delete element at specified index
sub DELETE {
   my ( $class, @list ) = @_;

   my $value = ${$class->{OBJECT}}->get(@list);
   ${$class->{OBJECT}}->delete(@list);
   return $value;
}

# EXISTS
# ------
# Returns true if the index exist, and undef if not
sub EXISTS {
   my ( $class, $index ) = @_;
   return undef unless ${$class->{OBJECT}}->get($index);
}

# SPLICE
# ------
# Performs equivalent of splice on the listbox contents
sub SPLICE {
   my $class = shift;

   my $self = ${$class->{OBJECT}};

   # check for arguments
   my @elements;
   if ( scalar(@_) == 0 ) {
      # none
      @elements = $self->get(0,'end');
      $self->delete(0,'end');
      return wantarray ? @elements : $elements[scalar(@elements)-1];;

   } elsif ( scalar(@_) == 1 ) {
      # $offset
      my ( $offset ) = @_;
      if ( $offset < 0 ) {
         my $start = $self->size() + $offset;
         if ( $start > 0 ) {
	    @elements = $self->get($start,'end');
            $self->delete($start,'end');
	    return wantarray ? @elements : $elements[scalar(@elements)-1];
         } else {
            return undef;
	 }
      } else {
	 @elements = $self->get($offset,'end');
         $self->delete($offset,'end');
         return wantarray ? @elements : $elements[scalar(@elements)-1];
      }

   } elsif ( scalar(@_) == 2 ) {
      # $offset and $length
      my ( $offset, $length ) = @_;
      if ( $offset < 0 ) {
         my $start = $self->size() + $offset;
         my $end = $self->size() + $offset + $length - 1;
	 if ( $start > 0 ) {
	    @elements = $self->get($start,$end);
            $self->delete($start,$end);
	    return wantarray ? @elements : $elements[scalar(@elements)-1];
         } else {
            return undef;
	 }
      } else {
	 @elements = $self->get($offset,$offset+$length-1);
         $self->delete($offset,$offset+$length-1);
         return wantarray ? @elements : $elements[scalar(@elements)-1];
      }

   } else {
      # $offset, $length and @list
      my ( $offset, $length, @list ) = @_;
      if ( $offset < 0 ) {
         my $start = $self->size() + $offset;
         my $end = $self->size() + $offset + $length - 1;
	 if ( $start > 0 ) {
	    @elements = $self->get($start,$end);
            $self->delete($start,$end);
	    $self->insert($start,@list);
	    return wantarray ? @elements : $elements[scalar(@elements)-1];
         } else {
            return undef;
	 }
      } else {
	 @elements = $self->get($offset,$offset+$length-1);
         $self->delete($offset,$offset+$length-1);
	 $self->insert($offset,@list);
         return wantarray ? @elements : $elements[scalar(@elements)-1];
      }
   }
}

sub ButtonRelease_1
{
	my $w = shift;
	my $Ev = $w->XEvent;

	my $mode = $w->cget('-selectmode');
	$w->CancelRepeat  if($mode !~ /^dragdrop/o);
	my $ent = $w->indexOf($w->GetNearest($Ev->y));

	return unless (defined($ent) and length($ent));  #BUTTON RELEASED OUTSIDE OF WIDGET? (PUNT)
	if (exists $w->{tixindicator}) {  #HANDLE THIS SILLY "TIX" STUFF:
		my @info = $w->info('item',$Ev->x,$Ev->y);

		if (defined($info[1]) && $info[1] eq 'indicator' && $w->{tixindicator} eq $ent)  #WE'RE RELEASING ON THE INDICATOR:
		{
			$w->Callback(-indicatorcmd => $ent, '<Activate>');
		} else {  #EITHER WE RELEASED OUTSIDE THE INDICATOR OR ON A DIFFERENT ENTRY:
			$w->Callback(-indicatorcmd => $w->{tixindicator}, '<Disarm>');
		}
		delete $w->{tixindicator};
		return;
	}
	$w->activate($Ev->xy);
	if ($mode =~ /^(?:multiple|extended)/o) {
		$w->Callback(-browsecmd);
	} else {
		(my $sel) = $w->curselection;
		$w->Callback(-browsecmd => $sel)  if ($sel =~ /\d/o);
	}
}

# Motion --
#
# This procedure is called to process mouse motion events while
# button 1 is down. It may move or extend the selection, depending
# on the listbox's selection mode.
#
# Arguments:
# w - The listbox widget.
# el - The element under the pointer (must be a number).
sub Motion
{
	my $w = shift;
	my $el = shift;
	#HANDLE THIS SILLY "TIX" STUFF:
	my $Ev = $w->XEvent;
	my @info = $w->info('item',$Ev->x, $Ev->y);

	return  if (exists($w->{tixindicator}));
	return  unless (defined $el);
	return  if (defined($Prev) && $el == $Prev);

	my $anchor = $w->index('anchor');
	if ($ENV{'jwtlistboxhack'}) {
		unless (defined($anchor) && $anchor =~ /\d/o) {
			$anchor = $el;
			$w->selectionAnchor($anchor);
			$w->selectionSet($el);
		}
	}
	my $mode = $w->cget('-selectmode');
	if ($mode =~ /^browse/o) {
		$w->selectionClear(0,'end');
		$w->selectionSet($el);
		$Prev = $el;
		$w->eventGenerate("<<ListboxSelect>>");
	} elsif ($mode =~ /^extended/o) {
		my $i = $Prev;
		if (!defined $i || $i eq '') {
			$i = $el;
			$w->selectionSet($el);
		}
		if ($w->selectionIncludes('anchor')) {
			$w->selectionClear($i,$el);
			$w->selectionSet('anchor',$el)
		} else {
			$w->selectionClear($i,$el);
			$w->selectionClear('anchor',$el);
		}
		if (!@Selection) {
			@Selection = $w->curselection;
		}
		while ($i < $el && $i < $anchor) {
			if (Tk::lsearch(\@Selection,$i) >= 0) {
				$w->selectionSet($i);
			}
			$i++
		}
		while ($i > $el && $i > $anchor) {
			if (Tk::lsearch(\@Selection,$i) >= 0) {
				$w->selectionSet($i);
			}
			$i--;
		}
		$Prev = $el;
		$w->eventGenerate("<<ListboxSelect>>");
	}
}
# BeginExtend --
#
# This procedure is typically invoked on shift-button-1 presses. It
# begins the process of extending a selection in the listbox. Its
# exact behavior depends on the selection mode currently in effect
# for the listbox; see the Motif documentation for details.
#
# Arguments:
# w - The listbox widget.
# el - The element for the selection operation (typically the
# one under the pointer). Must be in numerical form.
sub BeginExtend    #JWT: SELECT FROM ACTIVE TO THE ONE WE CLICKED ON (INCLUSIVE):
{
	my $w = shift;
	my $el = shift;

	if ($ENV{'jwtlistboxhack'}) {
		if ($w->cget('-selectmode') =~ /^extended/o) {
			my $active = $w->index('active');
			if ($el == $active) {  #IF CLICKED ON ACTIVE, TOGGLE SELECT-STATUS:
				if ($w->selectionIncludes($el))
				{
					$w->selectionClear($el);
				}
				else
				{
					$w->selectionSet($el);
				}
			} else {               #OTHERWISE SELECT FROM ACTIVE TO ONE WE CLICKED ON AND ACTIVE IT:
				$w->selectionSet($active, $el);
			}
		} else {
			# No selection yet; simulate the begin-select operation.
			$w->BeginSelect($el);
		}
	} else {
		if ($w->cget('-selectmode') =~ /^extended/o && $w->selectionIncludes('anchor')) {
			$w->Motion($el)
		} else {
			# No selection yet; simulate the begin-select operation.
			$w->BeginSelect($el);
		}
	}
	$w->eventGenerate("<<ListboxSelect>>");
}

sub ShiftSpace  #Shift-spacebar pressed:  Select from anchor to active inclusive:
{
	my $w = shift;
	my $el = shift;

	my $anchor = $w->index('anchor');
	my $mode = $w->cget('-selectmode');
	$w->activate($el);
	if (defined($anchor) && $mode =~ /^extended/o
			&& ($anchor >= 0 && $anchor < $w->index('end'))) {
		$w->selectionSet($anchor, $w->index('active'));
		$w->Callback(-browsecmd);
	} else {
		if ($w->selectionIncludes($el))  #TOGGLE SELECT-STATUS OF ENTRY CLICKED ON:
		{
			$w->selectionClear($el);
		}
		else
		{
			$w->selectionSet($el);
		}
		if ($mode =~ /^multiple/o) {
			$w->Callback(-browsecmd);
		} else {
			$w->Callback(-browsecmd => $el);
		}
	}
	$w->selectionAnchor($el);
	$w->eventGenerate("<<ListboxSelect>>");
}

# BeginToggle --
#
# This procedure is typically invoked on control-button-1 presses. It
# begins the process of toggling a selection in the listbox. Its
# exact behavior depends on the selection mode currently in effect
# for the listbox; see the Motif documentation for details.
#
# Arguments:
# w - The listbox widget.
# el - The element for the selection operation (typically the
# one under the pointer). Must be in numerical form.
sub BeginToggle
{
 my $w = shift;
 my $el = shift;
 if ($w->cget('-selectmode') =~ /^extended/o)
  {
   @Selection = $w->curselection();
   $Prev = $el;
   $w->selectionAnchor($el);
   $w->activate($el);  #FOR SOME REASON, Listbox ALWAYS ACTIVATES W/O CALLING THIS HERE?
   if ($w->selectionIncludes($el))
    {
     $w->selectionClear($el)
    }
   else
    {
     $w->selectionSet($el)
    }
   $w->eventGenerate("<<ListboxSelect>>");
  }
}
# AutoScan --
# This procedure is invoked when the mouse leaves an entry window
# with button 1 down. It scrolls the window up, down, left, or
# right, depending on where the mouse left the window, and reschedules
# itself as an "after" command so that the window continues to scroll until
# the mouse moves back into the window or the mouse button is released.
#
# Arguments:
# w - The entry window.
# x - The x-coordinate of the mouse when it left the window.
# y - The y-coordinate of the mouse when it left the window.
sub AutoScan
{
 my $w = shift;
 return if !Tk::Exists($w);
 my $x = shift;
 my $y = shift;
 if ($y >= $w->height)
  {
   $w->yview('scroll',1,'units')
  }
 elsif ($y < 0)
  {
   $w->yview('scroll',-1,'units')
  }
 elsif ($x >= $w->width)
  {
   $w->xview('scroll',2,'units')
  }
 elsif ($x < 0)
  {
   $w->xview('scroll',-2,'units')
  }
 else
  {
   return;
  }
 $w->Motion($w->index("@" . $x . ',' . $y));
 $w->RepeatId($w->after(50,'AutoScan',$w,$x,$y));
}

sub Cancel
{
	my $w = shift;

	if ($ENV{'jwtlistboxhack'}) {
		$w->selectionClear('0', 'end')  if ($w->cget('-selectmode') =~ /^(?:multiple|extended)/o);
	} else {
		return if ($w->cget('-selectmode') ne 'extended' || !defined $Prev);

		my $first = $w->index('anchor');
		my $active = $w->index('active');
		my $last = $Prev;
		($first, $last) = ($last, $first)  if ($first > $last);
		$w->selectionClear($first,$last);
		while ($first <= $last) {
			if (Tk::lsearch(\@Selection,$first) >= 0) {
				$w->selectionSet($first)
			}
			$first++
		}
		$w->activate($active);  #FOR SOME REASON THIS GETS CLEARED?!
	}
	$w->eventGenerate("<<ListboxSelect>>");
}

sub InvokeCommand  #USER PRESSED THE <RETURN> KEY, CALL CALLBACK.
{
	my $w = shift;
	my $active = $w->index('active');

	if ($w->cget('-selectmode') =~ /^(?:multiple|extended)/) {
		my $SelectedRef = $w->curselection;
		$w->Callback(-command => $active, $SelectedRef);
	} else {
		my ($Selected1) = $w->curselection;
		$w->Callback(-command => $active, $Selected1)
	}
}

sub show
{
	my $w = shift;
	my @args = @_;
	unshift @args, '-entry'  unless ($#args >= 1 && $args[0] =~ /^\-/);
	$args[1] = $w->getEntry($args[1]);
	$w->Tk::HList::show(@args);
}

sub hide
{
	my $w = shift;
	my @args = @_;
	unshift @args, '-entry'  unless ($#args >= 1 && $args[0] =~ /^\-/);
	$args[1] = $w->getEntry($args[1]);
	$w->Tk::HList::hide(@args);
}

sub bbox
{
	return $_[0]->infoBbox($_[0]->getEntry($_[1]));
}

1

__END__

