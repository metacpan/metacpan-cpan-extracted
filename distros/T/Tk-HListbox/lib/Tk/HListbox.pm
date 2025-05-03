=head1 NAME

Tk::HListbox - Tk Listbox widget supporting images and text entries, Tk::HList-based drop-in replacement for Tk::Listbox.

=for category  Tk Widget Classes

=head1 SYNOPSIS

I<$listbox> = I<$parent>-E<gt>B<HListbox>(?I<options>?);

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
below.  If an HListbox is exporting its selection (see B<exportSelection> 
option), then it will observe the standard X11 protocols 
for handling the selection.
HListbox selections are available as type B<STRING>; 
the value of the selection will be the "text" of the selected elements, 
returned as an array of zero or more elements.

It is not necessary for all the elements to be 
displayed in the HListbox window at once;  commands described below 
may be used to change the view in the window.  HListboxes allow 
scrolling in both directions using the standard B<xScrollCommand> 
and B<yScrollCommand> options.  They also support scanning, as described below.

=head1 STANDARD OPTIONS

B<-background> B<-borderwidth> B<-cursor> B<-disabledforeground> 
B<-exportselection> B<-font> B<-foreground> B<-height> 
B<-highlightbackground> B<-highlightcolor> B<-highlightthickness> 
B<-offset> B<-relief> B<-selectbackground> B<-selectborderwidth> 
B<-selectforeground> B<-setgrid> B<-state> B<-takefocus> 
B<-width> B<-xscrollcommand> B<-yscrollcommand>

See L<Tk::options> for details of the standard options.

=head1 WIDGET-SPECIFIC OPTIONS

=over

=item Name: B<Entries>

Entries (rows) are added to HListbox vertically as rows, one per row (line) 
using either the B<insert> method or inserting into a tied array. 
Entries can be either a text string (just like a standard L<Tk::Listbox> 
entry), an image (a L<Tk::Photo> object), or a hashref containing options 
specifying both, along with any other desired L<Tk::HList>-valid I<options> 
(see below).  
Example:  $listbox->insert('end', {-image => $image, -text => 'string'}); 
Options for the referenced hash include:

=over

=item B<-hidden> => 1 | 0 

Specifies whether or not the entry should be visible or hidden:  (0 (false) 
for visible, 1 (true) for hidden).

Default:  B<0> (visible).

=item B<-indicatoritemtype> => ['text' | 'image' | 'imagetext']

Specify an "indicator" of this type.

=item B<-indicatorimage => $image

Special image to be displayed next to entry (in addition to any other image 
specified in the entry).

=item B<-indicatortext => 'text'

Special text to be displayed next to entry (in addition to any other image 
specified in the entry).

=item B<-itemtype> => ['text' | 'image' | 'imagetext']

Specifies the type of display item of this entry.  Can be 
I<"text">, I<"image">, or I<"imagetext">.

Default:  Whatever is specified, if anything, for the widget, (see B<-itemtype> 
under B<WIDGET OPTIONS> below).  If not specified there, then the default is 
I<"text">, though I<"imagetext"> allows for either or both an image or text.

=item B<-textanchor> => ['n', 's', 'e', 'w']

Side of text the IMAGE is displayed on.

Default: I<'w'> (West / left, ie. image before text)

=item B<-style> => $ImageStyleObject

Use an already-defined HList B<ItemStyle> object 
(see Tk::ItemStyle and Tk::DItem)

=item B<-sort> => 'value', B<-user> => 'value'

Specifies user-specific data to be kept stored with the entry but not 
displayed.  Such data would most likely be a string, but could be a reference 
to pretty much anything.  Tk::HMListbox makes use of the B<-sort> field for 
user-control of column sorting, refer to it's documentation for examples.

=item B<-text> $string

Specifies a "text" entry.  $string represents the text to be displayed in 
the entry.

These options are not passed to functions, but retained with data, useful for 
saving info with an entry for one's own use.

For example, one could put text in a I<-sort> option of say, an image-only 
entry and then retrieve it in a sort function 
like "sort { $a->{-sort} cmp $b->{-sort} }".

Any other option, other than these or the standard applicable widget options, 
such as B<-background>, etc. are treated as "Style" options and sent to the 
default B<ItemStyle> for the data type.  NOTE:  Under the current 
implementation any "Style" options supplied with an entry will be applied to 
ALL entries of that "type" (ie. "image", "imagetext", or "text") in 
the listbox.  To force a specific entry to have a different "style", define 
an B<ItemStyle> object and use the B<-style> option.

=back

=item Name: B<activeForeground>

=item Class: B<activeForeground>

=item Switch: B<-activeforeground>

Specifies an alternate color for the foreground of the "active" entry (the one 
the text cursor is on).  This entry is also shown with a hashed box around it.  
The "activebackground" color, however, is always fixed as the same color as the 
the widget's background.  

Default:  Same color as the widget's foreground color.

=item Name:	B<browsecmd>

=item Class:	B<BrowseCmd>

=item Switch:	B<-browsecmd>

Specifies a perl/Tk L<callback|Tk::callbacks> to be executed when the user 
browses through the entries in the HList widget.

=item Name:	B<command>

=item Class:	B<Command>

=item Switch:	B<-command>

Specifies the perl/Tk L<callback|Tk::callbacks> to be executed when the user 
invokes a list entry in the HList widget. Normally the user invokes a list 
entry by double-clicking it or pressing the Return key.

=item Switch: B<-gap> value

The amount of space between the image and text in rows that have both.

Default: B<4> (pixels)

=item Name:	B<height>

=item Class:	B<Height>

=item Switch:	B<-height>

Specifies the desired height for the window, in number of characters.  
If zero or less, then the desired height for the window is based on the 
default for HList, which seems to be about 7 lines.  WARNING:  This is NOT 
accurate, ie. specifying a -height of 8 will typically display about 6-6 1/2 
rows of text in the default font.  Sorry, but this is a bug in the underlying 
Tk::HList widget.

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

=item Name: B<-ipadx>

Specify horizontal padding style in pixels around the image 
for the rows in the listbox which are type I<image> or I<imagetext>.

Default:  B<0> (no padding added)

=item Name: B<-ipady>

Specify vertical padding style in pixels around the image 
for the rows in the listbox which are type I<image> or I<imagetext>.
NOTE:  This changes the height of the affected rows.

Default:  B<1> (pixels added to both top and bottom, and setting to B<0> 
is the same as B<1>).

=item Name:	B<itemType>

=item Class:	B<ItemType>

=item Switch:	B<-itemtype>

Specifies the default type of display item.  Can be "text", "image", or 
"imagetext".

Default:  B<"text">, though I<"imagetext"> allows for either or both an image 
or text.

=item Name:	B<listVariable>

=item Class:	B<Variable>

=item Switch:	B<-listvariable>

Specifies the reference of a variable. The value of the variable is an array 
to be displayed inside the widget; if the variable value changes then the 
widget will automatically update itself to reflect the new value. Attempts 
to unset a variable in use as a -listvariable may fail without error.

