=head1 NAME

Tk::HMListbox - Sortable Multicolumn HListbox (allowing icons, along with text) with arrows in headers indicating sort order.

=head1 AUTHOR

Jim Turner

(c) 2015-2022, Jim Turner under the same license that Perl 5 itself is.  All rights reserved.

Tk::SMListbox author:  me

Tk::HListbox author:   me

Tk::MListbox authors:  Hans Jorgen Helgesen, hans_helgesen@hotmail.com (from March 2000: hans.helgesen@novit.no)

=head1 SYNOPSIS

use Tk::HMListbox;

$hml = $parent->HMListbox (<options>);

=head1 DESCRIPTION

Tk::HMListbox is a derivitive of my L<Tk::SMListbox> (and thus L<Tk::MListbox>) 
that uses L<Tk::HListbox> (instead of L<Tk::Listbox>, as used by the latter 
two) which was done to allow for image icons to be included in columns 
along with the traditional text strings.  I created both of these 
Tk::H*Listbox widgets in order to include a column of tiny file-type icons, 
in addition to the other file attribute columns in my JFM5 Perl/Tk-based 
file-manager application.  Tk::HMListbox is designed to work as a drop-in 
replacement for either Tk::SMListbox or Tk::MListbox, maintaining 
backward-compatability with both.

Sorting is done by clicking on one of the column headings in the 
widget. The first click will sort the data with the selected column as 
key, a new click will reverse the sort order.

=head1 EXAMPLES

my $table = $w->Scrolled('HMListbox'

        -scrollbars => 'se', 

        -height => 12,

        -relief => 'sunken',

        -sortable => 1,   #USER CAN SORT BY COLUMN BY CLICKING ON THE COLUMN HEADER BUTTON.

        -selectmode => 'extended',

        -showallsortcolumns => 1,  #SHOW SORT DIRECTION ARROW ON ALL SORTED COLUMNS.

        -takefocus => 1,

        -borderwidth => 1,

        -fillcolumn => 1,   #IF WINDOW RESIZED, EXPAND COLUMN 1 ("Name") TO FILL THE EXTRA SPACE.

        -columns => [    #COLUMN WIDTH, SORT FUNCTIONS, HEADER BUTTON INFORMATION, ETC.:

            [-itemtype => 'imagetext', -text => '~D', -width => 4, 
                -comparecmd => sub { $_[0]->{'-sort'} cmp $_[1]->{'-sort'} } ],

            [-text => '~Name', -width => 25 ],

            [-text => '~Perm.', -width => 10 ],

            [-text => '~Owner:Group', -width => 14 ],

            [-text => '~Size', -width => 8 ],

            [-text => 'Date/~Time', -width => 15, -reversearrow => 1, -comparecommand => sub { $_[1] cmp $_[0] }],

        ]

        )->pack(

                -expand => 'yes',

        );

#See also "make test" (test.pl).

=head1 STANDARD OPTIONS

B<-background> B<-borderwidth> B<-cursor> B<-disabledforeground> 
B<-exportselection> B<-font> B<-foreground> B<-height> 
B<-highlightbackground> B<-highlightcolor> B<-highlightthickness> 
B<-relief> B<-selectbackground> B<-selectborderwidth> 
B<-selectforeground> B<-setgrid> B<-state> B<-takefocus> B<-width> 
B<-xscrollcommand> B<-yscrollcommand>

=head1 WIDGET SPECIFIC OPTIONS

=over 4

=item B<-columns> => I<list>

Defines the columns in the widget. Each element in the list 
describes a column. See the B<COLUMNS> section below.

=item B<-configurecommand> => I<callback>

The -configurecommand callback will be called whenever the layout of the
widget has changed due to user interaction. That is, the user changes the
width of a column by dragging the separator, or moves a column by dragging
the column header. 

This option is useful if the application wants to store the widget layout 
for later retrieval. The widget layout can be obtained by the callback
by calling the method columnPackInfo().

=item B<-fillcolumn> => I<index>

Specify the index number of a column that will expand to fill any new 
space opened up by dragging the window to a larger size.  All other 
columns maintain their current widths unless changed by the user 
dragging a column separator.  Otherwise all columns maintain their 
sizes and the extra space is unused (if no column specified here).
Default: -1 (no column expands horizontally).  All columns always 
expand vertically though.  The same column keeps it's expansion 
privilege even if user rearranges their positions.

=item B<-focuscolumn> => I<index>

DEPRECIATED:  Sets the index of the column whose listbox 
is to receive the keyboard focus when the HMListbox widget receives 
keyboard focus.  This is a holdover from Tk::SMListbox, where it 
is useful to better display the active element cursor due to the 
fact that it depends on Tk::Listbox, which does not display the  
active element (usually underlined) unless the listbox itself has the 
focus.  This allows the programmer to specify a colum other than the 
first one, ie, if the main column of interest to the user is not the 
first one.