The listvariable reference is "TIEd" to the HListbox widget just as if one 
has done: "tie @listvariable, 'Tk::HListbox', $HListboxwidget, 
(ReturnType => 'index);" immediately after defining $HListboxwidget using the 
"tie @array" feature. 

=item Name:	B<selectBackground>

=item Class:	B<SelectBackground>

=item Switch:	B<-selectbackground>

Specifies an alternate background color for item(s) currently "selected".  

Default:  A slightly brighter shade of the widget's current background color.

=item Name:	B<selectForeground>

=item Class:	B<SelectForeground>

=item Switch:	B<-selectforeground>

Specifies an alternate foreground color for item(s) currently "selected".

Default:  The widget's current foreground color.

=item Name:	B<selectMode>

=item Class:	B<SelectMode>

=item Switch:	B<-selectmode>

Specifies one of several styles for manipulating the selection.  
The value of the option may be arbitrary, but the default bindings 
expect it to be either B<single>, B<browse>, B<multiple>, 
B<extended> or B<dragdrop>;  the default value is B<browse>.

=item Name: B<-showcursoralways>

=item Class: B<-showcursoralways>

=item Switch: B<-showcursoralways>

Starting with version 2.4, Tk::HListbox no longer displays the keyboard 
cursor (active element) when the HListbox widget does not have the 
keyboard focus, in order to be consistent with the behaviour of 
Tk::Listbox.  This option, when set to 1 (or a "true" value) restores 
the pre-v2.4 behaviour of always showing the keyboard cursor.
Default I<0> (False).

=item Name:	B<state>

=item Class:	B<State>

=item Switch:	B<-state>

Specifies one of two states for the listbox: B<normal> or B<disabled>.  
If the listbox is disabled then items may not be inserted or deleted, items 
are drawn in the B<-disabledforeground> color, and selection cannot be 
modified and is not shown (though selection information is retained).

=item Name:	B<takeFocus>

=item Class:	B<TakeFocus>

=item Switch: B<-takefocus>

There are actually three different focusing options:  Specify B<1> to both 
allow the widget to take keyboard focus itself and to enable grabbing the 
keyboard focus when a user clicks on a row in the listbox.  Specify B<''> 
to allow the widget to take focus (via the <TAB> circulate order) but do 
not grab the focus when a user clicks on (selects) a row.  This is the 
default focusing model.  Specify B<0> to not allow the widget to receive 
the keyboard focus.

=item Name: B<-tpadx> => I<number>

Specify horizontal padding style in pixels around the text for the rows in 
the listbox which are type I<text>.

Default:  B<2> (pixels - added to both left and right side)

=item Name: B<-tpady> => I<number>

Specify vertical padding style in pixels around the text for the rows in the 
listbox which are type I<text>.  NOTE:  This changes the height of the 
affected rows.

Default (seems to be):  B<2> (and setting to B<0> is the same as B<2>).

=item Name:	B<width>

=item Class:	B<Width>

=item Switch:	B<-width>

Specifies the desired width for the window in characters.  If the font 
doesn't have a uniform width then the width of the character "0" is used in 
translating from character units to screen units.  If zero or less, then the 
desired width for the window is made just large enough to hold all the 
elements in the listbox.

=back

=head1 LISTBOX OPTIONS AND METHODS NOT (YET?) SUPPORTED BY HLISTBOX

=over

=item Name:	B<activeStyle>

=item Class:	B<ActiveStyle>

=item Switch:	B<-activestyle>

Ignored (not implemented in HList).

For the most part, Tk::HListbox can be used as drop-in replacement 
for the Tk::Listbox widget when you need to use images instead of or 
in addition to text values, or need other Tk::HListbox - specific 
features such as hidden or disabled entries, callbacks, etc.

=back

=head1 INDICES

Many of the methods for HListboxes take one or more indices as arguments.  
An index specifies a particular element of the listbox, in any of 
the following ways:

=over

=item I<number>

Specifies the element as a numerical index, where 0 corresponds to the first 
element in the listbox.

=item B<active>

Indicates the element that has the location cursor.  This element will be 
displayed with a dashed-line frame border when the listbox has the keyboard 
focus, and it is specified with the B<activate> method.

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

In the method descriptions below, arguments named I<index>, I<first-index>, 
and I<last-index> always contain text indices in one of the above forms.

=head1 WIDGET METHODS

The B<HListbox> method creates a widget object.  This object supports the 
B<configure> and B<cget> methods described in L<Tk::options> which can be used 
to enquire and modify the options described above.  The widget also inherits 
all the methods provided by the generic L<Tk::Widget|Tk::Widget> class.

The following additional methods are available for HListbox widgets:

=over

=item I<$listbox>-E<gt>B<activate>(I<index>)

Sets the active element and the selection anchor to the one indicated 
by I<index>.  If I<index> is outside the range of elements in the listbox then 
the closest element is activated.  The active element is drawn similar to a 
"selected" element with a thin hashed border (similar to an underlined element 
in I<Tk::Listbox>, and its index may be retrieved with the index B<"active">.

NOTE:  Not supported by I<Tk::HList>.

=item I<$listbox>-E<gt>B<add>(I<$entryPath ?,option> => I<value, ...?index>)

Creates a new list entry with the pathname $entryPath. A list entry must be 
created after its parent is created (unless this entry is a top-level entry, 
which has no parent). See also "BUGS" below. This method returns the entryPath 
of the newly created list entry. The following configuration options can be 
given to configure the list entry:

=over

=item B<-at> => I<position>

Insert the new list at the position given by position. position must be a 
valid integer. The position 0 indicates the first position, 1 indicates 
the second position, and so on.

=item B<-after> => I<afterWhich>

Insert the new list entry after the entry identified by I<afterWhich>, 
which must be a valid list entry and it mush have the same parent as the 
new list entry.

=item B<-before> => I<beforeWhich>

Insert the new list entry before the entry identified by I<beforeWhich>, 
which must be a valid list entry and it mush have the same parent as the 
new list entry.

=item B<-data> => I<string>

Specifies a string to associate with this list entry.  This string can be 
queried by the info method. The application programmer can use the I<-data> 
option to associate the list entry with the data it represents.

=item B<-itemtype> => I<type>

Specifies the type of display item to be display for the new list entry.  
I<type> must be a valid display item type.  Currently the available 
display item types are imagetext, text, and $widget.  If this option is 
not specified, then by default the type specified by this HList widget's 
I<-itemtype> option is used.

=item B<-state> => I<state>

Specifies whether this entry can be selected or invoked by the user.  
Must be either normal or disabled.

=back

The I<add()> method accepts additional configuration options to configure the 
display item associated with this list entry.  The set of additional 
configuration options depends on the type of the display item given by the 
I<-itemtype> option.  Please see L<Tk::DItem> for a list of the configuration 
options for each of the display item types.  This method is associated with 
L<Tk::HList> and will accept strings as I<entryPath>s.  Unlike HList, 
entrypaths containing dots are not added as "children" because Tk::HListbox 
does not support "tree" lists (multi-level lists).

=item I<$listbox>-E<gt>B<bbox>(I<index>)

Returns a list of four numbers describing the bounding box of the text in the 
element given by I<index>.  The first two elements of the list give the x and 
y coordinates of the upper-left corner of the screen area covered by the text 
(specified in pixels relative to the widget) and the last two elements give 
the width and height of the area, in pixels.  If no part of the element given 
by I<index> is visible on the screen, or if I<index> refers to a non-existent 
element, then the result is an empty string;  if the element is partially 
visible, the result gives the full area of the element, including any parts 
that are not visible.

=item I<$listbox>-E<gt>B<curselection>

Returns a list containing the numerical indices of all of the elements in the 
HListbox that are currently selected.  If there are no elements selected in 
the listbox then an empty list is returned.  This method is the complement 
(opposite) of I<selectionSet()> in functionality.

NOTE:  Not supported by I<Tk::HList>.

=item I<$listbox>-E<gt>B<delete>(I<first-index, >?I<last-index>?)

Deletes one or more elements of the HListbox.  I<First-index> and I<last-index> 
are indices specifying the first and last elements in the range to delete.  
If I<last-index> isn't specified it defaults to I<first-index>, 
i.e. a single element is deleted.

=item I<$listbox>-E<gt>B<findIndex>(I<string>?)

Given the text of an entry, return the index of the first 
entry whose text matches the string, or I<<undef>> if no matches.

NOTE:  Not supported by I<Tk::Listbox>.

=item I<$listbox>-E<gt>B<fixListSize>(I<width>, I<height>)

Will fix the height and width of the B<HListbox>, caused by the underlying 
B<HList>, when non-default fonts are used.

The B<I<width>> and B<I<height>> values are the required character width and 
the number of rows in the listbox.

NOTE:  Not supported by I<Tk::HList> or I<Tk::Listbox>.

=item I<$listbox>-E<gt>B<fixPalette>()

Under certain situations, changing the color theme via 
$mainwin->setPalette(...) does not always update do to the myriad of 
subwidgets and color options supported.  Calling this method should fully 
update everything in the widget that have not been individually set by 
the user.  

=item I<$listbox>-E<gt>B<get>(I<first-index, >?I<last-index>?)

If I<last-index> is omitted, returns the contents of the listbox element 
indicated by I<first-index>, or an empty string if I<first-index> refers to a 
non-existent element.  If I<last-index> is specified, the command returns a 
list whose elements are all of the listbox elements between I<first-index> 
and I<last-index>, inclusive.  Both I<first-index> and I<last-index> may have 
any of the standard forms for indices.

=item I<$listbox>-E<gt>B<getEntry>(I<index>?)

Given an index, returns the HList "entry" value, only useful with 
lower-level HList functions.  Returns I<<undef>> if no matches.  
This method is the complement (opposite) of I<indexOf()> in functionality.

NOTE:  Not supported by I<Tk::HList> or I<Tk::Listbox>.

=item I<$listbox>-E<gt>B<getListHeight>(I<height>)

Will return the correct height in pixels, of the B<HListbox>, 
when a non-default B<-listfont> is used.

B<I<height>> is the required number of rows for the listbox.

NOTE:  Not supported by I<Tk::HList> or I<Tk::Listbox>.

=item I<$listbox>-E<gt>B<getListWidth>(I<width>)

Will return the correct width, in pixels, of the B<HListbox>, 
when a non-default B<-listfont> is used.

B<I<width>> is the required width in characters for the listbox.

NOTE:  Not supported by I<Tk::HList> or I<Tk::Listbox>.

=item I<$listbox>-E<gt>B<hide>([I<-entry> => ] I<index>)

Given an index, sets the entry to "hidden" so that it does not 
display in the listbox (but maintains it's index.  The "-entry" 
argument is unnecessary, but retained for Tk::HList compatability.

NOTE:  Not supported by I<Tk::Listbox>.

=item I<$listbox>-E<gt>B<show>([I<-entry> => ] I<index>)

Given an index, sets the entry to "not hidden" (the default) so 
that it is displayed in the listbox.

NOTE:  Not supported by I<Tk::Listbox>.

=item I<$listbox>-E<gt>B<index>(I<index>)

Returns the integer index value that corresponds to I<index>.  
If I<index> is B<end> the return value is a count of the number 
of elements in the listbox (not the index of the last element).  
If the index is out of range or invalid, I<undef> is returned.  
If the index is I<"end"> and the list is empty, I<-1> is returned.

=item I<$listbox>-E<gt>B<indexOf>(I<entry-path>)

Returns the integer index value that corresponds to I<entry-path>, 
or I<undef> if the I<entry-path> does not exist.  This method is 
the complement (opposite) of I<getEntry()> in functionality.

NOTE:  Not supported by I<Tk::HList> or I<Tk::Listbox>.

=item I<$listbox>-E<gt>B<insert>(I<index, >?I<element, element, ...>?)

Inserts zero or more new elements (entries) in the list just before the 
element given by I<index>.  If I<index> is specified as B<"end"> then the new 
elements are added to the end of the list.  Returns an empty string.  If the 
I<index> is not "end", the list will be automatically inserted in reverse 
order so that the entire list is inserted in the proper order before the 
element currently identified by the I<index>.

=item I<$listbox>-E<gt>B<item>(I<option, index, >?I<arg(s), ...>?)

Creates and configures the display items at individual columns the entries.  
The form of additional of arguments depends on the choice of option:

NOTE:  Not supported by I<Tk::Listbox>.

=over

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

=item I<$listbox>-E<gt>B<ItemStyle>(I<itemtype, >?I<option, value, ...>?)

HList method to create a display style for the I<-style> entry option.  
NOTE:  It's better to change most display properties by listing them 
and their values when inserting entries since any HListbox-wide style 
options specified when creating the HListbox widget, ie. I<-foreground>, 
etc. are NOT copied over into the style object.

=over

=item B<-background> =E<gt> I<color>

I<Color> specifies the background color to use when displaying the item.  
It may have any of the forms accepted by Tk_GetColor.

=item B<-foreground> =E<gt> I<color>

I<Color> specifies the foreground color to use when displaying the 
item. It may have any of the forms accepted by Tk_GetColor.  NOTE:  
may be returned as "-fg".

=item B<-selectbackground> =E<gt> I<color>

I<Color> specifies the background color to use when displaying the item while 
it is selected. It may have any of the forms accepted by Tk_GetColor.

=item B<-selectforeground> =E<gt> I<color>

I<Color> specifies the foreground color to use when displaying the item while 
it is selected. It may have any of the forms accepted by Tk_GetColor.

=back

=back

=item I<$listbox>-E<gt>B<nearest>(I<y>)

Given a y-coordinate within the listbox window, this command returns 
the index of the (visible) listbox element nearest to that y-coordinate.

NOTE:  Not supported by I<Tk::Listbox>.

=item $listbox-E<gt>nearestToIndex(I<index>)

Given a zero based B<I<index>> within the listbox window, this command returns 
the index of the (visible) listbox element nearest to the B<I<index>>.

If there is no visible bounding box associated with the 
zero-based B<I<index>>, then I<undef> is returned.

NOTE:  Not supported by I<Tk::HList> or I<Tk::Listbox>.

=item I<$listbox>-E<gt>B<scan>(I<option, >?I<arg(s), ...>?)

This command is used to implement scanning on listboxes.  It has two forms, 
depending on I<option>:

NOTE:  Not supported by I<Tk::HList>.

=over

=item I<$listbox>-E<gt>B<scanMark>(I<x, y>)

Records I<x> and I<y> and the current view in the listbox 
window;  used in conjunction with later B<scan dragto> commands.   
Typically this command is associated with a mouse button press in 
the widget.  It returns an empty string.

=item I<$listbox>-E<gt>B<scanDragto>(I<x, y>)

This command computes the difference between its I<x> and I<y> arguments and 
the I<x> and I<y> arguments to the last B<scan mark> command for the widget.  
It then adjusts the view by 10 times the difference in coordinates.  
This command is typically associated with mouse motion events in the widget, 
to produce the effect of dragging the list at high speed through the window.  
The return value is an empty string.

=back

=item I<$listbox>-E<gt>B<see>(I<index>)

Adjust the view in the HListbox so that the element given by I<index> 
is visible.  If the element is already visible then the command has no effect; 
if the element is near one edge of the window then the listbox scrolls to 
bring the element into view at the edge; otherwise the listbox scrolls to 
center the element.

=item I<$listbox>-E<gt>B<selection>(I<option, >?I<arg(s), ...>?)

This command is used to adjust the selection within a listbox.  It has several 
forms, depending on I<option>:

=over

=item I<$listbox>-E<gt>B<selectionAnchor>(I<index>)

Sets the selection anchor to the element given by I<index>.  
If I<index> refers to a non-existent element, then the closest 
element is used.  The selection anchor is the end of the selection that is 
fixed while dragging out a selection with the mouse.  The index B<anchor> 
may be used to refer to the anchor element.

=item I<$listbox>-E<gt>B<selectionClear>(I<first-index, >?I<last-index>?)

If any of the elements between I<first-index> and I<last-index> 
(inclusive) are selected, they are deselected.  The selection state is not 
changed for elements outside this range.  

=item I<$listbox>-E<gt>B<selectionGet>

NOTE:  Not recommended, nor supported by I<Tk::Listbox>.

Returns a list containing the actual I<elements> of all of the elements in 
the HListbox that are currently selected.  If there are no elements selected 
in the listbox then an empty list is returned.  NOTE:  The opposite method 
of this (I<selectionSet()>) is called with I<indices>.  Reason is that 
I<selectionGet> is not supported by L<Tk::Listbox>, but is a direct call to 
the corresponding method in L<Tk::HList>.

The recommended method for fetching back the indicies selected 
(either by the user or by I<selectionSet()>) is to call the 
I<curselection()> method provided both here and in I<Tk::Listbox>.

=item I<$listbox>-E<gt>B<selectionIncludes>(I<index>)

Returns 1 (true) if the element indicated by I<index> is currently selected, 
0 (false) if it isn't.

The recommended method for fetching back the indicies selected 
(either by the user or by I<selectionSet()>) is to call the 
I<curselection()> method provided both here and in I<Tk::Listbox>.

=item I<$listbox>-E<gt>B<selectionSet>(I<first-index, >?I<last-index>?)

Selects all of the elements in the range between 
I<first-index> and I<last-index>, inclusive, without affecting 
the selection state of elements outside that range.  This is the complement 
(opposite) of I<curselection()> in functionality.

NOTE:  Prior to v2.7, if more than two indices were passed 
to I<selectionSet()>, then the element of each index in the list 
would be selected.  Starting with v2.7, the list is limited to 
one or two indices (as is the case with both I<Tk::Listbox> and 
I<Tk::HList>).  Two indices represents a range, causing all elements 
with indices between the two specified (inclusive) being selected.

=back

=item I<$listbox>-E<gt>B<size>

Returns a decimal string indicating the total number of elements in 
the listbox.

=item I<$listbox>-E<gt>B<xview>(I<option, >?I<arg(s), ...>?)

This command is used to query and change the horizontal position of the 
information in the widget's window.  It can take any of the 
following forms:

=over

=item I<$listbox>-E<gt>B<xview>

Returns a list containing two elements.  Each element is a real fraction 
between 0 and 1;  together they describe the horizontal span that is visible 
in the window.  For example, if the first element is .2 and the second element 
is .6, 20% of the listbox's text is off-screen to the left, the middle 40% is 
visible in the window, and 40% of the text is off-screen to the right.  These 
are the same values passed to scrollbars via the B<-xscrollcommand> option.

=item I<$listbox>-E<gt>B<xview>(I<index>)

Adjusts the view in the window so that the character position given by 
I<index> is displayed at the left edge of the window.  
Character positions are defined by the width of the character B<0>.

=item I<$listbox>-E<gt>B<xviewMoveto>(I<fraction>);

Adjusts the view in the window so that I<fraction> of the 
total width of the listbox text is off-screen to the left.  
I<fraction> must be a fraction between 0 and 1.

=item I<$listbox>-E<gt>B<xviewScroll>(I<number, what>);

This command shifts the view in the window left or right according to 
I<number> and I<what>.  I<Number> must be an integer.  I<What> must be either 
B<units> or B<pages> or an abbreviation of one of these.  If I<what> is 
B<units>, the view adjusts left or right by I<number> character units 
(the width of the B<0> character) on the display;  if it is B<pages> then the 
view adjusts by I<number> screenfuls.  If I<number> is negative then 
characters farther to the left become visible;  if it is positive then 
characters farther to the right become visible.

=back

=item I<$listbox>-E<gt>B<yview>(I<option, >?I<arg(s), ...>?)

This command is used to query and change the vertical position of the 
text in the widget's window.  It can take any of the following forms:

=over

=item I<$listbox>-E<gt>B<yview>

Returns a list containing two elements, both of which are real fractions 
between 0 and 1.  The first element gives the position of the listbox element 
at the top of the window, relative to the listbox as a whole (0.5 means it is 
halfway through the listbox, for example).  The second element gives the 
position of the listbox element just after the last one in the window, 
relative to the listbox as a whole.  These are the same values passed to 
scrollbars via the B<-yscrollcommand> option.

=item I<$listbox>-E<gt>B<yview>(I<index>)

Adjusts the view in the window so that the element given by 
I<index> is displayed at the top of the window.

=item I<$listbox>-E<gt>B<yviewMoveto>(I<fraction>);

Adjusts the view in the window so that the element given by I<fraction> 
appears at the top of the window.  I<Fraction> is a fraction between 0 and 1; 
0 indicates the first element in the listbox, 0.33 indicates the element 
one-third the way through the listbox, and so on.

=item I<$listbox>-E<gt>B<yviewScroll>(I<number, what>);

This command adjusts the view in the window up or down according to I<number> 
and I<what>.  I<Number> must be an integer.  I<What> must be either B<units> 
or B<pages>.  If I<what> is B<units>, the view adjusts up or down by I<number> 
lines; if it is B<pages> then the view adjusts by I<number> screenfuls.  
If I<number> is negative then earlier elements become visible;  if it is 
positive then later elements become visible.

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

=over

=item [1]

In B<extended> mode, the selected range can be adjusted by pressing 
button 1 with the Shift key down:  this modifies the selection to 
consist of the elements between the anchor and the element under 
the mouse, inclusive.  The un-anchored end of this new selection can 
also be dragged with the button down.

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
deselected.  In B<extended> mode the new active element becomes the 
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

=over

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
for instance:

    my @list = ( "a", "b", "c", "d", "e", "f" );
    $lbox->insert('end', sort @list );
    $lbox->selectionSet(1);

inserts @list as elements in an already existing listbox and selects the 
element at index 1, which is "b". If we then:

     print @$selected;

this will return the currently selected elements, in this case "b".

However, if the "ReturnType" argument is passed when tying the HListbox to the 
scalar with value "index" then the indices of the selected elements will be 
returned instead of the elements themselves, ie in this case "1". This can be 
useful when manipulating both contents and selected elements in the HListbox 
at the same time.

Importantly, if a value "both" is given the scalar will not be tied to an 
array, but instead to a hash, with keys being the indices and values being 
the elements at those indices.

You can also manipulate the selected items using the scalar. Equating the 
scalar to an array reference will select any elements that match elements 
in the HListbox, non-matching array items are ignored, e.g. 

    my @list = ( "a", "b", "c", "d", "e", "f" );
    $lbox->insert('end', sort @list );
    $lbox->selectionSet(1);

would insert the array @list into an already existing HListbox and select 
element at index 1, i.e. "b":

    @array = ( "a", "b", "f" );
    $selected = \@array;

would select elements "a", "b" and "f" in the HListbox.

Again, if the "index" we indicate we want to use indices in the options hash 
then the indices are use instead of elements, e.g.

    @array = ( 0, 1, 5 );
    $selected = \@array;

would have the same effect, selecting elements "a", "b" and "f" if the 
$selected variable was tied with %options = ( ReturnType => "index" ).

If we are returning "both", i.e. the tied scalar points to a hash, both key 
and value must match, e.g.

    %hash = ( 0 => "a", 1 => "b", 5 => "f" );
    $selected = \%hash;

would have the same effect as the previous examples.

It should be noted that, despite being a reference to an array (or possibly 
a hash), you still can not copy the tied variable without it being untied, 
instead you must pass a reference to the tied scalar between subroutines.

=back

=head1 AUTHOR

Jim Turner, C<< <https://metacpan.org/author/TURNERJW> >>.

=head1 COPYRIGHT

Copyright (c) 2015-2023 Jim Turner C<< <mailto://turnerjw784@yahoo.com> >>.
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
use strict;
use warnings;
use POSIX qw(ceil);
use Carp;
use Tk;
use Tk::ItemStyle;
use base qw(Tk::Derived Tk::HList);
use vars qw($VERSION $DEFAULTFONT);
$VERSION = '3.00';

Tk::Widget->Construct('HListbox');

my $bummer = ($^O =~ /MSWin/) ? 1 : 0;   #Bummer if you're stuck running M$-Windows! ;)
my $JWTLISTBOXHACK = defined($ENV{jwtlistboxhack}) ? $ENV{jwtlistboxhack} : 0;
$DEFAULTFONT = $bummer ? '{MS Sans Serif} 8' : 'Helvetica -12 bold';  # ADDED 2.301 by Jeff Stephens

sub ClassInit
{
	my ($class,$mw) = @_;

	$class->SUPER::ClassInit($mw);
 # Standard Motif bindings:

# $mw->bind($class, '<Double-1>' => \&Tk::NoOp);
	$mw->bind($class,'<Double-1>' => ['DoubleButton1',Ev('index',Ev('@'))]);
	$mw->bind($class,'<B1-Motion>',['Motion',Ev('index',Ev('@'))]);
	$mw->bind($class,'<Alt-ButtonRelease-1>',['jwtAltButtonRelease_1', Ev('index',Ev('@'))]);
	$mw->bind($class,'<ButtonRelease-1>','ButtonRelease_1');
	$mw->bind($class,'<Shift-1>',['ShiftButton1',Ev('index',Ev('@'))]);  #JWT:ADDED 20091020!
	$mw->bind($class,'<Control-ButtonPress-1>',['BeginToggle',Ev('index',Ev('@'))]);
	$mw->bind($class,'<ButtonPress-1>',['ButtonPress_1', Ev('index',Ev('@'))]);
	$mw->bind($class,'<B1-Leave>',['AutoScan',Ev('x'),Ev('y')]);
	$mw->bind($class,'<B1-Enter>','CancelRepeat');
	$mw->bind($class,'<Up>',['UpDown',-1]);
	$mw->bind($class,'<Shift-Up>',['ShiftUpDown',-1]);
	$mw->bind($class,'<Down>',['UpDown',1]);
	$mw->bind($class,'<Shift-Down>',['ShiftUpDown',1]);
	$mw->XscrollBind($class);
	$mw->bind($class, '<Control-Prior>', ['CtrlPriorNext',-1]);  #JWT:DIFFERENT FROM Listbox!:
	$mw->bind($class, '<Control-Next>', ['CtrlPriorNext',1]);
 # <Home> and <End> defined in XscrollBind
	$mw->bind($class, '<Control-Home>','Cntrl_Home');
	$mw->bind($class,'<Shift-Control-Home>',['DataExtend',0]);
	$mw->bind($class, '<Control-End>','Cntrl_End');
	$mw->bind($class,'<Shift-Control-End>',['DataExtend','end']);
	$mw->bind($class,'<space>',['SpaceSelect',Ev('index','active')]);
	$mw->bind($class,'<Select>',['BeginSelect',Ev('index','active')]);

 # Additional Tk bindings that aren't part of the Motif look and feel:
	if ($JWTLISTBOXHACK) {
		$mw->bind($class,'<Shift-space>',['ShiftSpace',Ev('index','active')]);  #JWT:ADDED 20091020!
		$mw->bind($class,'<Alt-space>',['jwtAltSpace',Ev('index','active')]);  #JWT:ADDED 20091020!
		$mw->bind($class,'<plus>',['KeyboardToggleIndicator','<Activate>',Ev('index','active')]);
		$mw->bind($class,'<minus>',['KeyboardToggleIndicator','<Disarm>',Ev('index','active')]);
	}
	$mw->bind($class,'<Shift-Select>',['BeginExtend',Ev('index','active')]);  #JWT:ADDED 20091020!
	$mw->bind($class, '<Escape>', 'Cancel');
	$mw->bind($class, '<Control-slash>','SelectAll');
	$mw->bind($class, '<Control-backslash>','Cntrl_backslash');
	$mw->bind($class,'<2>',['scan','mark',Ev('x'),Ev('y')]);
	$mw->bind($class,'<B2-Motion>',['scan','dragto',Ev('x'),Ev('y')]);
	$mw->bind($class,'<Return>', ['InvokeCommand']);
	$mw->bind($class,'<FocusIn>','focus');
	$mw->bind($class,'<FocusOut>','unfocus');
	$mw->MouseWheelBind($class); # XXX Both needed?
	$mw->YMouseWheelBind($class);

	return $class; 
}

sub Populate {
	my ($w, $args) = @_;

	#NOTE:  Tk::Scrolled ALSO EATS -width, -height, and -highlightthickness, -takefocus, AND POSSIBLY OTHERS!
	#SO THAT THOSE ARGS DO *NOT* APPEAR IN THE $args HASH HERE!:
	$w->toplevel->bind('<<setPalette>>' => [$w => 'fixPalette']);
	$w->{Configure}{-font}  = defined($args->{-font}) ? $args->{-font} : $DEFAULTFONT;                           # ADDED 2.301
	$w->{Configure}{-state} = defined $args->{-state} ? $args->{-state} : 'normal';
	$args->{'-showcursoralways'} = 0  unless (defined $args->{'-showcursoralways'});
	$w->{'-showcursoralways'} = $args->{'-showcursoralways'};

	$w->SUPER::Populate($args);

	$w->ConfigSpecs(
			-background    => [qw/METHOD background Background/, undef],
			-foreground    => [qw/METHOD foreground Foreground/, undef],
			-activeforeground => [qw/METHOD activeForeground ActiveForeground/, undef],
			-selectforeground => [qw/METHOD selectForeground SelectForeground/, undef],
			-disabledforeground => [qw/PASSIVE disabledForeground DisabledForeground/, undef],
			#HList's DEFAULT HIGHLIGHTTHICKNESS IS 2, WE WANT IT 1 (LIKE Listbox) FOR PROPER ALIGNMENT!:
			-highlightthickness => [['SELF', 'DESCENDANTS'], qw/highlightThickness HighlightThickness/, 1],
			-updatecommand => ['CALLBACK'],
			-xscancommand  => ['CALLBACK'],
			-parent        => [qw/SELF parent parent/, undef],
			-itemtype      => [qw/PASSIVE itemType ItemType text/],
			-ipadx         => [qw/PASSIVE/],
			-ipady         => [qw/PASSIVE/],
			-tpadx         => [qw/PASSIVE/],
			-tpady         => [qw/PASSIVE/],
			-gap           => [qw/PASSIVE/],    #added by Jeff Stephens.
			-indicatorcmd  => ['CALLBACK'],
			-activestyle   => [qw/PASSIVE activeStyle ActiveStyle underline/],  #CURRENTLY IGNORED.
			-listvariable  => [qw/PASSIVE listVariable Variable/, undef],
			-state         => ['METHOD',  'state', 				'State', 'normal'],
			-font          => [qw/METHOD  font         Font/,   $DEFAULTFONT],
			-showcursoralways => [qw/PASSIVE showcursoralways showcursoralways/, 0],
			-takefocus     => ['METHOD', 'takeFocus', 'TakeFocus', ''],  #JWT:MUST BE METHOD SINCE SCROLLED EATS IT OTHERWISE!
			-Prev          => [qw/PASSIVE/],
			-Selection     => [qw/PASSIVE/],
	);

	my $Palette = $w->Palette;
	foreach my $tp (qw/text image imagetext/) {   #CREATE "DEFAULT" STYLES FOR EACH itemtype:
		$w->{"_style$tp"} = $w->ItemStyle($tp);
		$w->{"_style$tp"}->configure('-activebackground' => $Palette->{'background'})  if (defined $Palette->{'background'});
		$w->{"_style$tp"}->configure('-font' => $w->{Configure}{'-font'})  if ($tp ne 'image');
		if ($tp eq 'text') {
			$w->{"_style$tp"}->configure('-pady' => $args->{'-tpady'})  if (defined $args->{'-tpady'});
			$w->{"_style$tp"}->configure('-padx' => $args->{'-tpadx'})  if (defined $args->{'-tpadx'});
		} else {
			$w->{"_style$tp"}->configure('-pady' => $args->{'-ipady'})  if (defined $args->{'-ipady'});
			$w->{"_style$tp"}->configure('-padx' => $args->{'-ipadx'})  if (defined $args->{'-ipadx'});
			$w->{"_style$tp"}->configure('-gap'  => $args->{'-gap'})    if (defined($args->{'-gap'}) && $tp eq 'imagetext');
		}
	}
	$w->{'_lastactive'} = 0; #SAVE "active" INDEX (SINCE WE MAY CLEAR HList'S "anchor" THUS LOSING "active")!
	$w->{'_hasfocus'} = 0;   #TRUE IF WIDGET CURRENTLY HAS KEYBOARD FOCUS.
	$w->{'_ourtakefocus'} = (defined $args->{'-takefocus'}) ? $args->{'-takefocus'} : '';  #NOTE:  Scrolled EATS THIS!

	#EMULATE "-listvariable" USING THE TIE FEATURE:
	if (defined($args->{-listvariable}) && ref($args->{-listvariable})) {
		#MUST INITIALIZE MANUALLY IF WE ALREADY HAVE ELEMENTS (B/C Tk::Listbox DOES!):
		my @initlist = @{$args->{-listvariable}};
		#JWT:THE ONLY WAY WE CAN HANDLE ANY INITIAL VALUES (BEFORE TYING) IS TO SAVE THEM, EMPTY THE ARRAY
		#TO BE TIED, TIE IT, *THEN* RESET IT TO THE INITIAL VALUES, OTHERWISE, THEY DON'T GET ADDED:
		@{$args->{-listvariable}} = ()  if ($#initlist >= 0);
		tie @{$args->{-listvariable}}, 'Tk::HListbox', $w, (ReturnType => 'index');
		@{$args->{-listvariable}} = @initlist  if ($#initlist >= 0);
	}
	$w->{'_xmark'} = 0;      #USED BY ->scan('mark') FUNCTION TO SAVE COORDS:
	$w->{'_ymark'} = 0;
	$w->{'_rowWidth'}	= 0;   #USED BY HACKED ->*view() FUNCTIONS!
	$w->{'_rowHeight'} = 0;  #USED BY HACKED ->*view() FUNCTIONS!
}

sub fixPalette {     #WITH OUR setPalette, WE CAN CATCH PALETTE CHANGES AND ADJUST EVERYTHING ACCORDINGLY!:
	my $w = shift;   #WE STILL PROVIDE THIS AS A USER-CALLABLE METHOD FOR THOSE WHO ARE NOT.
	my $Palette = $w->Palette;

	$w->configure('-background' => $Palette->{'background'});
	$w->configure('-foreground' => $Palette->{'foreground'});
}

sub background {
	my $w = shift;
	my $val = shift;

	# CGET
	return $w->{Configure}{'-background'}  unless (defined($val) && $val);

	# CONFIGURE
	my $dfltBG = $w->toplevel->cget('-background');
	my $force = shift || 0;
	#ALLOW BACKGROUND CHANGE IF FORCE OR VALUE APPEARS TO BE USER-SET:
	$w->{'_backgroundset'} = 0  if ($force || $val !~ /^${dfltBG}$/i);
	## Ensure that the base Frame, pane and columns (if any) get set
	unless ($w->{'_backgroundset'}) {
		Tk::configure($w, "-background", $val);
		foreach my $tp (qw/text image imagetext/) {
			$w->{"_style$tp"}->configure('-background' => $val, '-activebackground' => $val);
		}
		$w->{'_backgroundset'} = 1  unless ($w->{'_statechg'} || $val =~ /^${dfltBG}$/i);
	}
}

#PBM. IS THAT IF USER SETS A CUSTOM COLOR, WE WANT TO KEEP THAT THRU BOTH STATE AND PALETTE CHANGES,
#OTHERWISE, WE WANT TO PROPERLY CHANGE WHEN EITHER STATE OR PALETTE CHANGES, EVEN IF PALETTE CHANGES
#WHILE THE STATE IS DISABLED!:
sub foreground {   #THIS CODE IS UGLY AS CRAP, BUT NECESSARY TO ACTUALLY WORK:
	my $w = shift;
	my $val = shift;

	# CGET
	return $w->{Configure}{'-foreground'}  unless (defined($val) && $val);

	# CONFIGURE
	my $dfltFG = $w->toplevel->cget('-foreground');
	my $force = shift || 0;
	#ALLOW FOREGROUND CHANGE IF FORCE OR VALUE APPEARS TO BE USER-SET:
	my $palettechg = ($val =~ /^${dfltFG}$/i) ? 1 : 0;
	my $disabled = (defined($w->{Configure}{'-state'}) && $w->{Configure}{'-state'} =~ /d/o) ? 1 : 0;
	my $allowed = 0;
	if ($force || $w->{'_statechg'}) {  #ALWAYS ALLOW FORCE OR STATE-CHANGE TO SET FG:
		$allowed = 1;   #IF FORCE OR WE'RE CHANGING "STATE" (ie. "normal" to "disabled"):
	} elsif ($w->{'_foregroundset'}) {  #USER SPECIFIED A SPECIFIC FG COLOR.
		$allowed = 1  unless ($palettechg);  #FROZEN, ALLOW USER BUT NOT setPalette TO CHANGE:
	} elsif ($disabled) {
		$allowed = 1    #NOT FROZEN, ALLOW setPalette OR DISABLED STATE TO SET FG:
	} elsif (!$w->{'_foregroundset'}) {  #ALLOW CHANGE SINCE USER HASN'T SPECIFIED A COLOR:
		$allowed = 1
	}
	## Ensure that the base Frame, pane and columns (if any) get set
	if ($allowed) {   #FG ALLOWED TO BE CHANGED:
		if ($disabled) {  #FORCE TO DISABLED FG, IF DISABLED:
			my $Palette = $w->Palette;
			$w->{'_foreground'} = $val  if ($w->{'_statechg'} eq '0');  #STATE CHANGED TO DIABLED BEFORE INITIALIZATION, SO SAVE USER-SPECIFIED ("normal") COLOR:
			unless ($w->{'_foreground'}) {  #NO "normal" COLOR SAVED YET, SAVE USER'S FG IF SPECIFIED, OR THE PALETTE'S COLOR:
				$w->{'_foreground'} = $w->{'_foregroundset'} || $Palette->{'foreground'};  #NEED TO GET IT HERE, SINCE STARTED DISABLED & WE DIDN'T HAVE IT YET!
			}
			$val = $w->cget('-disabledforeground') || $Palette->{'disabledForeground'};  #NOW SWITCH TO THE PALETTE'S "DISABLED" FG COLOR.
		}
		Tk::configure($w, "-foreground", $val);
		$w->{Configure}{'-foreground'} = $val;
		foreach my $tp (qw/text image imagetext/) {
			$w->{"_style$tp"}->configure('-foreground' => $val);
		}
		#WE MUST CONSIDER UPDATING ACTIVE AND SELECT FOREGROUND IF CHANGING STATES OR PALETTES:
		$w->{'_propogateFG'} = 1;
		$w->configure('-activeforeground' => $val)  if ($w->{'_statechg'} || !$w->{'_activeforegroundset'});
#UNCOMMENT TO USE USER-S FOREGROUND COLOR FOR SELECT FG TOO:		$w->configure('-selectforeground' => $val)  if ($w->{'_statechg'} || !$w->{'_selectforegroundset'});
		$w->{'_propogateFG'} = 0;

		#FREEZE (SAVE) THE FG (IF ENABLED AND SET BY USER, NOT PALETTE & NOT CHANGING "STATE"):
		$w->{'_foregroundset'} = $val  if (!$disabled && !$palettechg && !$w->{'_statechg'});
	} else {   #NOT ALLOWED TO BE CHANGED: MUST RESET TO "FROZEN" FG, SINCE TK'S ALREADY "CHANGED" IT INTERNALLY:
		if ($w->{'_foregroundset'}) {
			Tk::configure($w, "-foreground", $w->{'_foregroundset'});
			$w->{Configure}{'-foreground'} = $w->{'_foregroundset'};
		} elsif ($palettechg && $disabled) {  #IF WE'RE NOT "FROZEN" AND WE'RE DISABLED, SAVE NEW PALLETTE-SET FG FOR RESTORATION WHEN ENABLED:
			$w->{'_foreground'} = $val;
		}
	}
}

sub selectforeground {
	my ($w, $val) = @_;

	# CGET
	return $w->{Configure}{'-selectforeground'}  unless (defined($val) && $val);

	# CONFIGURE
	my $dfltFG = $w->toplevel->cget('-foreground');
	my $palettechg = ($val =~ /^${dfltFG}$/i) ? 1 : 0;
	my $disabled = (defined($w->{Configure}{'-state'}) && $w->{Configure}{'-state'} =~ /d/o) ? 1 : 0;
	my $allowed = 0;
	if ($w->{'_selectforegroundset'}) {
		$allowed = 1  unless ($w->{'_propogateFG'} || $palettechg);  #FROZEN, ALLOW USER, BUT NOT setPalette TO CHANGE:
	} else {
		$allowed = 1;    #NOT FROZEN, ALLOW setPalette IF ENABLED:
	}
	if ($allowed) {
		Tk::configure($w, "-selectforeground", $val);
		$w->{Configure}{'-selectforeground'} = $val;
		foreach my $tp (qw/text image imagetext/) {
			$w->{"_style$tp"}->configure('-selectforeground' => $val);
		}
		$w->{'_selectforegroundset'} = $val  unless ($disabled || $palettechg
				|| $w->{'_statechg'} || $w->{'_propogateFG'});
	} else {   #NOT ALLOWED TO BE CHANGED: MUST RESET TO "FROZEN" FG, SINCE TK'S ALREADY "CHANGED" IT INTERNALLY:
		Tk::configure($w, "-selectforeground", $w->{'_selectforegroundset'})
				if ($w->{'_selectforegroundset'});
	}
}

sub activeforeground {
	my ($w, $val) = @_;

	# CGET
	return $w->{Configure}{'-activeforeground'}  unless (defined($val) && $val);

	# CONFIGURE
	my $dfltFG = $w->toplevel->cget('-foreground');
	my $palettechg = ($val =~ /^${dfltFG}$/i) ? 1 : 0;
	my $disabled = (defined($w->{Configure}{'-state'}) && $w->{Configure}{'-state'} =~ /d/o) ? 1 : 0;
	my $allowed = 0;
	if ($w->{'_activeforegroundset'}) {
		$allowed = 1  unless ($w->{'_propogateFG'} || $palettechg);  #FROZEN, ALLOW USER, BUT NOT setPalette TO CHANGE:
	} else {
		$allowed = 1;    #NOT FROZEN, ALLOW setPalette IF ENABLED:
	}
	if ($allowed) {
		$w->{Configure}{'-activeforeground'} = $val;
		foreach my $tp (qw/text image imagetext/) {
			$w->{"_style$tp"}->configure('-activeforeground' => $val);
		}
		$w->{'_activeforegroundset'} = $val  unless ($disabled || $palettechg
				|| $w->{'_statechg'} || $w->{'_propogateFG'});
	} else {   #NOT ALLOWED TO BE CHANGED: MUST RESET TO "FROZEN" FG, SINCE TK'S ALREADY "CHANGED" IT INTERNALLY:
		Tk::configure($w, "-activeforeground", $w->{'_activeforegroundset'})
				if ($w->{'_activeforegroundset'});
	}
}

sub font {  #SINCE WE CREATE "DEFAULT" STYLES FOR FG/BG PURPOSES, WE MUST SET THE FONT THERE TOO!:
	my ($w, $val) = @_;

	# CGET
	return $w->{Configure}{'-font'} || undef  unless (defined($val) && $val);

	# CONFIGURE
	$w->{Configure}{'-font'} = $val;
	foreach my $tp (qw/text imagetext/) {
		$w->{"_style$tp"}->configure('-font' => $val);
	}
}

sub state {  #SINCE HList DOESN'T SUPPORT STATES (NORMAL, DISABLED), WE MUST HANDLE IT MANUALLY:
	my ($w, $val) = @_;

	# CGET
	return $w->{Configure}{'-state'} || undef  unless (defined($val) && $val);

	#THE STUPID HList WIDGET IS BROKEN: WON'T TAKE STATE CHANGE?!  $w->Tk::HList::configure('-state' => $val);
	#SO WE HAVE TO "EMULATE" IT OURSELVES MANUALLY - GRRRRRRRR!:
	return  if (defined($w->{'_prevstate'}) && $val eq $w->{'_prevstate'});  #DON'T DO TWICE IN A ROW!

	# CONFIGURE
	$w->{'_statechg'} = 1;
	if ($val =~ /d/o) {               #WE'RE DISABLING (SAVE CURRENT ENABLED STATUS STUFF, THEN DISABLE USER-INTERACTION):
		my $Palette = $w->Palette;

		$w->{Configure}{'-state'} = 'normal';
		$w->{'_saveactive'} = $w->index('active');
		@{$w->{'_savesel'}} = $w->curselection;   #SAVE & CLEAR THE CURRENT SELECTION, FOCUS STATUS & COLORS:
		$w->selectionClear(0, 'end');
		$w->{'_foreground'} = $w->foreground;
		$w->{Configure}{'-state'} = $val;
		$w->foreground($w->cget('-disabledforeground') || $Palette->{'disabledForeground'});
		$w->focusNext  if ($w->{'_hasfocus'});  #MOVE FOCUS OFF WIDGET IF IT HAS IT.
		$w->takefocus(0, 1);  #MOVE FOCUS OFF HListbox IF FOCUSED, SINCE DISABLING (SEE NOTE BELOW THOUGH)!
		#NOTE:  THIS DIFFERS FROM Tk::Listbox BEHAVIOUR, AS Tk::Listbox WILL STILL TAKE FOCUS IN THE
		#TAB-CIRCULATE ORDER EVEN IF DISABLED, IF -takefocus IS SET TO 1!:
	} elsif ($w->{'_prevstate'}) {    #WE'RE ENABLING (RESTORE PREV. ENABLED STUFF AND REALLOW USER-INTERACTION):
		$w->{Configure}{'-state'} = $val;
		if (ref $w->{'_savesel'}) {   #RESTORE SELECTED LIST.
			$w->selectionSet(shift @{$w->{'_savesel'}})  while (@{$w->{'_savesel'}});
		}
		$w->activate($w->{'_saveactive'});
		my $colr = 'foreground';
		my $fg = $w->{'_foreground'};
		$fg ||= $w->toplevel->cget('-foreground') || $w->toplevel->Palette->{'foreground'};
		$w->configure('-foreground' => $fg)  if ($fg);  #RESTORE FG COLOR.
		$w->takefocus($w->{'_ourtakefocus'}, 1);
	}
	$w->{'_prevstate'} = $w->{Configure}{'-state'};
	$w->{'_statechg'} = 0;
}

sub takefocus {
	my ($w, $val, $byus) = @_;
	return $w->{Configure}{'-takefocus'}  unless (defined $val);

	#JWT:NEEDS TO BE '' INSTEAD OF 1 FOR Tk (SO WE KEEP IT IN OUR OWN VARIABLE FOR OUR USE)!:
	$w->{'_ourtakefocus'} = $val  unless (defined $byus);
	$w->{Configure}{'-takefocus'} = ($val =~ /0/o) ? 0 : '';
}

# HListbox::selection options: clear     includes set   NOTE: need to add option='get' to POD documentation.
#                                                             need to move selection('anchor',...) POD documentation to selectionAnchor.
# HList::selection    options: clear get includes set

# SYNTAX for HList::selection($option, arg, ?arg?)
#           selection('clear', ?first?, ?last?)
#           selection('get', selection)    # is an alias for infoSelection
#           selection('includes', index)
#           selection('set', first, ?last?)
# NOTE: There is no option='anchor' support privided by method HList::selection('anchor', index)

# HListbox does provide the following selection related methods:
#           selectionAnchor(index)            NOTE: There is no option='anchor' support using this syntax: HList::selection('anchor', index)
#           selectionClear(?first?, ?last?)
#           selectionIncludes(index)
#           selectionSet($first, ?last?)
sub selection {
	my ($w, $opt, @args) = @_;

	# check for valid option name:
	croak "Invalid Tk::HListbox selection() option '$opt'\n  Valid options: ['clear'|'get'|'includes'|'set']\n"
			unless (defined($opt) && $opt =~ /^(?:get|set|clear|includes)$/io);

	# create entryPaths for each argument
	my @entrypaths = ();
	foreach my $arg (@args) {
		my $entrypath = $w->getEntry($arg);
		push @entrypaths, $entrypath  if (defined $entrypath);
	}

	return $w->Tk::HList::selection($opt, @entrypaths);
}

sub selectionSet {
	my ($w) = shift;

	return  unless (defined($_[0]) && $_[0] =~ /\S/o);

	my @args = ();
	$args[0] = $w->index($_[0]);
	if (defined($_[1]) && $_[1] =~ /\S/o) {
		if (defined $_[2]) {
			carp "e:HListbox.selectionSet() called with >2 arguments, 3rd=$_[2], no new selections set!";
			return;
		}
		$args[1] = $w->index($_[1]);
	}
	for (my $i=0;$i<=$#args;$i++) {
		unless (defined $args[$i]) {
			carp "e:HListbox.selectionSet() - Argument# ".($i+1)." ($args[$i]) is not a valid index, no new selections set!";
			return;
		}
	}

	#THE STUPID HList IS BROKEN - IT WILL SELECT ENTRIES THAT ARE DISABLED, SO WE HAVE TO FILTER 'EM OUT OURSELVES FIRST!: :(
	my @indexRange;
	if (defined $args[1]) {
		@indexRange = ($args[1] < $args[0]) ? reverse(@args) : @args;
	} else {
		@indexRange = ($args[0], $args[0]);
	}
	for (my $i=$indexRange[0];$i<=$indexRange[1];$i++) {
		my $ent = $w->getEntry($i);
		next  unless (defined($ent) && $ent =~ /\S/o);  #patch by Jeff Stephens to handle undef entryPaths.

		$w->Tk::HList::selectionSet($ent)  unless ($w->entrycget($ent, '-state') eq 'disabled' || $w->info('hidden', $ent));
	}
}

sub selectionClear {
	my ($w) = shift;
	my @range = @_;

# REMINDER of HList::selectionClear POD:
# When no extra arguments are given, deselects all of the list entrie(s) in this HList widget.
# When only from is given, only the list entry identified by from is deselected.
# When both from and to are given, deselects all of the list entrie(s) between between from and to, inclusive, without affecting the selection state of elements outside that range.

	#CONVERT (0[.0], 'end') => undef (NO ARGUMENT) FOR Tk::HList TO FORCE CLEAR OF ALL ELEMENTS:
	@range = ($#range == 1 && $range[0] =~ /^0(?:\.0)?$/o && $range[1] =~ /^end$/o)
			? () : $w->getEntryList(@range);
	$w->Tk::HList::selectionClear(@range);
}

sub anchorSet {  #HList's "anchor" is it's (active) cursor, so we use a "virtual anchor" for ours.
	my ($w) = shift;
	return  if ($w->{Configure}{'-state'} =~ /d/o);
	return  unless (defined($_[0]) && $_[0] =~ /\S/o);

	my $ent = $w->getEntry($_[0]);
	$w->{'_vanchor'} = (!defined($ent) || $w->entrycget($ent, '-state') eq 'disabled' || $w->info('hidden', $ent))
			? undef : $w->index($_[0]);
#BEHAVE MORE LIKE LISTBOX: #	$w->{'_lastactive'} = $w->index($_[0]);
}

sub anchorClear {
	$_[0]->{'_vanchor'} = undef;
}

sub selectionAnchor {  #SET THE SELECTION ANCHOR (Listbox's version of HList's "anchorSet" function:
	return  if (!defined($_[0]) || $_[0]->{Configure}{'-state'} =~ /d/o);

	$_[0]->anchorSet($_[1]);
}

#NOTE:  Tk::HList::anchorClear(*) disappears the cursor, BUT sets the "active" index to ZERO (which IS
#a LEGITIMATE ENTRY!!!  THEREFORE WHENEVER WE "activate" AN ENTRY, WE MUST SAVE IT AS "$w->{'_lastactive'}"!:
sub activate {    #HListbox "anchor" == Listbox "active"!
	my $w = shift;
	my @v = @_;
	return  unless (defined($v[0]) || $w->{'-showcursoralways'});

	my $ent = $w->getEntry($v[0]);
	return  unless (defined($ent) && $ent =~ /\S/o);

	unless ($w->entrycget($ent, '-state') eq 'disabled' || $w->info('hidden', $ent)) {
		if (defined $v[0]) {
			my $showcursor = $w->{'-showcursoralways'} || 0;
			$showcursor = 0  if ($showcursor < 0 && defined($v[1]) && $v[1] == 1);
			if ($showcursor || ($w->{'_hasfocus'} && $w->focusCurrent)) {
				$w->Tk::HList::anchorSet($ent);    #THIS SHOWS THE CURSOR
			} else {
				$w->Tk::HList::anchorSet($ent);    #THIS SHOWS THE CURSOR
				$w->Tk::HList::anchorClear($ent);  #THIS HIDES THE CURSOR
			}
			$w->{'_lastactive'} = $w->indexOf($ent);
		} else {
			$w->{'_lastactive'} = $w->index('active');
			$w->Tk::HList::anchorClear($w->{'_lastactive'});
		}
	}
}

sub curselection {
	my $v = $_[0]->info('selection');
	unless (defined $v) {
		return wantarray ? () : undef;
	}
	for (my $i=0;$i<=$#{$v};$i++) {
		$v->[$i] = $_[0]->indexOf($v->[$i]);
	}
	return wantarray ? @{$v} : $v
}

sub see {
	my $w = shift;
	my $entry = $w->getEntry($_[0]);

	# REMINDER of HList::see POD:
	# Adjust the view in the HList so that the entry given by $entryPath is visible.
	# If the entry is already visible then the method has no effect;
	# if the entry is near one edge of the window then the HList scrolls to bring the element into view at the edge; otherwise the HList widget scrolls to center the entry.
	$w->Tk::HList::see($entry)  if (defined $entry);
}

#PROGRAMMER NOTE:  THE *view FNS ARE VERY *HACKED* B/C HList'S VSNS RETURN PIXELS INSTEAD OF {0..1} AS
#THE DOCS SAY *AND* WE CAN ONLY APPROXIMATE (FOR xview) WHAT THE MAX PIXEL VALUE IS FOR CALCULATING THE
#RATIO!  FOR yview, WE MUST CALC. THE HEIGHT IN PIXELS OF A SPECIFIC ROW (ALL ROWS SHOULD BE SAME HEIGHT):
sub xview {
	my $w = shift;

	if (!defined $_[0]) {
		if ($w->size > 0) {
			my @v = $w->Tk::HList::xview;
			my $lb_width_approx = defined($w->Subwidget('scrolled'))
					? $w->Subwidget('scrolled')->width : $w->width;
			$lb_width_approx -= (2 * $w->cget('-borderwidth') + 2 * $w->cget('-highlightthickness'));
			#NOTE:  rowWidth IS A ROUGH-ESTIMATE (FIXME: IDK HOW TO FIND THE EXACT WIDTH Tk IS USING)!
			$w->{'_rowWidth'} ||= $w->_getwidth($w->cget('-width'), 'pixels');
			$lb_width_approx = $w->{'_rowWidth'}  if ($lb_width_approx > $w->{'_rowWidth'});
			$v[1] = ($lb_width_approx + $v[0]) / $w->{'_rowWidth'};  #PIXELS => APPROX. (ESTIMATED) RATIO.
			$v[1] = 1  if ($v[1] > 1.0);  #DUE TO ESTIMATION, THE 2ND RATIO CAN BE SLIGHTLY > 1 (NOT ALLOWED)!
			$v[0] *= ($lb_width_approx / $w->{'_rowWidth'}) / $lb_width_approx;
			return @v;
		} else {
			return (0, 1);  #EMPTY LIST!
		}
	} elsif (scalar(@_) == 1 && $_[0] ne '') {  #SINGLE PARAMETER (VALID ENTRY):
		return $w->Tk::HList::xview($w->getEntry($_[0]));
	} elsif ((scalar(@_) == 2 && $_[0] =~ /^moveto$/o)
			|| (scalar(@_) == 3 && $_[0] =~ /^scroll$/o)) {  #MULTIPLE PARAMETERS:
		$w->Tk::HList::xview(@_);
	}
	return undef;
}

sub yview {
	my $w = shift;

	if (!defined $_[0]) {  #NO PARAMETERS:
		if ($w->size > 0) {
			my @v = $w->Tk::HList::yview;
			$w->{'_rowHeight'} ||= $w->_getheight(1, 'pixels');
			my $lb_height = $w->{'_rowHeight'} * $w->size;
			$v[1] ||= $v[0] + $w->height;
			$v[0] /= $lb_height;
			$v[1] /= $lb_height;
			$v[1] = 1  if ($v[1] > 1.0);
			return @v;
		} else {
			return (0, 1);  #EMPTY LIST!
		}
	} elsif (scalar(@_) == 1 && $_[0] ne '') {  #SINGLE PARAMETER (VALID ENTRY):
		return $w->Tk::HList::yview($w->getEntry($_[0]));
	} elsif ((scalar(@_) == 2 && $_[0] =~ /^moveto$/o)
			|| (scalar(@_) == 3 && $_[0] =~ /^scroll$/o)) {  #MULTIPLE PARAMETERS:
		$w->Tk::HList::yview(@_);
	}
	return undef;
}

sub scan {    #JWT:UNDERLYING HList DOES NOT SEEM TO SUPPORT SCANNING AT THIS TIME, SO I HACKED MINE OWN!:
	my $w = shift;

	croak 'f:Invalid Tk::HListbox scan option ' . $_[0] . "\n  Valid options: 'mark'|'dragto' (case-sensitive)\n\n"
			unless (defined($_[0]) && $_[0] =~ /^(?:mark|dragto)$/o);  #patch by Jeff Stephens.

	my $r;
	eval { $r = $w->SUPER::scan(@_) };   #NOTE:  DOCS SAY ALWAYS RETURNS '' ON SUCCESS.
	return $r  unless ($@);   #SUCCESS WOULD MEAN A RECENT Tk::HList UPDATE FINALLY ADDED IT!

	if ($_[0] =~ /^mark/o) {  #FAILURE (HList) SO WE EMULATE IT MANUALLY:
		$w->{'_xmark'} = $_[1];
		$w->{'_ymark'} = $_[2];
	} else {
		$w->xview('scroll', ($w->{'_xmark'} - $_[1]), 'unit');
		$w->yview('scroll', ($w->{'_ymark'} - $_[2]), 'units');
	}
	return '';
}

sub SpaceSelect   #JWT:THIS WORKS SLIGHTLY DIFFERENT THAN NORMAL LISTBOX B/C THE ONLY WAY IN AN HList TO SHOW THE CURSOR ON AN ITEM IS TO "SELECT" IT.
{
	my $w = shift;
	return  if ($w->{Configure}{'-state'} =~ /d/o);

	$w->BeginSelect(@_);
	$w->activate($_[0]);
	if ($w->cget('-selectmode') =~ /^(?:multiple|extended)/o) {
		$w->Callback(-browsecmd);
	} else {
		$w->Callback(-browsecmd => $_[0]);
	}
}

sub size {
	my $list_ref = $_[0]->info('children'); # POD for Tk::HList::info('children')  Returns a list of the toplevel entryPath's
	return defined $list_ref ? scalar @{$list_ref} : 0;
}

sub get {
	my $w = shift;

	if (!defined $_[0]) {   #FORCE TO FAIL IF NO ARGS GIVEN, LIKE Tk::Listbox->get()!:
		# Exit gracefully
		carp 'e:HListbox.get() wrong # args: should be 1 or 2: (firstIndex ?lastIndex?)!';
		return undef;
	} elsif (defined $_[1]) {  #WE HAVE 2 ARGUMENTS (INDICES), WILL RETURN A LIST:
		my @data = ();
		my $first = $w->index($_[0]);
		my $last  = $w->index($_[1]);
		if (defined $first) {
			$last = $first  unless (defined $last);
			for (my $i=$first; $i<=$last; $i++) {
				my $entry = $w->getEntry($i);
				push @data, $w->info('data', $entry)  if (defined($entry) && !$w->info('hidden', $entry));
			}
		}
		return @data;
	} else {  #WE HAVE ONLY 1 ARGUMENT (INDEX), RETURN VALID ENTRY OR '':
		my $data = '';
		my $first = $w->getEntry($_[0]);
		$data = $w->info('data', $first)
				if (defined($first) && !$w->info('hidden', $first));
		return $data;
	}
}

#HList CONVERTS ENTRY TEXTS CONTAINING DOTS TO CHILDREN (TREE-LIKE LISTS), SO WE MUST PREVENT
#THAT IN ORDER TO ENSURE WE GET A SINGLE-LEVEL "LIST", SINCE WE'RE A "Listbox" WIDGET THAT
#SUPPORTS SOME "HList-LIKE" FEATURES, *NOT* AN "HList" (WANT TREES, USE HList)!!!:
sub add {  #ADDED W/v3.00
	my $w = shift;
	my $e = shift;
	my %args = @_;
	if ($e =~ /\./o) {
		(my $erenamed = $e) =~ s/\./\-/go;
		$args{-text} = $e  unless (defined $args{-text});
		$e = $erenamed;
	}
	my $indx = 'end';
	foreach my $arg ('-at','-before','-after') {
		if (defined $args{$arg}) {
			$indx = $w->indexOf($args{$arg});
			$indx++  if ($arg eq '-after');
			delete $args{$arg};
			last;
		}
	}
	$w->insert($indx, {%args});
}

sub insert {     #INSERT ONE OR MORE ITEMS TO THE LIST:
	my ($c, $index, @data) = @_;
#?	return ''  if ($c->{Configure}{'-state'} =~ /d/o);  #UNCOMMENT TO BAR INSERTS IF DISABLED (LIKE Tk::Listbox)!

	# The listbox might get resized after insert/delete, which is a
	# behaviour we don't like....
	my $itemType = $c->cget('-itemtype');
	my @atIndexArgs = ();
	unless ($index =~ /^end/io) {
		my $atIndex = $c->index($index);
		@atIndexArgs = ('-at', $c->index($index))  if (defined $atIndex);
		@data = reverse @data;     #WE HAVE TO REVERSE THE LIST BEING ADDED IF THE INDEX IS NOT "end"!
	}
	my (@addArgs, @childData, @indicatorOps, %styleOps, $haveStyle, $hideit, $dataAlreadyPushed, $refdata);
	for (my $i=0;$i<=$#data;$i++) {
		@addArgs = ();
		@childData = ();
		@indicatorOps = ();
		%styleOps = ();
		$haveStyle = 0;
		$hideit = 0;
		$dataAlreadyPushed = 0;
		$refdata = '';
		if (defined($data[$i]) && $data[$i] ne '') {
			$refdata = ref ($data[$i]);
			if ($refdata eq 'Tk::Photo' || $refdata eq 'Tk::Bitmap' || $refdata eq 'Tk::Pixmap') {
				@addArgs = ('-itemtype', 'image', '-image', $data[$i]);
			} elsif ($data[$i] =~ /^Tk\:\:.*HASH\(.+\)$/o && $itemType =~ /^image/o) {   #WE HAVE AN IMAGE:
				@addArgs = ('-itemtype', $itemType, '-image', $data[$i]);
			} elsif ($refdata =~ /HASH/o) {    #WE HAVE A HASHREF (PBLY IMAGE+TEXT) OR ADDITIONAL HList OPTIONS:
				@addArgs = ('-itemtype', $data[$i]->{'-itemtype'}||$itemType);
				foreach my $op (keys %{$data[$i]}) {  #PUT EACH OBJECT IN IT'S PROPER BUCKET:
					if ($op =~ /^\-state$/o) {  # => addchild(@childData)
						push @childData, $op, $data[$i]->{$op};
					} elsif ($op =~ /^\-(?:text|image|underline)$/o) {  # => ItemCreate(@addArgs)
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
					} elsif ($op !~ /^\-(?:user|sort|itemtype)/o) {    #DATA OPTIONS WE WISH TO RETAIN BUT ARE NOT VALID FOR USE IN CREATING OBJECTS:
						$styleOps{$op} = $data[$i]->{$op};
					}
				}
			} else {  #WE JUST HAVE A TRADITIONAL TEXT STRING TO DISPLAY:
				@addArgs = ('-itemtype', 'text', '-text', $data[$i]);
				push @childData, '-data', $data[$i];
				$dataAlreadyPushed = 1;
#				eval { $data[$i]->{'-itemtype'} = 'text'; }; #CAN'T HANDLE SOME STRINGS, LIKE "-"!
			}
			push @childData, '-data', $data[$i]  unless ($dataAlreadyPushed);
		} else {      #WE HAVE NOTHING, ADD A SPACE SO IT'LL DISPLAY PROPERLY!
			@addArgs = ('-itemtype', 'text', '-text', ' ');
			push @childData, '-data', ' ';
#			eval { $data[$i]->{'-itemtype'} = 'text'; };
		}
		push @childData, @atIndexArgs  if ($#atIndexArgs >= 0);

		my $child = $c->addchild('', @childData);    #CREATE "CHILD".
		unless ($haveStyle && $haveStyle =~ /^Tk::ItemStyle/o) {  #WE ALSO HAVE AN ItemStyle, TRY RECONFIGURING IT:
			my $tp = 'text';
			if (defined $refdata) {     #patch by Jeff Stephens.
				if ($refdata eq 'HASH') {
					$tp = (defined($data[$i]) && defined($data[$i]->{-itemtype})) ? $data[$i]->{'-itemtype'} : $itemType;
				} elsif ($refdata eq 'Tk::Photo' || $refdata eq 'Tk::Bitmap' || $refdata eq 'Tk::Pixmap') {
					$tp = 'image';
				}
			}
			#NOTE:  STYLE STAYS THAT WAY FOR ALL SUBSEQUENT ROWS, BUT MUST DO B/C jfm4 NEEDS THIS!!:
			$c->{"_style$tp"}->configure(%styleOps)  if (keys(%styleOps) > 0);
			push @addArgs, '-style', $c->{"_style$tp"};
		}

		$c->itemCreate($child, 0, @addArgs);    #CREATE THE ENTRY:
		if (@indicatorOps) {
			$c->indicator('create', $child, @indicatorOps);   #WE HAVE AN "INDICATOR" IMAGE, CREATE IT TOO:
		}
		$c->hide(-entry => $child)  if ($hideit);
	}
#	$c->update;
	return '';
}

sub delete {        #DELETE ONE OR MORE ITEMS FROM THE LIST (INCLUDING HIDDEN ONES):
	my $w = shift;

	if (!defined $_[0]) {  #WE HAVE NO ARGUMENTS, WARN & DO NOTHING!:
		carp 'e:HListbox.delete wrong # args: should be 1 or 2: ("all" | firstIndex ?, lastIndex?)!';
		return;
	} elsif (defined $_[1]) {  #WE HAVE 2 ARGUMENTS (INDICES), WILL DELETE ALL BETWEEN (INCLUSIVE):
		if ($_[0] =~ /^all$/io || ($_[0] =~ /^0(?:\.0)?$/o && $_[1] =~ /^end/o)) {
			$w->Tk::HList::delete('all');
		} else {
			my $first = $w->index($_[0]);  #CONVERT "active", "end", etc. TO NUMERIC INDICES:
			my $last = $w->index($_[1]);
			if (defined $first) {
				$last = $first  unless (defined $last);
				for (my $i=$first; $i<=$last; $i++) {
					my $entry = $w->getEntry($i);
					$w->Tk::HList::delete('entry', $entry)  if (defined $entry);
				}
			}
		}
	} else {  #WE HAVE ONLY 1 ARGUMENT (INDEX)
		my $entry = $w->getEntry($_[0]);
		$w->Tk::HList::delete('entry', $entry)  if (defined $entry);
	}
	$w->{'_rowHeight'} = 0;
}

sub findIndex {  #DEPRECIATED - CLONE OF indexOF()!:
	return indexOf(@_);
}

sub getFirstEntry {
	my $firstChild = $_[0]->info('children');
	return ''  unless (defined $firstChild);
	return ${$firstChild}[0]  if (ref($firstChild) eq 'ARRAY' && $#{$firstChild} >= 0);   # patch by Jeff Stephens
	return ($firstChild =~ /\S/o) ? $firstChild : '';
}

sub getLastEntry {
	my @children = $_[0]->info('children');
	return @children ? pop(@children) : '';
}

#NOTE:  THIS FUNCTION IS THE OPPOSITE OF indexOF():
sub getEntry {    #GIVEN A VALID LISTBOX "INDEX", RETURN THE EQUIVALENT HList "ENTRY" (NUMERIC, BUT NOT ZERO-BASED!):
	my ($w) = shift;
	my $entrypath = undef;

	# Get numeric index for an entry,
	# An invalid entry will return undef:
	my $index = $w->index($_[0]);
	if (defined $index) {   
		# Get a list of toplevel entryPaths
		my $entrypaths_ref = $w->info('children');
		$entrypath = ${$entrypaths_ref}[$index]  if (defined $entrypaths_ref);
	}

	return $entrypath;
}

sub getEntryList {    #CONVERT A LIST OF INDICIES TO HList "ENTRIES":
	my $w = shift;

	my @entries = ();
	foreach my $i (@_) {
		my $entry = $w->getEntry($i);
		push @entries, $entry  if (defined $entry);
	}
	return @entries;
}

# NEXT 7 FUNCTIONS CONTRIBUTED BY Jeff Stephens:
sub nearestToIndex {
	my ($w, $index) = @_;
	my ($hlist_index, $array_ref, $y, $i);

	# Get bounding box coords:
	#NOTE:  Will only return a bbox if the item is visible or partially visible.
	#(So useless if a list is popped down)!
	$array_ref = $w->bbox($index);

	# Trap invisible "bbox" index
	if (!defined $array_ref) {
		carp "w:HListbox.nearestToIndex($index) cannot determine bounding box coordinates! [Item is NOT visible]";
		return undef;
	}

	# Determine middle Y value of bounding box:
	$y = ( ${$array_ref}[1] + ${$array_ref}[3] )/2;

	# Get nearest Hlist index of Y coord:
	$hlist_index = $w->Tk::HList::nearest($y);

	# Get the Listbox "INDEX" relative to ZERO=1ST
	$i = $w->indexOf($hlist_index);
	return $i;
}

# Get width (in pixels) for HListbox when a non-default font is used (due to HList)
sub getListWidth {
	my ($self, $w_chars) = @_;
	my ($w_pixels);

	# List is empty?
	return 0  if ($self->size <= 0);

	$w_pixels = $self->_getwidth($w_chars, 'pixels');

	return $w_pixels;
}

# ------------------------------------------------------------------------------
# Get height (in pixels) for HListbox when a non-default font is used (due to HList)
sub getListHeight {
	my ($self, $h_rows) = @_;
	my ($h_pixels);

	# list is empty?
	return 0  if ($self->size <= 0);

	$h_pixels = $self->_getheight($h_rows, 'pixels');

	return $h_pixels;
}

# ------------------------------------------------------------------------------
# Fix incorrect height, and width of HListbox, caused when a non-default font is used (due to HList)
sub fixListSize {
	my ($self, $w, $h) = @_;
	my ($w_chars, $h_chars);

	# Skip if list is empty
	return  if ($self->size <= 0);

	# The width is set OK when -width=0   # NOT TRUE WHEN CHANGING FONT SIZE
	unless ($w <= 0) {
		$w_chars = $self->_getwidth($w, 'characters');
		$self->configure(-width => $w_chars);
	}

	# The height is set OK when -height=0
	unless ($h <= 0) {
		$h_chars = $self->_getheight($h, 'characters');
		$self->configure(-height => $h_chars);
	}
}

sub _max {   #PRIVATE FUNCTION (NOT A METHOD!) TO RETURN THE MAX. OF 2 NUMBERS;
	#PROGRAMMER NOTE:  COULD ADD LOOP HERE IF LATER WE NEED TO HANDLE >2 ARGS:
	return ($_[1] > $_[0]) ? $_[1] : $_[0];
}

# ------------------------------------------------------------------------------
# Get the correct height, when a non-default font is used and/or
# item related indicator/image/gap/pady/textanchor/selectborderwidth values are used (in HList)
sub _getheight {
	my ($self, $h_rows, $option) = @_;
	my ($lsdef, $linespace, $image, $imageh, $indicatorh, $h, $path, $itemtype, $pady, $gap,
	$item, $style, $font, $textanchor, $tih, %tih_action, );

	####print "Starting _getheight [HListbox]...\n";

	%tih_action = ( nw => 'sum', n => 'sum', ne => 'sum',
			w  => 'max', c => 'max',  e => 'max',
			center => 'max',
			sw => 'sum', s => 'sum', se => 'sum',
	);

	# get default font linespace
	$lsdef = $self->fontMetrics($DEFAULTFONT, -linespace);
	my $selectborderwidth = $self->cget('-selectborderwidth');

	$h = 0;
	for (my $i=0; $i<=$h_rows-1; $i++) {
		####print "I=$i\n";
		# get HLIST item -itemtype
		$path = $self->getEntry($i);  # ZERO based index
		$itemtype = $self->itemCget($path, 0, '-itemtype');

		# get HLIST item -style
		$style = $self->itemCget($path, 0, '-style');

		# get HLIST item imagetext text anchor
		$textanchor = ($itemtype eq 'imagetext') ? $style->cget('-textanchor') : 'unset';

		# get HLIST item -pady
		$pady = $style->cget('-pady');
		####print "PADY(line $i)=$pady [$itemtype]\n";

		# get HLIST item text font -linespace
		$linespace = 0;
		if ($itemtype eq 'text' || $itemtype eq 'imagetext') {
			$font = $style->cget('-font');
			# get font linespace
			$linespace = $self->fontMetrics($font, -linespace);
		}

		# get HLIST item gap
		$gap = 0;
		$gap = $style->cget('-gap')  if ($itemtype eq 'imagetext');

		# get HLIST item image height
		$imageh = 0;
		if ($itemtype eq 'image' || $itemtype eq 'imagetext') {
			#$image = $self->itemCget($path, 0, '-image'); # BUT ONLY RETURNS an internal image name barh!!!!!!!

			# Get raw data for the item
			$item = $self->get($i);     # ZERO based index

			if (ref $item eq 'Tk::Photo' || ref $item eq 'Tk::Bitmap' || ref $item eq 'Tk::Pixmap') {
				$imageh = $item->height;

			} elsif (ref $item eq 'HASH') {
				$imageh = ${$item}{-image}->height  if (defined ${$item}{-image});
			} else {
				print "ERROR: Unexpected Image type [_getheight]\n";
			}
		}

		# get HLIST indicator image height    .......HEIGHT IS IGNORED BY HLIST as the indicator is overlaid in the Item.
		#$indicatorh = 0;
		#if ($self->cget('-indicator') == 1) {
		#  if ($self->indicator('exists', $path) ) {
		#    (undef, $indicatorh) = $self->indicator('size', $path);
		#    print "INDICATORH(line $i)=$indicatorh\n";
		#  }
		#}

		# get item height action
		$tih = ($textanchor ne 'unset' && $tih_action{$textanchor} eq 'sum')
				? $linespace + $imageh + $gap
				: _max($linespace, $imageh);

		# increment height
		$h += ($tih + 2 * $selectborderwidth + 2 * $pady);
	}

	if (lc $option eq 'characters') {
		$h = $h/$lsdef;   # Divide by the linespace of the default Font.
		$h = ceil($h);  # Always Round-Up the calulated HEIGHT to an integer.
	}
	return $h;
}

# ------------------------------------------------------------------------------
# Get the correct width, when a non-default font is used and/or
# item related indicator/image/gap/padx/textanchor/selectborderwidth values are used (in HList)
# There will be performance issues with long lists!
sub _getwidth {
	my ($self, $w_chars, $option) = @_;
	my ($w, $maxitemw, $nitems, $selectborderwidth,
			$colw, $path, $indicator, $indicatorw, $maxindicatorw,
			$imagew, $item, $anchor, $textanchor,
			$itemtype, $itemref, $style, $font, $text, $textl, $maxtextl, $textw, $deftextw, $gap, $padx, $itemw,
			$maxnchars, $maxtext, $adjusted_nchars, $justify,
			$tiw, %tiw_action
	);

	# Is the option -indicator set for the HListbox?
	$indicator = $self->cget('-indicator');

	$selectborderwidth = $self->cget('-selectborderwidth');
	#$indent = $self->cget('-indent');  # NOT USED???????

	$maxitemw = 0;
	$maxtextl = 0;
	$maxtext  = 0;
	$maxindicatorw = 0;
	%tiw_action = (
			nw => 'sum', n => 'max', ne => 'sum',
			w  => 'sum', c => 'max',  e => 'sum',
			center => 'max',
			sw => 'sum', s => 'max', se => 'sum',
	);

	# Iterate through each item in list
	$nitems = $self->size;
	for (my $i=0; $i<=$nitems-1; $i++) {   # ZERO based index
		# Get HLIST item path
		$path = $self->getEntry($i);         # ZERO based index

		# Get itemtype
		$itemtype = $self->itemCget($path, 0, '-itemtype');

		# Get style
		$style = $self->itemCget($path, 0, '-style');

		# Get padx
		$padx = $style->cget('-padx');

		# get HLIST indicator image width
		$indicatorw = 0;
		if ($indicator == 1) {
			if ($self->indicator('exists', $path) ) {
				($indicatorw, undef) = $self->indicator('size', $path);
			} else {# Option -indicator=1, but no indicator defined.
				# HList will provide a gap so we need get width
				$indicatorw = 20;
			}
			$maxindicatorw = $indicatorw  if ($indicatorw > $maxindicatorw);
		}

		## get HLIST item anchor
		#$anchor = $style->cget('-anchor');  # NOT NEEDED AS YET!

		# get HLIST item imagetext text anchor
		$textanchor = ($itemtype eq 'imagetext') ? $style->cget('-textanchor') : 'unset';

		## get HLIST item text/imagetext justification
		#$justify = 'unset';
		#if ($itemtype eq 'text' || $itemtype eq 'imagetext') {
		#   $justify = $style->cget('-justify');   # NOT NEDDED AS YET!
		#}

		# get HLIST item image width
		$imagew = 0;
		if ($itemtype eq 'image' || $itemtype eq 'imagetext') {
			# Get raw data for the item
			$item = $self->get($i);     # ZERO based index

			$itemref = ref $item;
			if ($itemref eq 'Tk::Photo' || $itemref eq 'Tk::Bitmap' || $itemref eq 'Tk::Pixmap') {
				$imagew = $item->width;
			} elsif ($itemref eq 'HASH') {
				$imagew = ${$item}{-image}->width  if (defined ${$item}{-image});
			} else {
				print "ERROR: Unexpected Image type [_getwidth]\n";
			}
		}

		# get HLIST item gap
		$gap = ($itemtype eq 'imagetext') ? $style->cget('-gap') : 0;

		# get HLIST item style, font and text
		$textw = 0;
		if ($itemtype eq 'text' || $itemtype eq 'imagetext') {
			$text = $self->itemCget($path, 0, '-text');

			# Truncate text?
			$textl = length $text;
			if ($w_chars > 0) {
				if ($textl > $w_chars) {
					$text = substr($text, 0, $w_chars);
					$textl = $w_chars;
				}
			}
			$font  = $style->cget('-font');
			$textw = $self->fontMeasure($font, $text);
		}

		# Calculate item width
		if ($textanchor ne 'unset') {
			if ($tiw_action{$textanchor} eq 'sum') {
				$tiw = $textw + $imagew + $gap;
			} else {# $tiw_action{$textanchor}='max'
				$tiw = _max($textw, $imagew);
			}
		} else {# $textanchor='unset'
			$tiw = $textw + $imagew + $gap;
		}
		$itemw = $tiw + 2 * $padx + 2 * $selectborderwidth;

		# Keep track of widest item in list
		if ($itemw > $maxitemw) {
			$maxitemw = $itemw;
			$maxtextl = $textl;
			$maxtext  = $text;
		}
	}

	# Take account of indicator
	$maxitemw = $maxitemw + $maxindicatorw
			if (lc $option eq 'pixels' && $indicator == 1);

	# Get default font text width
	$deftextw = $self->fontMeasure($DEFAULTFONT, $maxtext);
	$adjusted_nchars = $maxtextl * ($maxitemw + $maxindicatorw) / $deftextw;
	$maxnchars = ceil($adjusted_nchars);

	# get current list column width (pixels)
	if (lc $option eq 'characters') {
		$w = $maxnchars;
	} else {   # 'pixels'
		$w = $maxitemw;
	}

	return $w;
}

#NOTE:  THIS FUNCTION IS THE OPPOSITE OF getEntry():
sub indexOf {  #GIVEN A VALID HList "ENTRY", RETURN IT'S RELATIVE (TO ZERO=1ST) Listbox "INDEX":
	my ($w, $entry) = @_;

	# Get a list of toplevel entryPaths
	my $entrypaths_ref = $w->info('children');
	return undef  unless (defined $entrypaths_ref);

	my $indx = 0;
	foreach my $entrypath (@{$entrypaths_ref}) {
		return $indx  if ($entry eq $entrypath);
		if ($entry =~ /[a-zA-Z]/o) {  #v3.00+ ALSO RETURN INDEX FOR "HListy" TEXT STRING ENTRYPATHS!:
			my $entrypath = $w->get($entrypath);
no strict "refs";
			return $indx  if (defined($entrypath) && defined($entrypath->{-text})
					&& $entry eq $entrypath->{-text});
		}
		$indx++;
	}
	return undef;   #ENTRY DOES NOT EXIST!
}

sub index {    #GIVEN A VALUE "LISTBOX INDEX", RETURN A ZERO-BASED "INDEX" (CONVERTS STUFF LIKE "@x,y", "end". etc:
	my $w = $_[0];
	return 0  unless (defined($_[1]) && $_[1]);

	if ($_[1] =~ /^\d+$/o) {
		return $_[1];
	} elsif ($_[1] =~ /^end/io) {
		return $_[0]->size-1;    #NOTE: empty list will return -1.
	} elsif ($_[1] =~ /^anchor/o) {
		return $_[0]->{'_vanchor'};
	} elsif ($_[1] =~ /^active/o) {
		return $w->{'_lastactive'};  #ALWAYS RETURN *OUR* ACTIVE, SEE NOTE ABOVE activate() FUNCTION!
	} elsif ($_[1] =~ /^\@\d+\,(\d+)/o) {
		return $_[0]->indexOf($_[0]->nearest($1));  # $1 is the Y=coord of an index i.e: INDEX='@64,114'.
	}
	return undef;  #BAD OR OUT-OF-BOUNDS INDEX (CALLERS MUST CHECK FOR THIS)!
}

sub Cntrl_Home {
	my $w = shift;
	my $Ev = $w->XEvent;

	$w->activate(0);
	$w->see(0);
	$w->selectionClear(0,'end');
	unless ($JWTLISTBOXHACK) {
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
	unless ($JWTLISTBOXHACK) {
		$w->selectionSet('end');
		$w->Callback(-browsecmd => $w->index('end'));
	}
	$w->eventGenerate("<<ListboxSelect>>");
}

sub DataExtend {    #USER PRESSED Shift-Ctrl-Home/End, SELECT FROM ACTIVE TO SPECIFIED LOCN (EITHER TOP OR BOTTOM):
	my ($w, $el) = @_;
	return  if ($w->{Configure}{'-state'} =~ /d/o);

	my $active = $w->index('active');
	my $indx = $w->index($el);
	return  unless ($indx);

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
	return  if ($w->{Configure}{'-state'} =~ /d/o);

	my $Ev = $w->XEvent;

	$w->selectionClear(0,'end');
	$w->eventGenerate("<<ListboxSelect>>");
	$w->Callback(-browsecmd);
}

sub DoubleButton1    #USER DOUBLE-CLICKED LEFT MOUSE-BUTTON (has already done a single click)
{
	return  if ($_[0]->{Configure}{'-state'} =~ /d/o);

	$_[0]->InvokeCommand;
	$_[0]->eventGenerate("<<ListboxSelect>>");
}

sub ShiftButton1     #USER PRESSED SHIFT-KEY AND MOUSE-BUTTON 1:
{
	my $w = shift;
	return  if ($w->{Configure}{'-state'} =~ /d/o);

	$w->BeginExtend(@_);
}

sub ShiftUpDown {    #USER PRESSED UP OR DOWN ARROW WHILST HOLDING <SHIFT> KEY DOWN:
	my $w = shift;
	my $spec = shift;

	$spec = ($1 >= 0) ? 'next' : 'prev'  if ($spec =~ /^([\+\-]?\d+)/o);
	return $w->UpDown($spec)  if ($w->cget('-selectmode') !~ /^extended/o);

	my $amount = ($spec =~ /^prev/o) ? -1 : 1;
	my $active = $w->index('active');
	return  unless (defined $active);

	if ($JWTLISTBOXHACK) {
		if ($w->selectionIncludes($active)) {
			$w->selectionClear($active);
		} else {
			$w->selectionSet($active);
		}
	} else {
		if (!@{$w->{-selection}}) {
			$w->selectionSet($active);
			@{$w->{-selection}} = $w->curselection;
		}
	}

	#BEFORE ADVANCING, SKIP OVER ANY ENTRIES THAT ARE DISABLED OR HIDDEN:
	#(THIS ALWAYS ADVANCES AT LEAST ONE ENTRY!):
	my $ent = $w->getEntry($active);
	return  unless (defined $ent);

	while (1) {
		$ent = $w->info($spec, $ent);
		last  unless(defined $ent);
		next  if( $w->entrycget($ent, '-state') eq 'disabled' );
		next  if( $w->info('hidden', $ent) );
		last;
	}
	unless ($ent =~ /\S/o ) {
		$w->yview('scroll', $amount, 'unit');
		$w->eventGenerate("<<ListboxSelect>>");
		$w->Callback(-browsecmd => $active);
		return;
	}
	$active = $w->indexOf($ent);  #THE "NEXT" ENTRY.
	return  unless (defined $active);

	$w->activate($active);
	$w->see('active');
	if ($JWTLISTBOXHACK) {
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
	return  unless (defined $active);

	my $ent = $w->getEntry($active);
	return  unless (defined $ent);

	while (1) {
		$ent = $w->info($spec, $ent);
		last if ($@);
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
	} elsif ($mode =~ /^extended/o && !$JWTLISTBOXHACK) {
		$w->selectionClear(0,'end');
		$w->selectionSet('active');
		$w->selectionAnchor('active');
		$w->{-Prev} = $w->index('active');
		@{$w->{-selection}} = ();
		$w->eventGenerate("<<ListboxSelect>>");
	}
}

sub selectionIncludes {
#	return 0  unless ($_[0]->index($_[1]) =~ /\d/o);
	return 0  unless (defined($_[0]) && $_[0] =~ /\S/o);

	my $res = 0;
	eval { $res = $_[0]->Tk::HList::selectionIncludes($_[0]->getEntry($_[1])); };
	$res ||= 0;
}

sub itemconfigure {   #SET OPTIONS ON INDIVIDUAL ITEMS:
	my $w = shift;
	my $indx = shift;
	my $entry = $w->getEntry($indx);
	unless (defined $entry) {
		carp "e:HListbox.itemconfigure(): ($indx) specified is not a valid entry!";
		return undef;
	}
	if (defined $_[0]) {
		my $opt = shift;
		if ($opt =~ /^\-(?:style|text|itemtype|image|underline|showimage|showtext|bitmap)$/o) {   #THESE OPTIONS CAN BE DIRECTLY CONFIGURED:
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
	if (defined($_[0]) && defined($entry)) {
		my $opt = shift;
		if ($opt =~ /^\-(?:style|text|itemtype|image|underline)$/o) {   #THESE OPTIONS CAN BE DIRECTLY CONFIGURED:
			return $w->itemCget($entry, 0, $opt);
		} else {    #OTHER OPTIONS MUST BE CONFIGURED IN AN HList "ItemStyle" OBJECT:
			my $style = $w->itemCget($entry, 0, '-style');
			if (defined($style) && $style) {    #GET ANY "STYLE" OBJECT
				$opt = '-fg'  if ($opt =~ /^\-foreground$/o);
				return $style->cget($opt);
			}
		}
	}
	return undef;
}

#NOTE:  Tk::HList's item()'s 2ND ARG. IS A "COLUMN" (HLists CAN HAVE A TREE STRUCTURE), BUT HListboxes,
#LIKE Listboxes HAVE A SINGLE COLUMN (0), SO DO NOT PASS A COLUMN# TO THIS FUNCTION (IT WILL BE TREATED
#AS AN ENTRY-PATH, AND LIKELY FAIL!  WE ONLY CHECK FOR A VALID OPTION IN 1ST ARGUMENT:
sub item {
	my $w = shift;

	croak "e:Missing Tk::HListbox.item() argument(s), at least (opt, index) required, only ".scalar(@_).' passed.'
			unless (scalar(@_) > 1);

	my ($opt, $indx, @args) = @_;
	# check for valid option name:
	croak "e:Invalid Tk::HListbox item() option '$opt'\n  Valid options: ['cget'|'configure'|'create'|'delete'|'exists'] (case-sensitive)\n"
			unless (defined($opt) && $opt =~ /^(?:cget|configure|create|delete|exists)$/o);

	my $entry = $w->getEntry($indx);
	return (defined $entry) ? $w->Tk::HList::item($opt, 0, @args) : undef;
}

sub BeginSelect   #Mouse button-press (button 1)
{
	my $w = shift;
	return  if ($w->{Configure}{'-state'} =~ /d/o || scalar($w->size) <= 0);  #patch by Jeff Stephens.

	my $el = shift;

	#HANDLE THIS SILLY "TIX" STUFF:
	my $Ev = $w->XEvent;
	my @info = $w->info('item',$Ev->x, $Ev->y)  if (defined $Ev);
	if (defined($info[1]) && $info[1] eq 'indicator') {
		$w->{tixindicator} = $el;
		$w->Callback(-indicatorcmd => $el, '<Arm>');
		return;
	}

	my $mode = $w->cget('-selectmode');
	#TOGGLE SELECTION STATUS, SET ANCHOR IF "extended":
	if ($JWTLISTBOXHACK) {
		if ($mode =~ /^(?:multiple|extended)/o) {
			if ($w->selectionIncludes($el)) {  #TOGGLE SELECT-STATUS OF ENTRY CLICKED ON:
				$w->selectionClear($el);
			} else {
				$w->selectionSet($el);
			}
			$w->selectionAnchor($el);
		} else {  #WE ALLOW SELECTION TO BE EMPTY IN SINGLE/BROWSE MODES!:
			if ($w->selectionIncludes($el)) {  #TOGGLE SELECT-STATUS OF ENTRY CLICKED ON:
				$w->selectionClear(0,'end');
			} else {
				$w->selectionClear(0,'end');
				$w->selectionSet($el);
			}
		}
		@{$w->{-selection}} = ();
	} elsif ($mode =~ /^multiple/o) {
		if ($w->selectionIncludes($el)) {
			$w->selectionClear($el);
		} else {
			$w->selectionSet($el);
		}
	} else {
		$w->selectionClear(0,'end');
		$w->selectionSet($el);
		$w->selectionAnchor($el);
		@{$w->{-selection}} = ();
	}
	$w->{-Prev} = $el;
	$w->eventGenerate("<<ListboxSelect>>");
}

sub CtrlPriorNext {   #USER PRESSED <CONTROL-<PgUp>/<PgDown>> - OUR SPECIAL SELECT NEXT SCREEN-FULL:
	my $w = shift;
	my $updown = shift;
	if ($w->cget('-selectmode') =~ /^(?:multiple|extended)/o) {
		my $anchor = $w->index('anchor');
		return  unless (defined $anchor);

		my $selectTo = $anchor + ($updown * $w->cget('-height'));
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

#THIS SOMETIMES FAILS CAUSING THE FIRST ELEMENT TO NOT BE ADDED?!
     if (defined($index) && $index <= $sizeof ) {
        # Change a current listbox entry
        $self->delete($index);
        $self->insert($index, $value);
     } else {
        # Add a new value
        if ( defined $index ) {
           $self->insert($index, $value);
        } else {
           $self->insert('end', $value);
        }
     }
	 $self->activate($self->{'_lastactive'});
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

sub ButtonPress_1
{
	my $w = shift;
	my $clickedon = shift;

	if (Tk::Exists($w)) {
		return  if (!defined($clickedon) || $w->{Configure}{'-state'} =~ /d/o || scalar($w->size) <= 0);

		$w->focus  if (!$w->{'_hasfocus'} && $w->{'_ourtakefocus'});
		$w->BeginSelect($clickedon, @_);
	}
}

sub ButtonRelease_1
{
	my $w = shift;
	return  if ($w->{Configure}{'-state'} =~ /d/o || scalar($w->size) <= 0);  #patch by Jeff Stephens.

	my $Ev = $w->XEvent;
	my $mode = $w->cget('-selectmode');
	$w->CancelRepeat  unless ($mode =~ /^dragdrop/o);
	my $ent = $w->indexOf($w->GetNearest($Ev->y));
	return  unless (defined($ent) and length($ent));  #BUTTON RELEASED OUTSIDE OF WIDGET? (PUNT)

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
	$w->activate($ent, 1);
	if ($mode =~ /^(?:multiple|extended)/o) {
		$w->Callback(-browsecmd);
	} else {
		(my $sel) = $w->curselection;
		$w->Callback(-browsecmd => $sel)  if (defined($sel) && $sel =~ /\d/o);
	}
}

sub jwtAltButtonRelease_1 {  #Alt-mousebutton1 released:  Set selection to only this item, & activate:
	my $w = shift;
	return  if ($w->{Configure}{'-state'} =~ /d/o || scalar($w->size) <= 0);  #patch by Jeff Stephens.

	if ($JWTLISTBOXHACK && !exists $w->{tixindicator}) {
		my $Ev = $w->XEvent;
		my $index = $w->index('@' . $Ev->x . ',' . $Ev->y);
		$w->selectionClear(0,'end');
		$w->selectionSet($index);
		$w->selectionAnchor($index);
		$w->focus  if ($w->cget('-takefocus'));
		$w->eventGenerate("<<ListboxSelect>>");
	}
	$w->ButtonRelease_1();
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
	return  unless (defined $Ev);

	my $mode = $w->cget('-selectmode');
	return  if ($mode eq 'dragdrop');

	return  if ($w->{Configure}{'-state'} =~ /d/o);
	return  if (exists($w->{tixindicator}));
	return  unless (defined $el);
	return  if (defined($w->{-Prev}) && $el == $w->{-Prev});

	my $anchor = $w->index('anchor');
	if ($JWTLISTBOXHACK) {
		unless (defined($anchor) && $anchor =~ /\d/o) {
			$anchor = $el;
			$w->selectionAnchor($anchor);
			$w->selectionSet($el);
		}
	}
	if ($mode =~ /^browse/o) {
		$w->selectionClear(0,'end');
		$w->selectionSet($el);
		$w->{-Prev} = $el;
		$w->eventGenerate("<<ListboxSelect>>");
	} elsif ($mode =~ /^extended/o) {
		my $i = $w->{-Prev};
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
		if (!@{$w->{-selection}}) {
			@{$w->{-selection}} = $w->curselection;
		}
		while ($i < $el && $i < $anchor) {
			if (Tk::lsearch(\@{$w->{-selection}},$i) >= 0) {
				$w->selectionSet($i);
			}
			$i++
		}
		while ($i > $el && $i > $anchor) {
			if (Tk::lsearch(\@{$w->{-selection}},$i) >= 0) {
				$w->selectionSet($i);
			}
			$i--;
		}
		$w->{-Prev} = $el;
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

	if ($JWTLISTBOXHACK) {
		if ($w->cget('-selectmode') =~ /^extended/o) {
			my $active = $w->index('active') || $w->index('anchor') || 0;
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

sub ShiftSpace  #(jwtlistboxhack only!) Shift-spacebar pressed:  Select from anchor to active inclusive:
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
		if ($w->selectionIncludes($el)) {  #TOGGLE SELECT-STATUS OF ENTRY CLICKED ON:
			$w->selectionClear($el);
		} else {
			$w->selectionClear  if ($mode =~ /^(?:single|browse)$/o);
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

sub jwtAltSpace  #Shift-spacebar pressed:  Select from anchor to active inclusive:
{
	my $w = shift;
	my $el = shift;

	my $anchor = $w->index('anchor');
	my $mode = $w->cget('-selectmode');
	$w->selectionClear(0, 'end');
	$w->selectionSet($el);
	$w->selectionAnchor($el);
	$w->activate($el);
	$w->eventGenerate("<<ListboxSelect>>");
}

sub KeyboardToggleIndicator   #<"+" or "-" KEY PRESSED:
{
	my $w = shift;
	my $indcmd = shift;
	my $el = shift;

	my @info = $w->info('anchor');
	return  unless (defined $info[0]);

	$w->{tixindicator} = $w->indexOf($info[0]);
	if ($w->indicator('exists', $info[0])) {
		my @ops = $w->indicator('configure', $info[0]);
		$w->Callback(-indicatorcmd => $w->indexOf($info[0]), $indcmd)  if ($#ops > 0);
		$w->Callback(-indicatorcmd => $w->indexOf($info[0]), $indcmd)  if ($#ops > 0);
	}
	delete $w->{tixindicator};

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
	return  if ($w->{Configure}{'-state'} =~ /d/o);

	my $el = shift;

	if ($w->cget('-selectmode') =~ /^extended/o) {
		@{$w->{-selection}} = $w->curselection();
		$w->{-Prev} = $el;
		$w->selectionAnchor($el);
		if ($w->selectionIncludes($el)) {
	 		$w->selectionClear($el)
		} else {
			$w->selectionSet($el)
		}
		$w->eventGenerate("<<ListboxSelect>>");
	}
	$w->activate($w->index('anchor'));
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

	if ($JWTLISTBOXHACK) {
		$w->selectionClear('0', 'end')  if ($w->cget('-selectmode') =~ /^(?:multiple|extended)/o);
	} else {
		return if ($w->cget('-selectmode') ne 'extended' || !defined $w->{-Prev});

		my $first = $w->index('anchor');
		my $active = $w->index('active');
		my $last = $w->{-Prev};
		($first, $last) = ($last, $first)  if ($first > $last);
		$w->selectionClear($first,$last);
		while ($first <= $last) {
			if (Tk::lsearch(\@{$w->{-selection}},$first) >= 0) {
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
	$w->Tk::HList::show(@args)  if (defined $args[1]);
}

sub hide
{
	my $w = shift;
	my @args = @_;
	unshift @args, '-entry'  unless ($#args >= 1 && $args[0] =~ /^\-/);
	$args[1] = $w->getEntry($args[1]);
	$w->Tk::HList::hide(@args)  if (defined $args[1]);
}

sub bbox
{
	my $entry = $_[0]->getEntry($_[1]);
	return $_[0]->infoBbox($entry)  if (defined $entry);
}

sub focus
{
	my $w = shift;
	if ($w->{Configure}{'-state'} =~ /d/o) {
		#DON'T ALLOW TO TAKE FOCUS IF DISABLED (NOTE:  THIS DIFFERS FROM Tk::Listbox WHICH WILL IF -takefocus == 1!):
		$w->focusNext;
		return;
	}

	$w->Tk::focus;
	$w->{'_hasfocus'} = 1;
	return  if ($w->{'-showcursoralways'});

	#RESTORE HIDDEN CURSOR WHEN FOCUS IS (RE)GAINED:
	my $entry = $w->getEntry($w->{'_lastactive'});
	$w->Tk::HList::anchorSet($entry)  if (defined($entry) && $w->{'_lastactive'} =~ /\d/); #LIST MAY BE EMPTY!
}

sub unfocus
{
	my $w = shift;
	if ($w->{'-showcursoralways'}) {
		$w->{'_hasfocus'} = 0;
		return;
	}

	$w->{'_lastactive'} = $w->index('active');
	$w->{'_hasfocus'} = 0;
	$w->activate($w->{'_lastactive'});
}

1

__END__