Tk::HMListbox depends instead on Tk::HListbox, which does 
display the active element without specifically being focused 
making it unnecessary to designate a specific widget to show the 
active cursor, so therefore all column listboxes show the active 
element regardless of which has the focus and Tk::HListbox can 
assign the first column (the default if this isn't specified here) 
the focus and everything displays properly.

NOTE:  none of this applies if B<-nocolumnfocus> is set, which 
also has the side effect of disabling most keyboard bindings on 
the HMListbox.  Default:  I<0> (First column listbox gets focus).

=item B<-headerbackground> => I<color>

Specify a different background color for the top ("header") row.
Default:  B<-background> or parent window's background.
 
=item B<-headerforeground> => I<color>

Specify a different foreground color for the top ("header") row.
Default:  B<-foreground> or parent window's foreground.

=item B<-ipadx> => I<number>

Specify horizontal padding style in pixels around the image 
for the rows in the listbox which are type I<image> or I<imagetext>.
Default:  B<0>

=item B<-ipady> => I<number>

Specify vertical padding style in pixels around the image 
for the rows in the listbox which are type I<image> or I<imagetext>.
This can be useful in correcting vertical misallignment between the 
columns when some columns contain images and others are text only!
NOTE:  This changes the height of the affected rows.
Default:  B<1> (and setting to B<0> is seems to be the same as B<2>).

=item B<-moveable> => I<boolean>

A value of B<1> indicates that it is okay for the user to move
the columns by dragging the column headers. B<0> disables this
function.  Default:  B<1>.

=item B<-nocolumnfocus> => I<boolean>

Prevents the HMListbox widget from giving the keyboard focus to 
a specific column.  In HMListbox, it doesn't matter which column 
receives the focus (the default without setting B<-focuscolumn> 
is that the first column normally gets the focus when the 
HMListbox widgets receives keyboard focus).  The net effect of 
this option being set is that the widget itself takes focus, but 
many keyboard bindings will not work, namely selecting rows with 
the spacebar.  Default:  I<0> (Take focus normally and give the 
focus to one of the column listboxes under the hood so that 
row-based keyboard bindings will all work properly).  To have 
the HMListbox widget itself be skipped in the focus order, set 
B<-takefocus> to I<0>.

=item B<-resizeable> => I<boolean>

A value of B<1> indicates that it is okay for the user to resize
the columns by dragging the column separators. B<0> disables 
this function.  Default:  B<1>.

Note that you can also specify -resizeable on a column
by column basis. See the B<COLUMNS> section below.

=item B<-selectmode> => I<string>

Should be "single", "browse", "multiple", or "extended".
Default:  B<"browse">.  See L<Tk::HListbox>.

=item B<-separatorcolor> => I<string>

Specifies the color of the separator lines 
(the vertical lines that separates the columns). 
Default:  B<black>.

Note that you can also specify -separatorcolor on a column
by column basis. See the B<COLUMNS> section below.

=item B<-separatorwidth> => I<integer>

Specifies the width in pixels of the separator lines 
(the vertical lines that separates the columns). 
Default:  B<1>.

Note that you can also specify -separatorwidth on a column
by column basis. See the B<COLUMNS> section below.

=item B<-showcursoralways> I<boolean>

Starting with version 3.20 (and Tk::HListbox version 2.4), Tk::HMListbox 
no longer displays the keyboard cursor (active row) when the HMListbox 
widget does not have the keyboard focus, in order to be consistent with the 
behaviour of Tk::SMListbox and Tk::MListbox.  This option, when set to 1 
(or a "true" value) restores the pre-v3.20 behaviour of always showing the 
keyboard cursor.  Default I<0> (False).

=item B<-sortable> => I<boolean>

A value of B<1> indicates that it is okay for the user to sort
the data by clicking column headings. B<0> disables this function.
Default:  B<1>.

Note that you can also specify B<-sortable> on a column
by column basis. See I<COLUMNS> below.

=item B<-state>

Specifies one of two states for the listbox: B<normal> or B<disabled>.
If the listbox is disabled then user can interact with the widget in a very 
limited (read-only) way.  Items may not be selected, but currently, the 
list can be resorted or the columns potentially expanded for easier viewing.  
Items are drawn in the B<-disabledforeground> color, and selection
cannot be modified and is not shown (though selection information is
retained).

=item B<-takefocus> => I<number>

There are actually three different focusing options:  Specify B<1> to both 
allow the widget to take keyboard focus itself and to enable grabbing the 
keyboard focus when a user clicks on a row in the listbox.  Specify B<''> 
to allow the widget to take focus (via the <TAB> circulate order) but do 
not grab the focus when a user clicks on (selects) a row.  This is the 
default focusing model.  Specify B<0> to not allow the widget to receive 
the keyboard focus.

=item B<-tpadx> => I<number>

Specify horizontal padding style in pixels around the text 
for the rows in the listbox which are type I<text>.  
Default:  B<0>

=item B<-tpady> => I<number>

Specify vertical padding style in pixels around the text 
for the rows in the listbox which are type I<text>.  
This can be useful in correcting vertical misallignment between the 
columns when some columns contain images and others are text only!
NOTE:  This changes the height of the affected rows.
Default (seems to be):  B<2> (and setting to B<0> is the same as B<2>).

=back

=head1 WIDGET SPECIFIC, COLUMN-SPECIFIC OPTIONS

=over 4

=item B<-comparecmd> => I<callback>

Specifies a callback to use when sorting the HMListbox with this
column as key. The callback will be called with two scalar arguments,
each a value from this particular column. The callback should 
return an integer less than, equal to, or greater than 0, depending
on how the tow arguments are ordered. If for example the column
should be sorted by numerical value:

    -comparecommand => sub { $_[0] <=> $_[1]}

Default:  B<sub { $_[0] cmp $_[1] }>  #(Ascending by string)
NOTE:  If the column data is images or hashrefs (both 
text and images or contains additional cell-specific 
options, then one should specify a component of that 
hash to sort by, ie. the special "-sort" key is handy, then 
one can sort using something like:

	sub { $_[0]->{'-sort'} cmp $_[1]->{'-sort'} } or maybe:

	sub { $_[0]->{'-text'} cmp $_[1]->{'-text'} }

=item B<-itemtype> => "text" | "imagetext"

New option (not included with Tk::SMListbox or Tk::MListbox) that 
permits a column to contain either images and or text in it's
entries.  Valid values are "text" and "imagetext".  
Default:  B<"text">.

=item B<-reversearrow> => 0 | 1

New option (not included with the old Tk::MListbox) that 
causes the up / down direction of the sort arrow in the 
column header that shows the direction the sorted-by 
column is currently sorted.  Default:  B<0> (zero): (Up-arrow) 
if sorted in ascending order, Down-arrow if in 
descending order.  Setting to 1 reverses this.  This is 
often necessary to show desired results, ie. if the sort 
function is reversed, such as:  sub { $_[1] cmp $_[0] } 

=back

=head1 HMListbox COLUMN CONFIGURATION

NOTE:  See also the additional options described in the previous 
section "WIDGET SPECIFIC COLUMN-SPECIFIC OPTIONS".

The HMListbox widget is a collection of I<HMLColumn> widgets. 
Each HMLColumn contains a HListbox, a heading and the separator bar.
The columns are created and maintained through the -columns 
option or the column methods of the widget. The columns are indexed
from 0 and up. Initially, column 0 is the leftmost column of the
widget. The column indices B<are not changed> when the columns
are moved or hidden. The only ways to change the column indices 
are to call columnInsert(), columnDelete() or configure(-column).

Each column has its own set of options which might be passed to 
HMListbox::configure(-columns), HMListbox::insert(),
HMListbox::columnConfigure() or HMLColumn::configure().

The following code snippets are all equal:

1.  my $hml=$mw->HMListbox(-columns=>[[-text=>'Heading1',
                                  -sortable=>0],
                                 [-text=>'Heading2']]);

2.  my $hml=$mw->HMListbox;
    $hml->columnInsert(0,-text=>'Heading1', -sortable=>0);
    $hml->columnInsert(0,-text=>'Heading2');

3.  my $hml=$mw->HMListbox;
    $c=$hml->columnInsert(0,-text=>'Heading1');
    $hml->columnInsert(0,-text=>'Heading2');
    $c->configure(-sortable=>0);

4.  my $hml=$mw->HMListbox;
    $hml->columnInsert(0,-text=>'Heading1');
    $hml->columnInsert(0,-text=>'Heading2');
    $hml->columnConfigure(0,-sortable=>0);

(See the columnConfigure() method below for details on column options).

All column methods expects one or two column indices as arguments.
The column indices might be an integer (between 0 and the number
of columns minus one), 'end' for the last column, or a reference
to the HMLColumn widget (obtained by calling HMListbox->columnGet() 
or by storing the return value from HMListbox->columnInsert()).

=head1 WIDGET METHODS

=over 4

=item $hml->B<compound>(I<[left|right|top|bottom]>)

Gets / sets the side of the column header that the 
ascending / descending arrow is to appear (left, right, top, 
bottom).  Default:  I<"right">.

=item $hml->B<focusColumn>(I<[index]>)

DEPRECIATED:  Gets or sets the index of the column whose listbox 
is to receive the keyboard focus when the HMListbox widget receives 
keyboard focus.  This is a holdover from Tk::SMListbox, where it 
is useful to better display the active element cursor due to the 
fact that it depends on Tk::Listbox, which does not display the  
active element (usually underlined) unless the listbox itself has the 
focus.  This allows the programmer to specify a colum other than the 
first one, ie, if the main column of interest to the user is not the 
first one.

Tk::HMListbox depends instead on Tk::HListbox, which does 
display the active element without specifically being focused 
making it unnecessary to designate a specific widget to show the 
active cursor, so therefore all column listboxes show the active 
element regardless of which has the focus and Tk::HListbox can 
assign the first column (the default if this isn't specified here) 
the focus and everything displays properly.

NOTE:  none of this applies if B<-nocolumnfocus> is set, which 
also has the side effect of disabling most keyboard bindings on 
the HMListbox.  

=item $hml->B<getSortOrder>() 

Returns an array that is in the same format accepted by the 
$smListBox->sort method.  The 1st element is 
either true for descending sort, false for assending.  
Subsequent elements represent the column indices of one or 
more columns by which the data is sorted.
Default (if nothing previously set):  B<(0, 0)>.

=item $hml->B<setSortOrder>(I<descending>, I<columnindex>...) 

Sets the default sort order and columns to sort without actually 
sorting.  The arguments are the same as the sort() function.

=item $hml->B<setButtonHeight>([I<pady>])

Sets (alters) the "-pady" value for the header buttons.  
Should be called AFTER all columns have been created.  
Requires version 2 or higher.

=item $hml->B<showallsortcolumns>([I<1|0>])

Gets or sets whether a sort direction arrow is to be displayed 
on each column involved in the sorting or just the 1st 
(primary sort).  Default:  B<0> (false) - show arrow only on the 
primary sort column.

=item $hml->B<bindColumns>(I<sequence>,I<callback>)

Adds the binding to all column headers in the widget. See the section
BINDING EVENTS TO HMListbox below.

=item $hml->B<bindRows>(I<sequence>,I<callback>)

Adds the binding to all listboxes in the widget. See the section
BINDING EVENTS TO HMListbox below.

=item $hml->B<bindSeparators>(I<sequence>,I<callback>)

Adds the binding to all separators in the widget. See the section
BINDING EVENTS TO HMListbox below.

=back

=head2 COLUMN METHODS

(Methods for accessing and manipulating individual columns
in the HMListbox widget)

=over 4

=item $hml->B<columnConfigure>(I<index>,I<option>=>I<value>...)

Set option values for a specific column.
Equal to $hml->columnGet(I<index>)->configure(...).

The following column options are supported:

=over 4

=item B<-comparecommand> => I<callback>

Specifies a callback to use when sorting the HMListbox with this
column as key. The callback will be called with two scalar arguments,
each a value from this particular column. The callback should 
return an integer less than, equal to, or greater than 0, depending
on how the tow arguments are ordered. If for example the column
should be sorted by numerical value:

    -comparecommand => sub { $_[0] <=> $_[1]}

Default:  B<sub { $_[0] cmp $_[1] }>  #(Ascending by string)
NOTE:  If the column data is images or hashrefs (both 
text and images or contains additional cell-specific 
options, then one should specify a component of that 
hash to sort by, ie. the special "-sort" key is handy, then 
one can sort using something like:

	sub { $_[0]->{'-sort'} cmp $_[1]->{'-sort'} } or maybe:

	sub { $_[0]->{'-text'} cmp $_[1]->{'-text'} }

=item B<-text> => I<string>

Specifies the text to be used in the heading button of the column.

=item B<-resizeable> => I<boolean>

A value of B<1> indicates that it is okay for the user to resize
this column by dragging the separator. B<0> disables this function.
Default:  B<1>.

=item B<-separatorcolor> => I<string>

Specifies the color of the separator line.  Default:  B<black>.

=item B<-separatorwidth> => I<integer>

Specifies the width of the separator line in pixels.  Default:  B<1>.

=item B<-sortable> => I<boolean>

A value of B<1> indicates that it is okay for the user to sort
the data by clicking this column's heading. B<0> disables this 
function.  Default:  B<1>.

=item B<-itemtype> => "text" | "imagetext"

New option (not included with Tk::SMListbox or Tk::MListbox) that 
permits a column to contain either images and or text in it's
entries.  Valid values are "text" and "imagetext".  
Default:  B<"text">.

=item B<-reversearrow> => 0 | 1

New option (not included with the old Tk::MListbox) that 
causes the up / down direction of the sort arrow in the 
column header that shows the direction the sorted-by 
column is currently sorted.  Default:  B<0> (zero) - (Up-arrow 
if sorted in ascending order, Down-arrow if in 
descending order.  Setting to 1 reverses this.  This is 
often necessary to show desired results, ie. if the sort 
function is reversed, such as:  sub { $_[1] cmp $_[0] } 

=back

=item $hml->B<columnDelete>(I<first>,I<last>)

If I<last> is omitted, deletes column I<first>. If I<last> is
specified, deletes all columns from I<first> to I<last>, inclusive.

All previous column indices greater than I<last> (or I<first> if
I<last> is omitted) are decremented by the number of columns 
deleted.

=item $hml->B<columnGet>(I<first>,I<last>)

If I<last> is not specified, returns the HMLColumn widget specified by I<first>.
If both I<first> and I<last> are specified, returns an array containing all
columns from I<first> to I<last>.

=item $hml->B<columnHide>(I<first>,I<last>)

If I<last> is omitted, hides column I<first>. If I<last> is
specified, hides all columns from I<first> to I<last>, inclusive.

Hiding a column is equal to calling $hml->columnGet(I<index>)->packForget. 
The column is B<not> deleted, all data are still available, 
and the column indices remain the same.

See also the columnShow() method below.

=item $hml->B<columnIndex>(I<index>)

Returns an integer index for the column specifed by I<index>.

=item $hml->B<columnInsert>(I<index>,I<option>=>I<value>...)

Creates a new column in the HMListbox widget. The column will 
get the index specified by I<index>. If I<index> is 'end', the
new column's index will be one more than the previous highest
column index.

If column I<index> exists, the new column will be placed
to the B<left> of this column. All previous column indices 
equal to or greater than I<index> will be incremented by one.

Returns the newly created HMLColumn widget.

(See the columnConfigure() method above for details on column options).

=item $hml->B<columnPack>(I<array>)

Repacks all columns in the HMListbox widget according to the 
specification in I<array>. Each element in I<array> is a string
on the format B<index:width>. I<index> is a column index, I<width> 
defines the columns width in pixels (may be omitted). The columns 
are packed left to right in the order specified by by I<array>.
Columns not specified in I<array> will be hidden.

This method is most useful if used together with the 
columnPackInfo() method.

=item $hml->B<columnPackInfo>()

Returns an array describing the current layout of the HMListbox
widget. Each element of the array is a string on the format
B<index:width> (see columnPack() above). Only indices of columns that 
are currently shown (not hidden) will be returned. The first element
in the returned array represents the leftmost column.

This method may be used in conjunction with columnPack() to save
and restore the column configuration. 

=item $hml->B<columnShow>(I<index>,I<option>=>I<value>)

Shows a hidden column (see the columnHide() method above). 
The column to show is specified by I<index>.

By default, the column is pack'ed at the rigthmost end of the
HMListbox widget. This might be overridden by specifying one of
the following options:

=item B<-after> => I<index>

Place the column B<after> (to the right of) the column specified
by I<index>.

=item B<-before> => I<index>

Place the column B<before> (to the left of) the column specified
by I<index>.

=back

=head2 ROW METHODS

(Methods for accessing and manipulating rows of data)

Many of the methods for HMListbox take one or more indices as 
arguments. See L<Tk::HListbox> for a description of row indices.

=over 4

=item $hml->B<delete>(I<first>,I<last>)

Deletes one or more row elements of the HMListbox. I<First> and I<last>
are indices specifying the first and last elements in the range to 
delete. If I<last> isn't specified it defaults to B<first>, 
i.e. a single element is deleted. 

=item $hml->B<get>(I<first>,I<last>)

If I<last> is omitted, returns the content of the HMListbox row
indicated by I<first>. If I<last> is specified, the command returns
a list whose elements are all of the listbox rows between 
I<first> and I<last>.

The returned elements are all array references. The referenced
arrays contains one element for each column of the HMListbox.

=item $hml->B<getRow>(I<index>)

In scalar context, returns the value of column 0 in the HMListbox
row specified by I<index>. In list context, returns the content
of all columns in the row as an array.

This method is provided for convenience, since retrieving a single
row with the get() method might produce some ugly code.

The following two code snippets are equal:

   1. @row=$hml->getRow(0);

   2. @row=@{($hml->get(0))[0]};


=item $hml->B<sort>(I<descending>, I<columnindex>...)

Sorts the content of the HMListbox. If I<descending> is a B<true> 
value, the sort order will be descending.  Default is  B<0> - ascending
sort on B<first> column (0).

If I<columnindex> is specified, the sort will be done with the 
specified column as key. You can specify as many I<columnindex>
arguments as you wish. Sorting is done on the first column, then
on the second, etc...

The default is to sort the data on all columns of the listbox, 
with column 0 as the first sort key, column 1 as the second, etc.

=back

=head1 OTHER LISTBOX METHODS

Most other Tk::HListbox methods works for the HMListbox widget.  This
includes the methods activate, cget, curselection, index, nearest, see,
selectionXXX, size, xview, yview.

See L<Tk::HListbox>

=head1 BINDING EVENTS TO HMLISTBOX

Calling $hml->bind(...) probably makes little sense, since the call does not
specify whether the binding should apply to the listbox, the header button 
or the separator line between each column.

In stead of the ordinary bind, the following methods should be used:

=over 4

=item $hml->B<bind>(I<sequence>,I<callback>)

Synonym for $hml->B<bindRows>(I<sequence>,I<callback>).

=item $hml->B<bindRows>(I<sequence>,I<callback>)

Synonym for $hml->B<bindSubwidgets>('listbox',I<sequence>,I<callback>)

=item $hml->B<bindColumns>(I<sequence>,I<callback>)

Synonym for $hml->B<bindSubwidgets>('heading',I<sequence>,I<callback>)

=item $hml->B<bindSeparators>(I<sequence>,I<callback>)

Synonym for $hml->B<bindSubwidgets>('separator',I<sequence>,I<callback>)

=item $hml->B<bindSubwidgets>(I<subwidget>,I<sequence>,I<callback>)

Adds the binding specified by I<sequence> and I<callback> to all subwidgets
of the given type (should be 'listbox', 'heading' or 'separator'). 

The binding is stored in the widget, and if you create a new column 
by calling $hml->columnInsert(), all bindings created by $hml->bindSubwidgets()
are automatically copied to the new column.

The callback is called with the HMListbox widget as first argument, and
the index of the column where the event occured as the second argument.

NOTE that $hml->bindSubwidgets() does not support all of Tk's callback formats.
The following are supported:

     \&subname
     sub { code }
     [ \&subname, arguments...]
     [ sub { code }, arguments...]

If I<sequence> is undefined, then the return value is a list whose elements 
are all the sequences for which there exist bindings for I<subwidget>.

If I<sequence> is specified without I<callback>, then the callback currently 
bound to sequence is returned, or an empty string is returned if there is no
binding for sequence.

If I<sequence> is specified, and I<callback> is an empty string, then the
current binding for sequence is destroyed, leaving sequence unbound. 
An empty string is returned.

An empty string is returned in all other cases.

=back

=head1 KEYWORDS

hmlistbox, smlistbox, mlistbox, listbox, hlist, widget

=head1 SEE ALSO

L<Tk::SMListbox> L<Tk::MListbox> L<Tk::HListbox>

=cut

## Tk::HMListbox
##
## Tk::HMListbox is a Tk::HList-based derivitive of Tk::SMListbox that 
## adds the ability to include either image icons or text (or both) 
## columns along with other HList-specific style and configuration options.
##
## Tk::HMListbox adds 2 new options:  "itemtype", and "reversearrow".
##
##############################################################################
## MListbox Version 1.11 (26 Dec 2001)
##
## Original Author: Hans J. Helgesen, Dec 1999  
## Maintainer: Rob Seegel (versions 1.10+)
##
## This version is a maintenance release of Hans' MListbox widget.
## I have tried to avoid adding too many new features and just ensure 
## that the existing ones work properly.
## 
## Please post feedback to comp.lang.perl.tk or email to RobSeegel@aol.com
##
## This module contains four classes. Of the four, HMListbox is
## is the only one intended for standalone use, the other three:
## HMCListbox, HMLColumn, HMButton are accessible as Subwidgets, but
## not intended to be used in any other way other than as 
## components of HMListbox.
##
##############################################################################
## HMCListbox is similar to an ordinary listbox, but with the following 
## differences:
## - Calls an -updatecommand whenever something happens to it.
## - Horizontal scanning is disabled, calls -xscancommand to let parent widget
##   handle this.

{
	package Tk::HMListbox::HMCListbox;
	use base qw(Tk::Derived Tk::HListbox);

	Tk::Widget->Construct('HMCListbox');

	sub Populate {
		my ($w, $args) = @_;
		$w->SUPER::Populate($args);
		$w->ConfigSpecs(
				-updatecommand => ['CALLBACK'],
				-xscancommand  => ['CALLBACK'],
		);
	}

	sub selectionSet {   #JWT:NOTE:Callback->can() EATS 1ST ARGUMENT, SO WE MUST *NOT* SHIFT @_!!!
		my ($w) = @_;
		$w->Callback(-updatecommand=>$w->can('Tk::HListbox::selectionSet'),@_);
	}

	sub selectionClear {
		my ($w) = @_;
		$w->Callback(-updatecommand=>$w->can('Tk::HListbox::selectionClear'),@_);
	}

	sub selectionAnchor {
		my ($w) = @_;
		$w->Callback(-updatecommand=>$w->can('Tk::HListbox::selectionAnchor'),@_);
	}

	sub activate {
		my ($w) = @_;
		$w->Callback(-updatecommand=>$w->can('Tk::HListbox::activate'),@_);
	}

	sub see {
		my ($w) = @_;
		$w->Callback(-updatecommand=>$w->can('Tk::HListbox::see'),@_);
	}

	sub yview {
		my ($w) = @_;  #JWT:NOTE:Callback->can() EATS 1ST ARGUMENT, SO WE MUST *NOT* SHIFT @_!!!
		@args = @_;
		shift @args;   #JWT:NOTE:WE DO SHIFT THE MODULE OFF BEFORE CALLING yview, ETC. DIRECTLY!
		$w->Callback(-updatecommand=>$w->can('Tk::HListbox::yview'),@_);
		$w->Tk::HListbox::yview  unless (@args);   #JWT:REQUIRED BY _yscrollCallback!
	}

	sub scan {
		my ($w,$type,$x,$y) = @_;
		# Disable horizontal scanning.
		if ($type eq 'mark') {
			$w->{'_scanmark_x'} = $x;
		}
		$w->Callback(-updatecommand=>$w->can('Tk::HListbox::scan'),
				$w, $type, $w->{'_scanmark_x'}, $y
		);
		$w->Callback(-xscancommand=>$type,$x);
	}

	sub SpaceSelect
	{
		my ($w) = @_;
#		$w->Callback(-updatecommand=>$w->can('Tk::HListbox::SpaceSelect'),@_);
		eval { shift; $w->Tk::HListbox::SpaceSelect(@_); };
	}

	sub CtrlPriorNext
	{
		my ($w) = @_;
		$w->Callback(-updatecommand=>$w->can('Tk::HListbox::CtrlPriorNext'),@_);
	}
}

##############################################################################
## HMButton is like an ordinary Button, but with an addition option:
## -pixelwidth
## The new configure method makes sure the pixelwidth is always retained.
{
	package Tk::HMListbox::HMButton;
	use base qw(Tk::Derived Tk::Button);   
	Tk::Widget->Construct('HMButton');

	sub Populate {
		my ($w, $args) = @_;
		$w->SUPER::Populate($args);
		$w->ConfigSpecs(
				-pixelwidth => ['PASSIVE'],
				-bitmap => [qw/SELF bitmap bitmap/, 'noarrow'],
				-compound => [qw/SELF compound compound/, 'right'],
				-background    => [qw/SELF background Background/, $Tk::NORMAL_BG],
				-foreground    => [qw/SELF foreground Foreground/, $Tk::NORMAL_FG]
		);
	}

	sub configure {
		my $w = shift;
		my (@ret) = $w->SUPER::configure(@_);
		unless (@ret) {
			if (defined(my $pixels = $w->cget('-pixelwidth'))) {
				$w->GeometryRequest($pixels,$w->reqheight);
			}
		}
		return @ret;
	}
}

###############################################################################
## HMLColumn implements a single column in the HMListbox. HMLColumn is a composite
## containing a heading (an HMButton), a listbox (HMCListbox) and a frame which  
## frame which serves as a draggable separator 
{
	package Tk::HMListbox::HMLColumn;
	use base qw(Tk::Frame);
	Tk::Widget->Construct('HMLColumn');

	sub Populate {
		my ($w, $args) = @_;
		my $undln = delete($args->{'-underline'});
		$w->SUPER::Populate($args);
		my $hdrBG = $args->{'-headerbackground'} || $args->{'-background'} || undef;
		my $hdrFG = $args->{'-headerforeground'} || $args->{'-foreground'} || undef;
		my $disableFG = $args->{'-disabledforeground'} || $Tk::DISABLED_FG;

		## HMLColumn Components
		## $sep - separator - Frame
		## $hdr - heading    - HMButton
		## $f   - frame     - Frame    
		## $lb  - listbox   - HMCListbox

		my $sep = $w->Component(
				Frame   => 'separator',
				-height => 1,
				-takefocus => 0,
		)->pack(qw/-side right -fill y -anchor w/);

		$sep->bind( "<B1-Motion>", 
		[$w=>'adjustMotion']);
		$sep->bind("<ButtonRelease-1>", 
		[$w=>'Callback','-configurecommand']);

		my $f = $w->Component(
				Frame => "frame",
				-takefocus => 0,
		)->pack(qw/-side left -anchor n -fill both -expand 1/);

		my $hdr;
		if (defined $undln) { 
		
			$hdr = $f->HMButton(
					-takefocus=>0,
					-padx=>0,
					-width=>1,
					-borderwidth=>2,
					-underline=>$undln,
					-highlightthickness=>0
			)->pack(qw/-side top -anchor n -fill x -expand 0/);
		} else {
			$hdr = $f->HMButton(
					-takefocus=>0,
					-padx=>0,
					-width=>1,
					-borderwidth=>2,
					-highlightthickness=>0
			)->pack(qw/-side top -anchor n -fill x -expand 0/);
		}
		$w->Advertise("heading" => $hdr);

		my $lb;
		my $dynamic = <<'END_STR';
			$lb = $f->HMCListbox(
					-highlightthickness=>0,
					-relief=>'flat',
					-bd=>0,
					-exportselection=>0,
					-takefocus=>0,
END_STR

		if ($Tk::HListbox::VERSION >= 2.3) {
			foreach my $padarg (qw/-tpady -tpadx -ipady -ipadx/) {
				$dynamic .= " $padarg => $args->{$padarg},"  if (defined($args->{$padarg}) && $args->{$padarg} =~ /\d/o);
			}
			$dynamic .= "-showcursoralways => 1,"  if ($Tk::HListbox::VERSION >= 2.4);
			if ($Tk::HListbox::VERSION >= 2.42) {
				$dynamic .= "-state => '".$args->{'-state'}."',";
				$dynamic .= "-disabledforeground => '".$args->{'-disabledforeground'}."',"
						if (defined $args->{'-disabledforeground'});
			}
		} else {
			foreach my $padarg (qw/-tpady -tpadx -ipady -ipadx/) {
				delete $args->{$padarg}  if (defined $args->{$padarg});
			}
		}
		$dynamic =~ s/\,$/\)\;/;
		eval $dynamic;
		$lb->pack(qw/-side top -anchor n -expand 1 -fill both/);
		$w->Advertise("listbox" => $lb);
		$w->Delegates (DEFAULT => $lb);

		my $bgWidgets = $hdrBG ? [$f, $lb] : [$f, $hdr, $lb];
		my $fgWidgets = $hdrFG ? [$f, $lb] : [$f, $hdr, $lb];
		$w->ConfigSpecs(
#				-background     => [[$f, $lb], 
				-background     => [$bgWidgets, 
						qw/background Background/, $Tk::NORMAL_BG],
				-comparecommand => ['CALLBACK', undef, undef,
						sub{$_[0] cmp $_[1]}],
				-configurecommand => ['CALLBACK'],

				-font           => [[$hdr, $lb], qw/font Font/, undef],
#				-foreground     => [[$lb],
				-foreground     => [$fgWidgets,
						qw/foreground Foreground/, $Tk::NORMAL_FG],
				-headerbackground => [qw/PASSIVE headerBackground HeaderBackground/, $hdrBG],
				-headerforeground => [qw/PASSIVE headerForeground HeaderForeground/, $hdrFG],
				-disabledforeground => [qw/PASSIVE disabledForeground DisabledForeground/, $disableFG],
				-separatorwidth => [{-width => $sep}, 
						qw/separatorWidth Separator 1/],
				-separatorcolor => [{-background => $sep}, 
						qw/separatorColor Separator black/],
				-resizeable     => [qw/METHOD resizeable Resizeable 1/],
				-sortable       => [qw/PASSIVE sortable Sortable 1/],
				-text           => [$hdr],
				-compound       => [[$hdr], 'compound', 'compound', 'right'],
				-updatecommand  => [$lb],
				-textwidth      => [{-width => [$lb, $hdr]}],
				-reversearrow   => [qw/PASSIVE reversearrow reversearrow 0/],
				-state          => ['METHOD', 'state',  'State',   'normal'],
				-ipadx          => [qw/PASSIVE/],
				-ipady          => [qw/PASSIVE/],
				-tpadx          => [qw/PASSIVE/],
				-tpady          => [qw/PASSIVE/],
				DEFAULT         => [$lb]
		);
		$w->ConfigAlias(
				-comparecmd => '-comparecommand',
				-width      => '-textwidth'
		);

		$hdr->configure('-background' => $hdrBG)  if ($hdrBG);
		$hdr->configure('-foreground' => $hdrFG)  if ($hdrFG);
	}

######################################################################
## HMLColumn Configuration methods (call via configure/cget). 
######################################################################

	sub resizeable {
		my ($w, $value) = @_;
		return $w->{Configure}{-resizeable}  unless (defined $value);

		$w->Subwidget("separator")->configure(
				-cursor => ($value ? 'sb_h_double_arrow' : 'xterm')
		);
	}

	sub compare {
#		my ($w,$a,$b) = @_;

#		$w->Callback(-comparecommand => $a, $b);
		shift->Callback(-comparecommand => $_[0], $_[1]);
	}

	sub setWidth {
		my ($w, $pixels) = @_;
		$pixels -= $w->Subwidget("separator")->width;
		return  unless ($pixels >= 0);

		$w->Subwidget("listbox")->GeometryRequest(
		$pixels,$w->Subwidget("listbox")->height);
		$w->Subwidget("heading")->configure(-pixelwidth=>$pixels);
	}

######################################################################
## HMLColumn Private  methods (Do not depend on these methods being present)
######################################################################

	sub _setButtonHeight {
		my $w = shift;
		my $pady = shift;
		$w->Subwidget("heading")->configure(-pady => $pady)  if (defined $pady);
	}

## Adjust size of column.
	sub adjustMotion {
		my ($w) = @_;
		return  if ($w->getState() =~ /d/o);

		$w->setWidth($w->pointerx - $w->rootx)  if ($w->resizeable);
	}

	sub state {
		my $w = shift;
		my $state = shift;
#FOOBARS FOCUS?!		return $w->{Configure}{'-state'} || undef  unless (defined($state) && $state);

		$w->Subwidget("listbox")->configure('-state' => $state, -takefocus => 0);
		$w->Subwidget("heading")->configure('-state' => $state, -takefocus => 0);
		$w->{'_hlistboxstate'} = $state;
	}

	sub getState {
		return shift->{'_hlistboxstate'};
	}

} ## END PRELOADING OF HMLColumn

######################################################################
## Package: Tk::HMListbox
## Purpose: Multicolumn widget used to display tabular data
##          with optional sorted-column indicator arrows and keyboard-
##          bound column-sorting capability.
##          This widget has the ability to sort data by column,
##          hide/show columns, and the ability to change the order
##          of columns on the fly

package Tk::HMListbox;
use strict;
use Carp;
use vars qw($VERSION);
$VERSION = '4';

use Tk;

## Overidden Scrolled method to suit the purposes of HMListbox
## I want -columns to be configured LAST no matter what.
## I know full well that I'm overriding the Scrolled method
## and I don't need a warning broadcasting the fact.

no warnings;

sub Tk::Widget::Scrolled {
	my ($parent, $kind, %args) = @_;

	my $colAR;
	$colAR = delete $args{'-columns'} if $kind eq "HMListbox";

	## Find args that are Frame create time args
	my @args = Tk::Frame->CreateArgs($parent,\%args);
	my $name = delete $args{'Name'};
	push(@args,'Name' => $name) if (defined $name);
	my $cw = $parent->Frame(@args);
	@args = ();
	my $scrollbarfocus = (defined $args{'-scrollbarfocus'}) ? delete($args{'-scrollbarfocus'}) : undef;

	## Now remove any args that Frame can handle
	foreach my $k ('-scrollbars',map($_->[0],$cw->configure)) {
		push(@args,$k,delete($args{$k})) if (exists $args{$k})
	}
	## Anything else must be for target widget - pass at widget create time
	my $w  = $cw->$kind(%args);
	$cw->{'__HMListbox__'} = $w  if ($w =~ /HMListbox/o);  #JWT:SAVE ME FOR USE IN THE LEFT-TAB BIND ABOVE!
	## Now re-set %args to be ones Frame can handle
	## RCS NOTE: I've also slightly modified the ConfigSpecs
	%args = @args;
	$args{'-scrollbarfocus'} = $scrollbarfocus  if (defined($scrollbarfocus) && $scrollbarfocus =~ /[xy01]/);
	$cw->ConfigSpecs(
			'-scrollbars' => [qw/METHOD   scrollbars Scrollbars se/],
			'-background' => [$w, qw/background Background/, undef],
			'-foreground' => [$w, qw/foreground Foreground/, undef],
			'-scrollbarfocus' => ['METHOD', 'scrollbarfocus', 'Focus', ''],
	);
	$cw->AddScrollbars($w);
	$cw->Default("\L$kind" => $w);
	$cw->Delegates('bind' => $w, 'bindtags' => $w, 'menu' => $w);
	$cw->ConfigDefault(\%args);
	delete($args{'-scrollbarfocus'})  if (defined $args{'-scrollbarfocus'});  #DELETE IT AGAIN SO THIS ONE WON'T BITCH!
	$cw->configure(%args);
	$args{'-scrollbarfocus'} = $scrollbarfocus  if (defined($scrollbarfocus) && $scrollbarfocus =~ /[xy01]/);
	$cw->configure(-columns => $colAR) if $colAR;
	$w->scrollbarfocus($scrollbarfocus)  if ($scrollbarfocus =~ /[xy01]/);

	#JWT:FOR SOME STUPID REASON THIS 1 DIRECTIONAL BINDING REQUIRES A SLIGHT FRACTION ABOVE ZERO?!
	#(THE OTHER 3 WORK FINE AUTOMATICALLY!) :-/
	$w->parent->Subwidget('yscrollbar')->bind('<Home>', sub {
		$cw->{'__HMListbox__'}->_chgView('yview','moveto',0.0001)  if (defined $cw->{'__HMListbox__'});
	});
	return $cw;
}

use warnings;

require Tk::Pane;
use base qw(Tk::Frame);
Tk::Widget->Construct('HMListbox');

sub ClassInit {
	my ($class,$mw) = @_;
	$mw->bind($class,'<Configure>',['_yscrollCallback']);
	$mw->bind($class,'<Down>',['_upDown',1]);
	$mw->bind($class,'<Up>',  ['_upDown',-1]);
	$mw->bind($class,'<Control-Down>',['_ctrlupDown',1]);
	$mw->bind($class,'<Control-Up>',  ['_ctrlupDown',-1]);
	$mw->bind($class,'<Shift-Up>',  ['_extendUpDown',-1]);
	$mw->bind($class,'<Shift-Down>',['_extendUpDown',1]);
	$mw->bind($class,'<Control-Home>','_cntrlHome');
	$mw->bind($class,'<Control-End>','_cntrlEnd');
	$mw->bind($class,'<Shift-Control-Home>',['_dataExtend',0]);
	$mw->bind($class,'<Shift-Control-End>',['_dataExtend',Ev('index', 'end')]);
	$mw->bind($class,'<Control-slash>','_selectAll');
	$mw->bind($class,'<Control-backslash>','_deselectAll');
	$mw->bind($class,'<FocusIn>','focus');
	$mw->bind($class,'<FocusOut>','unfocus');
	$mw->bind($class,'<Escape>', '_Cancel'); 
	$mw->bind($class, '<Home>',  ['_chgView','xview','moveto',0.001]);
	$mw->bind($class, '<End>',   ['_chgView','xview','moveto',1]);
	$mw->bind($class, '<Prior>',  ['_chgView','yview','scroll',-1,'pages']);
	$mw->bind($class, '<Next>',   ['_chgView','yview','scroll',1,'pages']);
	$mw->bind($class, '<Control-Prior>', ['CtrlPriorNext',-1]);
	$mw->bind($class, '<Control-Next>', ['CtrlPriorNext',1]);
	$mw->bind($class,'<space>',['SpaceSelect',Ev('index','active')]);
	$mw->bind($class,'<Select>',['SpaceSelect',Ev('index','active')]);

	my $downArrowBits = pack("b10"x10,
			"..........",
			"..........",
			"..........",
			".#########",
			"..#######.",
			"...#####..",
			"....###...",
			".....#....",
			"..........",
			".........."
	);
	$mw->DefineBitmap('downarrow' => 10,10, $downArrowBits);
	my $upArrowBits = pack("b10"x10,
			"..........",
			"..........",
			"..........",
			".....#....",
			"....###...",
			"...#####..",
			"..#######.",
			".#########",
			"..........",
			".........."
	);
	$mw->DefineBitmap('uparrow' => 10,10, $upArrowBits);
	my $noArrowBits = pack("b10"x10,
			"..........",
			"..........",
			"..........",
			"..........",
			"..........",
			"..........",
			"..........",
			"..........",
			"..........",
			".........."
	);
	$mw->DefineBitmap('noarrow' => 10,10, $noArrowBits);

}

## Do some slightly tricky stuff: The -columns option, if called is
## guaranteed to be confiugred last of all the options submitted.
## NOTE: The args hash is cleared out if a columns option is sent
## so that all the options won't be reconfigured again immediately
## after this method finishes. ALso, if Scrolled is called, then
## the -columns option will never make it down to this level so 

sub Populate {
	my ($w, $args) = @_;

	$w->{'-showcursoralways'} = delete($args->{'-showcursoralways'})  if (defined $args->{'-showcursoralways'});
#    $w->SUPER::Populate($args);   

	$w->{'_columns'} = [];          ## Array of HMLColumn objects 
	$w->{'_sortcol'} = -1;          ## Column used for sorting
	$w->{'_sortcolumns'} = [];
	$w->{'_sort_descending'} = 0;   ## Flag for ascending/desc. sort order
	$w->{'_top'} = 0;
	$w->{'_bottom'} = 0;
	$w->{'_lastactive'} = 0;
	$w->{'_hasfocus'} = 0;

	my $pane = $w->Component(
			Pane => "pane",
			-sticky => 'nsew',
			-takefocus => 0,
	)->pack(-expand=>1,-fill=>'both');

	my $font;
	if ($Tk::platform eq 'MSWin32') {
		$font = "{MS Sans Serif} 8";
	} else {
		$font = "Helvetica -12 bold";
	}

	my $hdr = $w->Subwidget('heading');

	$w->ConfigSpecs(
			-background        => [qw/METHOD background Background/, $Tk::NORMAL_BG ],
			-columns           => [qw/METHOD/],
			-configurecommand  => [qw/CALLBACK/],
			-font              => [qw/METHOD font Font/, $font],
			-foreground        => [qw/METHOD foreground Foreground/, $Tk::NORMAL_FG ],
			-headerbackground  => [qw/METHOD headerbackground headerBackground/, $Tk::NORMAL_BG ],
			-headerforeground  => [qw/METHOD headerforeground headerForeground/, $Tk::NORMAL_FG ],
			-height            => [qw/METHOD height Height 10/],
			-moveable          => [qw/PASSIVE moveable Moveable 1/],
			-resizeable        => [qw/METHOD resizeable Resizeable 1/],
			-selectbackground  => [qw/METHOD selectBackground Background/, $Tk::SELECT_BG],
			-selectborderwidth => [qw/METHOD selectBorderwidth Borderwidth 1/],
			-selectforeground  => [qw/METHOD selectForeground Foreground/, $Tk::SELECT_FG],
			-disabledforeground => [qw/PASSIVE disabledForeground DisabledForeground/, $Tk::DISABLED_FG],
			-selectmode        => [qw/METHOD selectMode Mode browse/],
			-compound          => [qw/METHOD compound compound right/],
			-showallsortcolumns      => [qw/METHOD showallsortcolumns showallsortcolumns 0/],
			-jwtlistboxhack    => [qw/PASSIVE jwtlistboxhack jwtlistboxhack 0/],  #NOW USELESS (W/HList), LEFT FOR BACK-COMPAT.
			-fillcolumn        => [qw/PASSIVE fillcolumn fillColumn -1/],
			-focuscolumn       => [qw/PASSIVE focuscolumn focusColumn -1/],
			-nocolumnfocus     => [qw/PASSIVE nocolumnfocus nocolumnfocus 0/],
			-separatorcolor    => [qw/METHOD separatorColor Foreground black/],
			-separatorwidth    => [qw/METHOD separatorWidth SeparatorWidth 1/], 
			-sortable          => [qw/METHOD sortable Sortable 1/],
			-itemtype          => [qw/PASSIVE itemtype Itemtype text/],
			-takefocus         => ['METHOD', 'takeFocus', 'TakeFocus', ''],
			-textwidth         => [qw/METHOD textWidth Width 10/],
			-width             => [qw/METHOD width Width/, undef],
			-xscrollcommand    => [$pane],
			-yscrollcommand    => ['CALLBACK'],  
			-ipadx             => [qw/PASSIVE/],
			-ipady             => [qw/PASSIVE/],
			-tpadx             => [qw/PASSIVE/],
			-tpady             => [qw/PASSIVE/],
			-showcursoralways  => [qw/PASSIVE showcursoralways showcursoralways 0/],
			-state             => ['METHOD',  'state',         'State',   'normal'],
	);

	$w->ConfigAlias(
			-selectbg => "-selectbackground",
			-selectbd => "-selectborderwidth",
			-selectfg => "-selectforeground",
			-sepcolor => "-separatorcolor",
			-sepwidth => "-separatorwidth",
	);
	#JWT:HAD TO DO THESE THIS WAY INSTEAD OF IN THE CLASS, ELSE THEY DON'T WORK!:
	$w->bindRows('<Home>',  ['_chgView', 'xview','moveto',0.001]);
	$w->bindRows('<End>',   ['_chgView', 'xview','moveto',1]);
	$w->bindRows('<Control-ButtonPress-1>', ['CtrlButtonPress', Ev('index',Ev('@'))]);

	$w->bindRows('<ButtonPress-1>', [sub {
		my $w = shift;
		my $clickedon = $_[0];

		if (Tk::Exists($w)) {
			return  if ($w->{Configure}{'-state'} =~ /d/o);
			$w->focus  if (!$w->{'_hasfocus'} && $w->{'_ourtakefocus'});
		}
	}, Ev('index',Ev('@'))]
	);

	$w->bindRows('<Alt-ButtonPress-1>', [sub {
		my $w = shift;
		my $clickedon = $_[0];

		if (Tk::Exists($w)) {
			return  if ($w->{Configure}{'-state'} =~ /d/o);
			my $index = $w->_firstVisible->index('anchor');
			$w->focus  if (!$w->{'_hasfocus'} && $w->{'_ourtakefocus'});
			$w->activate($index);
		}
	}, Ev('index',Ev('@'))]
	);
}

sub CtrlButtonPress {
	my $w = shift;
	return  unless (defined $w->_firstVisible);

	my $clickedon = $w->_firstVisible->index('active');
	my @cursel = $w->_firstVisible->curselection;
	if (Tk::Exists($w)) {
		return  if ($w->{Configure}{'-state'} =~ /d/o);
		$w->activate($w->_firstVisible->index('anchor'));
	}
}

sub scrollbarfocus { #JWT:  ALLOW THEM TO SPECIFY WHICH, IF ANY SCROLLBARS TAKE FOCUS:
	my $w = shift;
	my $focusopt = shift;
	return $w->{Configure}{'-scrollbarfocus'} || undef  unless (defined($focusopt));

	if ($focusopt eq '0') {
		$w->parent->Subwidget('xscrollbar')->configure(-takefocus => 0);
		$w->parent->Subwidget('yscrollbar')->configure(-takefocus => 0);
	} elsif (! $focusopt) {
		return;
	} elsif ($focusopt eq '1' || ($focusopt =~ /x/o && $focusopt =~ /y/o)) {
		$w->parent->Subwidget('xscrollbar')->configure(-takefocus => 1);
		$w->parent->Subwidget('yscrollbar')->configure(-takefocus => 1);
	} elsif ($focusopt =~ /x/o) {
		$w->parent->Subwidget('xscrollbar')->configure(-takefocus => 1);
		$w->parent->Subwidget('yscrollbar')->configure(-takefocus => 0);
	} elsif ($focusopt =~ /y/o || $focusopt !~ /x/o) {
		$w->parent->Subwidget('yscrollbar')->configure(-takefocus => 1);
		$w->parent->Subwidget('xscrollbar')->configure(-takefocus => 0);
	}
}

sub getSortOrder {   #JWT:  ADDED THIS METHOD TO FETCH HOW THE LIST IS SORTED!
	my $w = shift;

	my @l = scalar(@{$w->{'_sortcolumns'}}) ? @{$w->{'_sortcolumns'}} : (0);
	return ($w->{'_sort_descending'}||0, @l);
}

sub setSortOrder {   #JWT:  ADDED THIS METHOD TO FETCH HOW THE LIST IS SORTED!
	my $w = shift;
	my ($sOrder, @sColumns) = @_;

	$w->{'_sort_descending'} = $sOrder;
	$w->{'_sortcolumns'} = [@sColumns]  if (defined $sColumns[0]);
}

######################################################################
## Configuration methods (call via configure). 
######################################################################

## Background is a slightly tricky option, this option would be a 
## great candidate for "DESCENDANTS", except for the separator subwidget in
## each column set by separatorcolor which I'd prefer not to set in such
## a clumsy way. All other background colors are fair game, but I'd like 
## to leave open the possibility for other exceptions such as separator. 
## Besides I prefer that composite subwidgets manage their own component parts
## as much as possible.

sub background { 
	my ($w, $val) = @_;
	return $w->{Configure}{'-background'}
	unless $val;

	## Ensure that the base Frame, pane and columns (if any) get set
	Tk::configure($w, "-background", $val);
	$w->Subwidget("pane")->configure("-background", $val);
	$w->_configureColumns("-background", $val);
}

## columns needs to be called last during creation time if set and I 
## went to a great deal of trouble to guarantee this. The reason
## being is that it needs to use many of the other configurations to
## use as defaults for columns, and the ability to override any of them
## for individual columns. If these options (that the columns override)
## were called afterwards, then the reverse would happen. All the default
## would override the individually specified options.

sub columns {
	my ($w, $vAR) = @_;
	return $w->{Configure}{'-columns'}  unless (defined $vAR);

	$w->columnDelete(0, 'end');
	map {$w->columnInsert('end', @$_)} @$vAR; 
}

sub font              { shift->_configureColumns('-font', @_) }
sub foreground        { shift->_configureColumns('-foreground', @_) }
sub headerbackground  { shift->_configureColumns('-headerbackground', @_);  }
sub headerforeground  { shift->_configureColumns('-headerforeground', @_);  }
sub disabledforeground { shift->_configureColumns('-disabledforeground', @_);  }
sub height            { shift->_configureColumns('-height', @_) }
sub resizeable        { shift->_configureColumns('-resizeable', @_) }
sub selectbackground  { shift->_configureColumns('-selectbackground', @_) }
sub selectborderwidth { shift->_configureColumns('-selectborderwidth', @_) }
sub selectforeground  { shift->_configureColumns('-selectforeground', @_) }
sub selectmode        { shift->_configureColumns('-selectmode', @_) }
sub compound {    #JWT:  ADDED THIS METHOD TO ALLOW USER TO DYNAMICALLY OVERWRITE WHERE THE SORT ARROW IMAGE DISPLAYS.
	my $w = shift;
	if (scalar(@_) > 0) { 
	
		$w->_configureColumns('-compound', @_);
		$w->{'-compound'} = $_[0];
	} else {
		return $w->{'-compound'};
	}
}
sub showallsortcolumns {    #JWT:  ADDED THIS METHOD TO ALLOW USER TO DYNAMICALLY OVERWRITE WHERE THE SORT ARROW IMAGE DISPLAYS.
	my $w = shift;	if (scalar(@_) > 0) { 
	
		$w->{'-showallsortcolumns'} = $_[0];
	} else 
	
	{
		return $w->{'-showallsortcolumns'};
	}
}
sub columnFocus {    #JWT:ALLOW A SPECIFIED COLUMN'S LISTBOX GET FOCUS SO THAT KEYBOARD CURSOR "UNDERSCORE" MAY BECOME (MORE) VISIBLE:
	my $w = shift;	

	if ($w->cget('-nocolumnfocus') != 1 && scalar(@_) > 0) { 
		$w->{Configure}{'-focuscolumn'} = $_[0]  if ($_[0] =~ /\d/o);
	} else {
		return $w->{Configure}{'-focuscolumn'};
	}
}
sub focusColumn {    #JWT:DEPRECIATED:USE columnFocus!
	return shift->columnFocus(@_)
}
sub setButtonHeight {  #JWT:ALLOW USER TO SET HEIGHT OF BUTTONS (-pady):
	my $w = shift;
	foreach my $c (@{$w->{'_columns'}}) {
		$c->_setButtonHeight(@_);
	}
}
sub separatorcolor    { shift->_configureColumns('-separatorcolor', @_ ) }
sub separatorwidth    { shift->_configureColumns('-separatorwidth', @_ ) }
sub sortable          { shift->_configureColumns('-sortable', @_) }
sub itemtype          { shift->_configureColumns('-itemtype', @_) }
sub textwidth         { shift->_configureColumns('-textwidth', @_) }

sub takefocus {
	my ($w, $val) = @_;
	return $w->{Configure}{'-takefocus'}  unless (defined($val) && $val);

	#JWT:NEEDS TO BE '' INSTEAD OF 1 FOR Tk (SO WE KEEP IT IN OUR OWN VARIABLE FOR OUR USE)!:
	$w->{'_ourtakefocus'} = $val;
	$w->{Configure}{'-takefocus'} = ($val =~ /0/o) ? 0 : '';
}

sub width {
	my ($w, $v) = @_;

	return $w->{Configure}{'-width'} unless defined $v;
	if ($v == 0) {
		$w->afterIdle(['_setWidth', $w]);
	} else {
		$w->Subwidget('pane')->configure(-width => $v);
	}
}

######################################################################
## Private  methods (Do not depend on these methods being present)
##
## For all methods which have _firstVisible, the method is delegated 
## to the first visible (packed) HListbox
######################################################################

## This is the main callback that is bound to the subwidgets
## when using any of the public bind methods, The defined 
## defined callback ($cb) is called from within it

sub _bindCallback {
	my ($w, $cb, $sw, $ci, $yCoord) = @_;

	my $iHR = { '-subwidget' => $sw, '-column' => $ci };
	if (defined($yCoord)) {
		$iHR->{'-row'} = $w->_getEntryFromY($sw, $yCoord);
	}
	if (ref $cb eq 'ARRAY') {
		my ($code,@args) = @$cb;
		return $w->$code($iHR, @args);
	} else {
		return $w->$cb($iHR);
	}
}

## bind subwidgets is used by other public bind methods to
## apply a callback to an event dequence of a particular subwidget 
## within each of the columns. Any defined callbacks are passed
## to the _bindCallback which is actually the callback that gets
## bound. 

sub _bindSubwidgets {
	my ($w,$subwidget,$sequence,$callback) = @_;
	my $col = 0;

	return (keys %{$w->{'_bindings'}->{$subwidget}})
	unless (defined $sequence);

	unless (defined $callback) {
		$callback = $w->{'_bindings'}->{$subwidget}->{$sequence};
		$callback = '' unless defined $callback;
		return $callback;
	}

	if ($callback eq '') {
		foreach (@{$w->{'_columns'}}) {
			$_->Subwidget($subwidget)->Tk::bind($sequence,'');
		}
		delete $w->{'_bindings'}->{$subwidget}->{$sequence};
		return '';
	}
	my @args = ('_bindCallback', $callback);
	foreach (@{$w->{'_columns'}}) {
		my $sw = $_->Subwidget($subwidget);
		if ($sw->class ne "HMCListbox") {
			$sw->Tk::bind($sequence, [$w => @args, $sw, $col++]);
		} else {
			$sw->Tk::bind($sequence, [$w => @args, $sw, $col++, Ev('y')]);
		}
	}
	$w->{'_bindings'}->{$subwidget}->{$sequence} = $callback;
	return '';
}

## handles config options that should be propagated to all HMLColumn 
## subwidgets. Using the DEFAULT setting in ConfigSpecs would be one 
## idea, but the pane subwidget is also a child, and Pane will not 
## be able to handle many of the options being passed to this method.

sub _configureColumns {
	my ($w, $option, $value) = @_;
	return $w->{Configure}{$option}  unless (defined $value);

	foreach (@{$w->{'_columns'}}) {
		$_->configure("$option" => $value);
	}
}

sub _cntrlEnd  { shift->_firstVisible->Cntrl_End; }

sub _cntrlHome { shift->_firstVisible->Cntrl_Home; }

sub _chgView { 
	my ($w, $fn, @args) = @_;

	$fn = shift(@args)  if ($fn =~ /HASH/o);
	my $code = "\$w->$fn('".join("','",@args)."')";
	eval $code;
}

sub _dataExtend {
	my ($w, $el) = @_;
	my $mode = $w->cget('-selectmode');
	if ($mode eq 'extended') {
		my $anchor = $w->_firstVisible->index('anchor');  #JWT:ADDED - SINCE HList DOESN'T SUPPORT Listbox's Motion() FUNCTION:
		$w->activate($el);
		$w->see($el);
		$w->selectionSet($w->index($el), $anchor);        #JWT:ADDED          "
#		if ($w->selectionIncludes('anchor')) {            #JWT:NEXT 3 REMOVED
#			$w->_firstVisible->Motion($el)
#		}
	} elsif ($mode eq 'multiple') {
		$w->activate($el);
		$w->see($el)
	}
}

sub _deselectAll {
	my $w = shift;
	if ($w->cget('-selectmode') ne 'browse') {
		$w->selectionClear(0, 'end');
	}
}

## implements sorting and dragging & drop of a column
sub _dragOrSort {
	my ($w, $c, $sortAnyway) = @_;

	return  if ($w->state() =~ /disable/o);  #DON'T ALLOW SORTING OR DRAGGING IF DISABLED!

	if (!$w->cget('-moveable') || (defined($sortAnyway) && $sortAnyway)) {
		if ($c->cget('-sortable') && $w->{Configure}{-sortable}) {
			$w->sort(undef, $c);
		}
		return;
	}

	my $h=$c->Subwidget("heading");  # The heading button of the column.

	my $start_mouse_x = $h->pointerx;
	my $y_pos = $h->rooty;  # This is constant through the whole operation.
	my $width = $h->width;
	my $left_limit = $w->rootx - 1;

	# Find the rightmost, visible column
	my $right_end = 0;
	foreach (@{$w->{'_columns'}}) {
		if ($_->rootx + $_->width > $right_end) {
			$right_end = $_->rootx + $_->width;
		}
	}        
	my $right_limit = $right_end + 1;

	# Create a "copy" of the heading button, put it in a toplevel that matches
	# the size of the button, put the toplevel on top of the button.
	my $tl=$w->Toplevel; 
	$tl->overrideredirect(1);
	$tl->geometry(sprintf("%dx%d+%d+%d",
	$h->width, $h->height, $h->rootx, $y_pos));

	my $b=$tl->HMButton
	(map{defined($_->[4]) ? ($_->[0]=>$_->[4]) : ()} $h->configure)
	->pack(-expand=>1,-fill=>'both');

	# Move the toplevel with the mouse (as long as Button-1 is down).
	$h->bind("<Motion>", sub {
		my $new_x = $h->rootx - ($start_mouse_x - $h->pointerx);
		unless ($new_x + $width/2 < $left_limit ||
				$new_x + $width/2 > $right_limit) 
		{
			$tl->geometry(sprintf("+%d+%d",$new_x,$y_pos));
		}
		});

	$h->bind("<ButtonRelease-1>", sub {
		my $rootx;
		eval {$rootx = $tl->rootx;};
		return  unless (defined $rootx);  #ASSUME WE'RE DISABLED.

		my $x = $rootx + ($tl->width/2);
		$tl->destroy;    # Don't need this anymore...
		$h->bind("<Motion>",'');  # Cancel binding

		if ($h->rootx == $rootx) {    
			# Button NOT moved, sort the column....
			if ($c->cget('-sortable') && $w->{Configure}{-sortable}) {
				$w->sort(undef, $c);
			}
			return;
		}

		# Button moved.....
		# Decide where to put the column. If the center of the dragged 
		# button is on the left half of another heading, insert it -before 
		# the column, otherwise insert it -after the column.
		foreach (@{$w->{'_columns'}}) {
			if ($_->ismapped) {
				my $left = $_->rootx;
				my $right = $left + $_->width;
				if ($left <= $x && $x <= $right) {
					if ($x - $left < $right - $x) {
						$w->columnShow($c,-before=>$_);
					} else {
						$w->columnShow($c,'-after'=>$_);
					}
					$w->update;
					$w->Callback(-configurecommand => $w);
				}
			}
		}
	});
}

sub _extendUpDown { shift->_firstVisible->ShiftUpDown(@_) }

## Many of the methods in this package are very similar in that they
## delagate calls to the HMLColumn widgets. Because widgets can be
## be moved around (repacked) and hidden (packForget), any
## one widget may not be the "best" to be delegating calls to. The
## _columns variable holds an array of the columns but the order of 
## this array does not correspond to the order in which they might 
## by displayed, therefore this method is used to return the first
## "visible" or packed HMLColumn. RCS Note: It might be reasonable to
## make this a public method as it could conceivably useful to someone
## who might want to subclass this widget or use their own bindings.
sub _firstVisible {
	my $w = shift;
	foreach my $c (@{$w->{'_columns'}}) {
		return $c if $c->ismapped;
	}
	return $w->{'_columns'}->[0];
}

sub _getEntryFromY {
	my ($cw, $sw, $yCoord) = @_;
	my $nearest = $sw->indexOf($sw->nearest($yCoord));

	return $nearest  if ($nearest <= ($sw->size() - 1));

#x	my ($x, $y, $w, $h) = $sw->bbox($nearest);   #JWT:NEXT 4 REMOVED SINCE HLIST DOESN'T SUPPORT bbox & THIS CODE DOESN'T SEEM TO BE NEEDED ANYWAY.
#x	my $lastY = $y + $h;
#x	return -1  if ($yCoord > $lastY);
#x	return $nearest;
	return -1;
}

## Used to distribute method calls which would otherwise be called for
## for one HMCListbox (Within a column), Each HMCListbox is a modified 
## HListbox whose methods end up passing the code and arguments that need
## to be called to this method where they are invoked for each column
## It's an interesting, although complex, interaction and it's worth 
## tracing to follow the program flow.

#sub _motion    { shift->_firstVisible->Motion(@_) }  #JWT:REMOVED - SINCE HList DOESN'T SUPPORT Listbox's Motion() FUNCTION:
sub _selectAll { shift->_firstVisible->SelectAll; }
sub _Cancel { shift->_firstVisible->Cancel; }

sub _selectionUpdate {
	my ($w, $code, $l, @args) = @_;

	if (@args) {
		foreach (@{$w->{'_columns'}}) {
			&$code($_->Subwidget("listbox"), @args);
		}
	} else {
#		&$code($w->{'_columns'}->[0]->Subwidget("listbox"));
		foreach (@{$w->{'_columns'}}) {
			&$code($_->Subwidget("listbox"));
		}
	}
}

## dynamically sets the width of the widget by calculating
## the width of each of the currently visible columns. 
## This is generally called during creation time when -width
## is set to 0.

sub _setWidth {
	my ($w) = shift;
	my $width = 0;
	foreach my $c (@{$w->{'_columns'}}) {
		my $lw = $c->Subwidget('heading')->reqwidth;
		my $sw = $c->Subwidget('separator')->reqwidth;
		$width += ($lw + $sw);
	}
	$w->Subwidget('pane')->configure(-width => $width);
}



sub _upDown { shift->_firstVisible->UpDown(@_) }

sub _ctrlupDown   #JWT:TAKE ADVANTAGE OF PERSONAL LISTBOX HACK TO ALLOW MULTIPLE SELECTIONS IN "BROWSE" MODE VIA KEYBOARD (Ctrl-Up, Ctrl-Down, and Spacebar):
{
	my $w = shift;
	if (defined($w->{Configure}{'-jwtlistboxhack'}) && $w->{Configure}{'-jwtlistboxhack'} == 1) {
no warnings;
		eval { $w->_firstVisible->Tk::Listbox::CtrlUpDown(@_); };
use warnings;
	} else {
		$w->_firstVisible->UpDown(@_);
	}
}

sub _yscrollCallback  {
	my ($w, $top, $bottom) = @_;

	return  unless ($w->cget(-yscrollcommand));

	unless (defined($top)) {
		# Called internally
		my $c = $w->_firstVisible;
		if (Exists($c) && $c->ismapped){
			($top,$bottom) = $c->yview;
		} else {
			($top,$bottom) = (0,1);
		}
	} 

	if ($top != $w->{'_top'} || $bottom != $w->{'_bottom'}) {
		$w->Callback(-yscrollcommand=>$top,$bottom);
		$w->{'_top'} = $top;
		$w->{'_bottom'} = $bottom;
	}
}

######################################################################
## Exported (Public) methods (listed alphabetically)
######################################################################

## Activate a row
sub activate {
	my $w = shift;

	return  unless (defined $w->_firstVisible);

	if ($w->{Configure}{'-state'} !~ /d/o
			&& ($w->{'-showcursoralways'} || ($w->focusCurrent && $w->{'_hasfocus'}))) {
		$w->_firstVisible->activate(@_);
	} else {
		$w->{'_lastactive'} = $_[0];
		$w->_firstVisible->activate(undef);
		$w->_firstVisible->anchorSet(@_);
	}
}

#JWT: NOTE:FOCUSING IS VERY TRICKY AND REQUIRED MUCH EXPERIMATION AND HACKS TO GET WORKING PROPERLY:
#    THE MAIN ISSUE HS LEFT-TABBING AND THE INABILITY TO TELL HOW FOCUS ARRIVED.  IN Tk WHEN FOCUS LANDS
#    ON A DISABLED WIDGET, A "focusNext" IS DONE TO MOVE FOCUS TO THE NEXT WIDGET AUTOMATICALLY.  THIS
#    WORKS IN ALL CASES *EXCEPT* IF FOCUS ARRIVED FROM A LEFT-TAB, IN WHICH CASE, A "focusPrev" SHOULD
#    BE EXECUTED INSTEAD.  FORTUNATELY, IN OUR CASE, THE "SCROLLED" FRAME THAT SURROUNDS OUR WIDGET
#    ALSO HAS A SECOND WIDGET-FRAME FOR THE SCROLLBARS (WHETHER DISPLAYED OR NOT) THAT'S "NEXT" IN THE
#    TAB-CIRCULATE ORDER FROM OUR WIDGET.  BY BINDING LEFT-TAB TO THE "SCROLLED" FRAME, WE ARE ABLE TO
#    KNOW THAT ANY FOCUS COMING TO OUR WIDGET FIRST COMES THROUGH THE SCROLLBARS (EVEN IF NONE, ONE, OR
#    BOTH ARE VISIBLE AND TAKE FOCUS OR NOT.  ARMED WITH THAT INFORMATION, WE CAN THEN DETERMINE WHETHER
#    A focusPrev OR focusNext SHOULD BE DONE TO PASS ON THE FOCUS WHEN OUR WIDGET IS DISABLED!

sub focus
{
	my $w = shift;
	if ($w->{Configure}{'-state'} =~ /d/o) {
		$w->focusNext;
		return;
	}

	$w->Tk::focus;
	$w->{'_hasfocus'} = 1;
	my $c = (defined($w->{Configure}{'-focuscolumn'}) && $w->{Configure}{'-focuscolumn'} >= 0)
			? $w->columnGet($w->{Configure}{'-focuscolumn'})  #User specified which one to get focus.
			: $w->_firstVisible; 
              #Default to 1st one visible if user did not pick one.
	if (defined($c) && $w->cget('-nocolumnfocus') != 1) {
		$c->Subwidget("listbox")->focus(@_);
		$c->Subwidget("listbox")->bind('<<LeftTab>>', sub {
			$w->focusPrev;
			Tk->break;
		});
	}
	return  if ($w->{'-showcursoralways'});

	#RESTORE CURSOR WHEN FOCUS IS GAINED:
	my $indx = $w->index('active');
	$indx = $w->{'_lastactive'}  unless (defined($indx) && $indx =~ /\d/);
	$indx = 0  unless (defined($indx) && $indx =~ /\d/);
	$w->activate($indx)  if ($w->index('end') >= 0);
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
	$w->activate($w->{'_lastactive'})  if ($w->index('end') >= 0);
}

sub bindColumns    {  shift->_bindSubwidgets('heading',@_) }
sub bindRows       {  shift->_bindSubwidgets('listbox',@_) }
sub bindSeparators {  shift->_bindSubwidgets('separator',@_) }

sub columnConfigure {
	my ($w, $index, %args) = @_;
	$w->columnGet($index)->configure(%args);
}

## Delete a column.
sub columnDelete {
	my ($w, $first, $last) = @_;

    $last ||= $first;    #JWT:ADDED 20150429
	for (my $i=$w->columnIndex($first); $i<=$w->columnIndex($last); $i++) {
		eval { $w->columnGet($i)->destroy; };
	}
	@{$w->{'_columns'}} = map{Exists($_) ? $_ : ()} @{$w->{'_columns'}};
}

sub columnGet {
	my ($w, $from, $to) = @_;
	if (defined($to)) {
		$from= $w->columnIndex($from);
		$to = $w->columnIndex($to);
		return @{$w->{'_columns'}}[$from..$to];
	} else {
		return $w->{'_columns'}->[$w->columnIndex($from)];
	}
}

sub columnHide {
	my ($w, $first, $last) = @_;
	$last = $first unless defined $last;

	for (my $i=$w->columnIndex($first); $i<=$w->columnIndex($last); $i++) {
		eval { $w->columnGet($i)->packForget; };
	}
}

## Converts a column index to a numeric index. $index might be a number,
## 'end' or a reference to a HMLColumn widget (see columnGet). Note that
## the index return by this method may not match up with it's current
## visual location due to columns being moved around

sub columnIndex {    
	my ($w, $index, $after_end) = @_;

	if ($index eq 'end') {
		if (defined $after_end) {
			return $#{$w->{'_columns'}} + 1;
		} else {
			return $#{$w->{'_columns'}};
		}
	} 

	if (ref($index) eq "Tk::HMListbox::HMLColumn") {
		foreach (0..$#{$w->{'_columns'}}) {
			if ($index eq $w->{'_columns'}->[$_]) {
				return $_;
			}
		}
	} 

	if ($index =~ m/^\s*(\d+)\s*$/o) {
		return $1;
	}    
	croak "Invalid column index: $index\n";
}

## JWT:Bind "underlined" Alt-<letter> keys in column headers to sort function (as if header button pressed) to HMListbox widget (when it has focus)

sub _headerAltBindit {
	my ($x, $w, $c, $idx) = @_;

	$w->_dragOrSort($c, 1);
	$x->break;
}

## JWT:Bind "underlined" Alt-<letter> keys in column headers to sort function (as if header button pressed) to all column HListbox widgets (when it has focus using JWT's hack)

sub _headerAltBinditAll {
	my ($x, $w) = @_;
	my $mykey = $x->XEvent->A;
	foreach my $c (@{$w->{'_columns'}}) {
		if (defined($c->{'sorthotkey'}) && $c->{'sorthotkey'} eq $mykey) {
			$w->_dragOrSort($c, 1);
		}
	}
	$x->break;
}

## Insert a column. $index should be a number or 'end'. 

sub columnInsert {
	my ($w, $index, %args) = @_;

	$index = $w->columnIndex($index,1);
	my %opts = ();

	## Copy these options from the megawidget.
	foreach (qw/-background -foreground -headerbackground -headerforeground -font -height
			-resizeable -selectbackground -selectforeground -disabledforeground
			-selectborderwidth -selectmode -separatorcolor
			-separatorwidth -sortable -itemtype -textwidth -reversearrow -state/) 
	{
		$opts{$_} = $w->cget($_) if defined $w->cget($_);
	}
	if ($Tk::HListbox::VERSION >= 2.3) {
		foreach (qw/-tpady -tpadx -ipady -ipadx/) {
			$opts{$_} = $w->cget($_)  if defined $w->cget($_);
		}
	}
	## All options (and more) might be overridden by %args.
	map {$opts{$_} = $args{$_}} keys %args;

	## JWT:See if column header contains "~" indicating a "hot-character (next letter) to use as a keyboard binding for sorting the column using the keyboard!:
	my $hotchar;	if (defined($opts{'-text'}) && $opts{'-text'} =~ s/^([^\~]*)\~(\w)/$1$2/o) { 
	
		$hotchar = $2;
		$opts{'-underline'} = length($1);  #Cause the hotkey to be underlined in the column header button.
	}
	my $c = $w->Subwidget("pane")->HMLColumn(%opts,       #Create the new column:
			-yscrollcommand  =>  [ $w => '_yscrollCallback'],
			-configurecommand => [ $w => 'Callback', '-configurecommand', $w],
			-xscancommand =>     [ $w => 'xscan' ],
			-updatecommand =>    [ $w => '_selectionUpdate']
	);
	unless ($index || defined $w->{Configure}{'-jwtlistboxhack'} || $w->cget('-nocolumnfocus') == 1)   { #JWT:If 1st column (now that we've created a listbox), see if we're using JWT's HACKED listbox:
no warnings;
		eval { $c->Subwidget("listbox")->Tk::Listbox::CtrlUpDown(0); };
use warnings;
		$w->{Configure}{'-jwtlistboxhack'} = $@ ? 0 : 1;  #eval succeeds if using JWT's hacked listbox!
	}
	$c->{'__HMListbox__'} = $w;   #JWT:SAVE ME FOR FUTURE REFERENCES.
	## RCS: Review this later - questionable implementation
	## Fill the new column with empty values, making sure all columns have
	## the same number of rows.
	unless (scalar(@{$w->{'_columns'}}) == 0) {
		foreach (1..$w->size) {
			$c->insert('end','');
		}
	}  
	$c->Subwidget("heading")->bind("<ButtonPress-1>", [ $w => '_dragOrSort', $c]);
	$c->Subwidget("heading")->configure(-compound => $w->{'-compound'})  if ($w->{'-compound'});
	my @bindTags = $w->bindtags;	
	if (defined($hotchar) && $hotchar =~ /\S/o)   { #JWT:Set up Alt-<hotkey> bindings if we have a hotkey character defined:
	
		$hotchar =~ tr/A-Z/a-z/;
		$c->{'sorthotkey'} = $hotchar;
		$w->bind($bindTags[1], "<Alt-$hotchar>", [\&_headerAltBindit, $w, $c, $index]);
		$c->Subwidget("listbox")->Tk::HListbox::bind("<Alt-Key>", [\&_headerAltBinditAll, $w, $c, $index]);
	}

	my $carr = $w->{'_columns'};
	splice(@$carr,$index,0,$c);

	## Update the selection to also include the new column.
	map {$w->selectionSet($_, $_)} $w->curselection
	if $w->curselection;

	## Copy all bindings that are created by calls to 
	## bindRows, bindColumns and/or bindSeparators.
	## RCS: check this out, on the next pass
	foreach my $subwidget (qw/listbox heading separator/) {
		foreach (keys %{$w->{'_bindings'}->{$subwidget}}) {
			$c->Subwidget($subwidget)->Tk::bind($_, 
					[
					$w => '_bindCallback', 
					$w->{'_bindings'}->{$subwidget}->{$_},
					$index
			]
			);
		}
	}

	if (Tk::Exists($w->{'_columns'}->[$index+1])) {
		$w->columnShow($index, -before=>$index+1);
	} else {
		$w->columnShow($index);
	}
	return $c;
}

sub columnPack {
	my ($w, @packinfo) = @_;
	$w->columnHide(0,'end');
	foreach (@packinfo) {
		my ($index, $width) = split /:/o;
		$w->columnShow ($index);
		if (defined($width) && $width =~ /^\d+$/o) {
			$w->columnGet($index)->setWidth($width)
		}
	}
}

sub columnPackInfo {
	my ($w) = @_;

	## Widget needs to have an update call first, otherwise
	## the method will not return anything if called prior to
	## MainLoop - RCS

	$w->update;
	map {$w->columnIndex($_) . ':' . $_->width} 
	sort {$a->rootx <=> $b->rootx}
	map {$_->ismapped ? $_ : ()} @{$w->{'_columns'}};
}    

sub columnShow {
	my ($w, $index, %args) = @_;

	my $numericIndex = $w->columnIndex($index);
	my $c = $w->columnGet($index);
	my @packopts = ($numericIndex == $w->{Configure}{'-fillcolumn'})
			? (-anchor=>'w',-side=>'left',-fill=>'both',-expand=>1)
			: (-anchor=>'w',-side=>'left',-fill=>'both');
	if (defined($args{'-before'})) {
		push (@packopts, '-before'=>$w->columnGet($args{'-before'}));
	} elsif (defined($args{'-after'})) {
		push (@packopts, '-after'=>$w->columnGet($args{'-after'}));
	}
	eval { $c->pack(@packopts); };
}

sub curselection { shift->_firstVisible->curselection(@_)}

sub delete {
	my $w = shift;
	foreach (@{$w->{'_columns'}}) {
		my $saved_width = $_->width;
		$_->delete(@_);
		if ($_->ismapped) {
			$_->setWidth($saved_width);
		}
	}
	$w->_yscrollCallback;
}

sub get {
	my @result = ();
	my ($colnum,$rownum) = (0,0);

	foreach (@{shift->{'_columns'}}) {
		my @coldata = $_->get(@_);
		$rownum = 0;
		map {$result[$rownum++][$colnum] = $_} @coldata;
		$colnum++;
	}
	@result;
}

sub getRow {
	my @result = map {$_->get(@_)} @{shift->{'_columns'}};
	if (wantarray) {
		@result;
	} else {
		$result[0];
	}
}

sub index {
	my $w = shift;
	
	return undef  unless (defined($_[0]) && defined($w->_firstVisible));
	my $ret = ($w->{'-showcursoralways'} || ($w->{'_hasfocus'} && $w->focusCurrent) || $_[0] !~ /^active/o)
			? $w->_firstVisible->index(@_) : $w->{'_lastactive'};
	return $ret;
}

sub insert {
	my ($w, $index, @data) = @_;
	my ($rownum, $colnum);
	my $rowcnt = $#data;

	# Insert data into one column at a time, calling $listbox->insert
	# ONCE for each column. (The first version of this widget call insert
	# once for each row in each column).
	# 
	foreach $colnum (0..$#{$w->{'_columns'}}) {    
		my $c = $w->{'_columns'}->[$colnum];

		# The listbox might get resized after insert/delete, which is a 
		# behaviour we don't like....
		my $saved_width = $c->width;

		my @coldata = ();

		foreach (0..$#data) {
			if (defined($data[$_][$colnum])) {
				push @coldata, $data[$_][$colnum];
			} else {
				push @coldata, '';
			}
		}
		$c->insert($index,@coldata);

		if ($c->ismapped) {
			# Restore saved width.
			$c->setWidth($saved_width);
		} 
	}    
	$w->_yscrollCallback;
}

## These methods all delegate to the first visible column's
## HListbox. Refer to HListbox docs and description for _firstVisible

sub nearest           { shift->_firstVisible->nearest(@_)}
sub see               { shift->_firstVisible->see(@_)}
sub selectionAnchor   { shift->_firstVisible->selectionAnchor(@_)}
sub selectionClear    { shift->_firstVisible->selectionClear(@_)}
sub selectionIncludes { shift->_firstVisible->selectionIncludes(@_)}
sub selectionSet      { shift->_firstVisible->selectionSet(@_)}
sub SpaceSelect       { shift->_firstVisible->SpaceSelect(@_)}
sub CtrlPriorNext     { shift->_firstVisible->CtrlPriorNext(@_)}
sub size              { shift->_firstVisible->size(@_)}

sub sort {
	my ($w, $descending, @indexes) = @_;

	#my @l = @{$w->{'_sortcolumns'}};  #JWT:CHGD. TO NEXT 20150429 TO PREVENT STRAY ARROWS:
	my @l = (0..$#{$w->{'_columns'}});
	foreach my $i (@l) {
		$w->{'_columns'}->[$i]->Subwidget("heading")->configure(-bitmap => 'noarrow');
	}

# Hack to avoid problem with older Tk versions which do not support
# the -recurse=>1 option.
	$w->Busy;   # This works always (but not very good...)
	Tk::catch {$w->Busy(-recurse=>1)};# This works on newer Tk versions,
# harmless on old versions.

	@indexes = (0..$#{$w->{'_columns'}}) unless @indexes;

# Convert all indexes to integers.
	map {$_=$w->columnIndex($_)} @indexes;
# This works on Solaris, but not on Linux???
# Store the -comparecommand for each row in a local array. In the sort,
# the store command is called directly in stead of via the HMLColumn
# subwidget. This saves a lot of callbacks and function calls.
#
# my @cmp_subs = map {$_->cget(-comparecommand)} @{$w->{'_columns'}};

# If sort order is not defined
	unless (defined $descending) {
		if ($#indexes == 0 &&
				$w->{'_sortcol'} == $indexes[0] &&
				$w->{'_sort_descending'} == 0)
		{
			# Already sorted on this column, reverse sort order.
			$descending = 1;
		} else {
			$descending = 0;
		}
	}

# To retain the selection after the sort we have to save information
# about the current selection before the sort. Adds a dummy column
# to the two dimensional data array, this last column will be true
# for all rows that are currently selected.
	my $dummy_column = scalar(@{$w->{'_columns'}});

	my $wasActive = $w->index('active');
	my @data = $w->get(0,'end');
	foreach ($w->curselection) {
		$data[$_]->[$dummy_column] = 1;  # Selected...
	}
	$data[$wasActive]->[$dummy_column] += 2  if (defined($wasActive) && $wasActive >= 0);

	@data = sort {
		local $^W = 0;
		foreach (@indexes) {
			my $res = do {
				if ($descending) {
					# Call via cmp_subs works fine on Solaris, but no
					# on Linux. The column->compare method is much slower...
					#
					# &{$cmp_subs[$_]} ($b->[$_],$a->[$_]);
					$w->{'_columns'}->[$_]->compare($b->[$_],$a->[$_]);
				} else {
					# &{$cmp_subs[$_]} ($a->[$_],$b->[$_]);
					$w->{'_columns'}->[$_]->compare($a->[$_],$b->[$_]);
				}
			};
			return $res if $res;
		}
		return 0;
	} @data;

# Replace data with the new, sorted list.
	$w->delete(0,'end');
	$w->insert('end',@data);

	my @new_selection = ();
	foreach (0..$#data) {
		if (defined $data[$_]->[$dummy_column]) {
			$w->selectionSet($_,$_)  if ($data[$_]->[$dummy_column] % 2);
			$w->activate($_)  if ($data[$_]->[$dummy_column] > 1);
		}
	}

	$w->{'_sortcol'} = $indexes[0];
	@{$w->{'_sortcolumns'}} = @indexes;
	$w->{'_sort_descending'} = $descending;

	$w->Unbusy; #(-recurse=>1);
	if ($w->{'-showallsortcolumns'}) {
		for (my $i=0;$i<=$#indexes;$i++) {   #UNCOMMENT TO SHOW ALL SORTED COLUMNS:
			if ($w->{'_columns'}->[$indexes[$i]]->cget('-reversearrow') == 1) {
				$w->{'_columns'}->[$indexes[$i]]->Subwidget("heading")->configure(-bitmap => ($w->{'_sort_descending'} ? 'uparrow' : 'downarrow'));
			} else {
				$w->{'_columns'}->[$indexes[$i]]->Subwidget("heading")->configure(-bitmap => ($w->{'_sort_descending'} ? 'downarrow' : 'uparrow'));
			}
		}
	} else {
		if ($w->{'_columns'}->[$indexes[0]]->cget('-reversearrow') == 1) {
			$w->{'_columns'}->[$indexes[0]]->Subwidget("heading")->configure(-bitmap => ($w->{'_sort_descending'} ? 'uparrow' : 'downarrow'));
		} else {
			$w->{'_columns'}->[$indexes[0]]->Subwidget("heading")->configure(-bitmap => ($w->{'_sort_descending'} ? 'downarrow' : 'uparrow'));
		}
	}
}

sub state {
	my ($w, $val) = @_;

	return $w->{Configure}{'-state'} || undef  unless (defined($val) && $val);
	return  if (defined($w->{'_prevstate'}) && $val eq $w->{'_prevstate'});  #DON'T DO TWICE IN A ROW!

	$w->{'_statechg'} = 1;
	if ($val =~ /d/o) {              #WE'RE DISABLING (SAVE CURRENT ENABLED STATUS STUFF, THEN DISABLE USER-INTERACTION):
		$w->{Configure}{'-state'} = 'normal';
		$w->{'_saveactive'} = $w->index('active') || 0;
		$w->{'_foreground'} = $w->cget('-foreground');  #SAVE CURRENT (ENABLED) FG COLOR!
		$w->{Configure}{'-state'} = $val;
		foreach my $i (0..$#{$w->{'_columns'}}) {
			$w->{'_columns'}->[$i]->state($val);
		}
		$w->activate($w->{'_saveactive'})  unless ($w->{'_hasfocus'});
#?		$w->focusNext  if ($w->{'_hasfocus'});  #MOVE FOCUS OFF WIDGET IF IT HAS IT.
	} elsif ($w->{'_prevstate'}) {   #WE'RE ENABLING (RESTORE PREV. ENABLED STUFF AND REALLOW USER-INTERACTION):
		my $fg = $w->{'_foreground'};
		$w->{Configure}{'-state'} = $val;
		foreach my $i (0..$#{$w->{'_columns'}}) {
			$w->{'_columns'}->[$i]->state($val);
		}
		if (defined $w->_firstVisible) {   #RESTORE SELECTED LIST AND ACTIVE CURSOR:
			my @selected = $w->_firstVisible->curselection;
			$w->selectionSet(shift @selected)  while (@selected);
			$w->activate($w->{'_saveactive'});
		}
	}
	$w->{'_prevstate'} = $w->{Configure}{'-state'};
	$w->{'_statechg'} = 0;
}

# Implements horizontal scanning. 
sub xscan {
	my ($w, $type, $x) = @_;

	if ($type eq 'dragto') {
		my $dist = $w->{'_scanmark_x'} - $w->pointerx;

		# Looks like there is a bug in Pane: If no -xscrollcommand
		# is defined, xview() fails. This is fixed by this hack:
		#
		my $p = $w->Subwidget("pane");
		unless (defined ($p->cget(-xscrollcommand))) {
			$p->configure(-xscrollcommand => sub {});
		}
		$p->xview('scroll',$dist,'units');
	}
	$w->{'_scanmark_x'} = $w->pointerx;
}

sub xview { shift->Subwidget("pane")->xview(@_) }
sub yview { shift->_firstVisible->yview(@_)}
1;

__END__