#
# Tk::JBrowseEntry is an enhanced version of the Tk::BrowseEntry widget.

=head1 NAME

Tk::JBrowseEntry - Full-featured "Combo-box" (Text-entry combined with drop-down 
listbox) derived from Tk::BrowseEntry with many additional features and options.

=head1 SYNOPSIS

	use Tk;
	use Tk::JBrowseEntry;

	my $mw = MainWindow->new;
	my $var;

	my $widget = $mw->JBrowseEntry(
		-label => 'Normal:',
		-variable => \$var,
		-state => 'normal',
		-choices => [qw(pigs cows foxes goats)],
		-width  => 12
	)->pack(
		-side   => 'top',
		-pady => '10',
		-anchor => 'w');

	MainLoop;

=head1 DESCRIPTION

Tk::JBrowseEntry is a derived widget from Tk::BrowseEntry, but adds numerous 
features and options.  Among them are hash lists (one set of values is displayed 
for the user, but another is used as data), ability to disable either the text 
entry widget or the listbox, ability to allow user to delete items from the list, 
additional keyboard bindings, ability to have the drop-down list "fixed" (always 
displayed, ability to use Tk::HListbox, ie. to include thumbnail icons in the 
list), customized key bindings and behaviour, and much more!

JBrowseEntry widgets allow one to specify a full combo-box, a "readonly" 
box (text field allows user to type the 1st letter of an item to search for, 
but user may only ultimately select one of the items in the list); a "textonly" 
version (drop-down list and list pattern-matching disabled); a "text" version 
(drop-down list disabled), but the up, down, and right arrows will still do 
text-completion by matching against the choices in the list; or a completely 
disabled widget.

This widget is similar to other combo-boxes, ie. 	JComboBox, but has better 
keyboard bindings and allows for quick lookup/search within the listbox. 
pressing <RETURN> in entry field displays the drop-down box with the 
first entry most closly matching whatever's in the entry field highlighted. 
Pressing <RETURN> or <SPACE> in the listbox 
selects the highlighted entry and copies it to the text field and removes the 
listbox.  <ESC> removes the listbox from view.  
<UP> and <DOWN> arrows work the listbox as well as pressing a key, which will 
move the highlight to the next item starting with that letter/number, etc. 
<UP> and <DOWN> arrows pressed within the entry field circle through the 
various list options as well (unless "-state" is set to 'textonly').  
Set "-state" to "text" to disable the drop-down list, but allow <UP> and 
<DOWN> to cycle among the choices.  Setting "-state" to 'textonly' completely 
hides the choices list from the user - he must type in his choice just like 
a normal entry widget.

One may also specify whether or not the button which activates the 
drop-down list via the mouse can take focus or not (-btntakesfocus) or 
whether the widget itself can take focus or is skipped in the focusing 
order.  The developer can also specify alternate bitmap images for the 
button (-arrowimage and / or -farrowimage).  The developer can also specify the 
maximum length of the drop-down list such that if more than that number of 
items is added, a vertical scrollbar is automatically added (-height).  
A fixed width in characters (-width) can be specified, or the widget can be 
allowed to resize itself to the width of the longest string in the list.  The 
listbox and text entry field are automatically kept to the same width.

One can optionally specify a label (-label), similar to the "LabEntry" widget.  
By default, the label appears packed to the left of the widget.  The 
positioning can be specified via the "-labelPack" option.  For example, to 
position the label above the widget, use "-labelPack => [-side => 'top']".

=head1 EXAMPLES

 It is easiest to illustrate this widget's capabilities via examples:
 
 use Tk;
 use Tk::JBrowseEntry;
 
 $MainWin = MainWindow->new;
 
 #SET UP SOME DEFAULT VALUES.
 
 $dbname1 = 'cows';
 $dbname2 = 'foxes';
 $dbname3 = 'goats';
 $dbname5 = 'default';
 
 #HERE'S A NORMAL COMBO-BOX.
 
 $jb1 = $MainWin->JBrowseEntry(
 	-label => 'Normal:',
 	-variable => \$dbname1,
 	-state => 'normal',
 	-choices => [qw(pigs cows foxes goats)],
 	-width  => 12);
 $jb1->pack(
 	-side   => 'top', -pady => '10', -anchor => 'w');
 
 #THIS ONE HAS THE DROP-DOWN LIST DISABLED.
 
 $jb2 = $MainWin->JBrowseEntry(
 	-label => 'TextOnly:',
 	-variable => \$dbname2,
 	-state => 'text',
 	-choices => [qw(pigs cows foxes goats)],
 	-width  => 12);
 $jb2->pack(
 	-side   => 'top', -pady => '10', -anchor => 'w');
 
 #THIS ONE'S "READONLY" (USER MUST PICK FROM THE LIST, TEXT BOX ALLOWS QUICK 
 #SEARCH.
 
 $jb3 = $MainWin->JBrowseEntry(
 	-label => 'ReadOnly:',
 	-variable => \$dbname3,
 	-choices => [qw(pigs cows foxes goats)],
 	-state => 'readonly',
 	-width  => 12);
 $jb3->pack(
 	-side   => 'top', -pady => '10', -anchor => 'w');
 
 #THIS ONE'S COMPLETELY DISABLED!
 
 $jb4 = $MainWin->JBrowseEntry(
 	-label => 'Disabled:',
 	-variable => \$dbname3,
 	-state => 'disabled',
 	-choices => [qw(pigs cows foxes goats)],
 	-width  => 12);
 $jb4->pack(
 	-side   => 'top', -pady => '10', -anchor => 'w');
 
 #HERE'S ONE WITH A SCROLLBAR (NOTE THE "-height" ATTRIBUTE).
 
 $jb5 = $MainWin->JBrowseEntry(
 	-label => 'Scrolled List:',
 	-width => 12,
 	-default => $dbname5,
 	-height => 4,
 	-variable => \$dbname5,
 	-browsecmd => sub {print "-browsecmd!\n";},
 	-listcmd => sub {print "-listcmd!\n";},
 	-state => 'normal',
 	-choices => [qw(pigs cows foxes goats horses sheep dogs cats ardvarks default)]);
 $jb5->pack(
 	-side   => 'top', -pady => '10', -anchor => 'w');
 
 #HERE'S ONE THAT THE BUTTON TAKES KEYBOARD FOCUS.
 
 $jb6 = $MainWin->JBrowseEntry(
 	-label => 'Button Focus:',
 	-btntakesfocus => 1,
 	-arrowimage => $MainWin->Getimage('balArrow'),   #SPECIFY A DIFFERENT BUTTON IMAGE.
 	-farrowimage => $MainWin->Getimage('cbxarrow'),  #OPTIONAL 2ND IMAGE FOR BUTTON WHEN FOCUSED. 
 	-width => 12,
 	-height => 4,
 	-variable => \$dbname6,
 	-browsecmd => sub {print "-browsecmd!\n";},
 	-listcmd => sub {print "-listcmd!\n";},
 	-state => 'normal',
 	-choices => [qw(pigs cows foxes goats horses sheep dogs cats ardvarks default)]);
 $jb6->pack(
 	-side   => 'top', -pady => '10', -anchor => 'w');
 
 #HERE'S ONE THAT DOWS NOT TAKE KEYBOARD FOCUS.
 
 $jb7 = $MainWin->JBrowseEntry(
 	-label => 'Skip Focus:',
 	-takefocus => 0,
 	-width => 12,
 	-height => 4,
 	-variable => \$dbname7,
 	-browsecmd => sub {print "-browsecmd!\n";},
 	-listcmd => sub {print "-listcmd!\n";},
 	-state => 'normal',
 	-choices => [qw(pigs cows foxes goats horses sheep dogs cats ardvarks default)]);
 $jb7->pack(
 	-side   => 'top', -pady => '10', -anchor => 'w');
 
 $jb7->choices([qw(First Second Fifth Sixth)]);   #REPLACE LIST CHOICES!
 $jb7->insert(2, 'Third', 'Fourth');              #ADD MORE AFTER 1ST 2.
 $jb7->insert('end', [qw(Seventh Oops Eighth)]);  #ADD STILL MORE AT END.
 $jb7->delete(7);                                 #REMOVE ONE.
 
 $b = $MainWin->Button(-text => 'Quit', -command => sub {exit(); });
 $b->pack(-side => 'top');
 $jb1->focus;   #PICK ONE TO START WITH KEYBOARD FOCUS.
 
 MainLoop;

=head1 SEE ALSO

L<Tk::JComboBox> L<Tk::BrowseEntry> L<Tk::Listbox> L<Tk::Entry>

=head1 WIDGET-SPECIFIC OPTIONS

=over 4

=item B<-state> => I<normal | readonly | text | textonly | disabled>

Default: B<normal>

JBrowseEntry supports 5 different states:

=over 4

I<normal>:  Default operation -- Both text entry field and drop-down list button 
function normally. 

I<readonly>:  Drop-down list functions normally. When text entry field has focus, 
user may type in a letter, and the drop-down list immediately drops down and the 
first/ next matching item becomes highlighted. The user must ultimately select 
from the list of valid entries and may not enter anything else.

I<text>:  Text entry functions normally, but drop-down list button is disabled. 
User must type in an entry or use the up and down arrows to choose from among 
the list items.

I<textonly>:  Similar to "text": Text entry functions normally, but drop-down 
list button is disabled. User must type in an entry. The list choices are 
completely hidden from the user.

I<disabled>:  Widget is completely disabled and greyed out. It will not 
activate or take focus.

=back

=item B<-altbinding>

Allows one to specify alternate binding schema for certain keys.  Each binding 
pair may be separated by a comma, semicolon, colon, space, or virtical bar.  
Case is insensitive.  Currently valid values are:

"Return=Go" - causes [Return] key to roll up the drop-down list and invoke the 
I<-browsecmd> callback, if any.

"Return=NonEmptyGo" - same as "Return=Go" if the text field is non-empty, 
otherwises pops up the drop-down list.

"Return=SingleGo" - same as "Return=Go" if there are no choices in the 
drop-down list (instead of popping up the drop-down list). 

"Return=Next" - causes pressing the [Return] key to advance the focus to the 
next widget in the main window.

"Right=NoSearch" - Do not complete the text in the text field with the next 
matching value found in the 
choices list when the [Right-arrow] key is pressed in the entry field, rather 
leave it unchanged.

"Down=Popup" - causes the [Down-arrow] key pressed in the entry field to pop 
up the selection listbox.  
Useful particularly if the [arrow-button] isn't displayed, 
ie. (I<-nobutton> => 1) and/or the [Return] key is bound with an 
I<-altbinding>, etc. to do something other than pop up the drop-down list.

"List=Bouncy" - causes the drop-down list to behave more like a popup menu 
and immediately roll back up (after matching text with nearest entry) if the 
mouse button is pressed and released on the drop-down list button.
(Normally, the drop-down list state is simply toggled when mouse is pressed 
and released on the button.)

"Nolistbox=actions" - causes certain I<actions> to NOT invoke the 
I<-browsecmd> callback when activated within the listbox widget, 
ie. "Nolistbox=listbox.space" means don't invoke I<-browsecmd> callback if 
<spacebar> pressed in the listbox.  Valid values are 
([listbox.]{space|return|button1|*button1|mod[.{shift|Control|alt|*}-]button1}:  
"space,button1,return,mod.Shift-button1,mod.Control-button1,mod.Alt-button1,mod,*button1", 
etc.  Multiple values can be separated by commas.  "mod" means any modifier 
(Shift|Control|Alt), "*button1" means button1 regardless of modifier.

"Tab=KeepList" - Normally, if the [Tab] key is pressed while the drop-down 
list is displayed, the drop-down list is removed from view (rolled up) and 
the focus simply returns to the text entry field.  Specifying "Tab=KeepList" 
(on Unixish systems) makes Tk::JBrowseEntry keep the drop-down list displayed 
while returning the focus back to the text field.  If "Tab=Popup" is also 
specified, it implies "KeepList" as well on Unixish systems where the list 
is not "fixed" as this avoids trapping the user in a "tab loop" between the 
text-entry field and the drop-down list.  Either way, the listbox is 
undisplayed anyway when the JBrowseEntry widget itself goes out of focus, or 
either the [Enter] or [Esc] key is pressed.  If the drop-down list is a 
"fixed" list (I<-fixedlist> is specified), then the list always remains in 
view and only the focus changes and this setting is ignored.  This setting is 
also ignored on M$-Windows platforms, which is beyond our control.

"Down=None", "Up=None", "Right=None", "Esc=None", "Return=None", "Space=None" 
- causes pressing that respective key to NOT perform it's default 
binding action.  User can still add their own bindings within their calling 
program though.

=item B<-arrowimage>

Allows one to specify an alternate image for the the button which activates 
the drop-down list when the button has the keyboard focus. The default is: 
$MainWin->Getimage('cbxarrow') on Linux and a custom bitmap on M$-Windows.  
Also see the "-farrowimage" option below, as well as the "-arrowimage" 
option under Standard BrowseEntry options for more details.  On Linux, this 
is used regardless of the focus status of the button, which is indicated by 
the border, unless a "-farrowimage" image is specified.  On M$-Windows, a 
separate custom bitmap is provided for the focused version, since Windows does 
not change the border color when the button takes focus.

=item B<-browse>

Adds several additional triggering events which invoke the B<-browsecmd> 
callback:  entry.tab, frame.tab, and key.<character-typed>, if set to 1.  
Default is 0.  This likely is rarely needed in practice, but allows the 
calling program to know whenever a key is typed into the entry field or if the 
field is tabbed away from.  The one case the author uses this option on is the 
"drive-letter" field in the M$-Windows version of his Tk::JFileDialog widget.

=item B<-browsecmd>

Specifies a callback function to call when a selection is made in the popped 
up listbox. It is passed the widget and the text of the entry selected. This 
function is called after the entry variable has been assigned the value, 
(so the programmer can validate and override the user's entry if desired).

The function is passed the widget reference itself (self), the content of the 
entry field (not necessarily equal to the B<-variable> reference value), and 
the triggering "event" as described below.  

Specific cases (events) where it is invoked:  
entry.[-mod.{Shift|Control|Alt}]return[.{go|browse}], listbox.return, 
listbox.space, or listbox.[-mod.{Shift|Control|Alt}]button1.  
If B<-browse> is set to 1, then additional triggering events are:  
entry.tab, frame.tab, and key.<character-typed>.

=item B<-btntakesfocus>

The drop-down list button is normally activated with the mouse and is skipped 
in the focusing circuit. If this option is set, then the button will take 
keyboard focus. Pressing <Return>, <Spacebar>, or <Downarrow> will cause the 
list to be dropped down, repeating causes the list to be removed again.  
Normally, the text entry widget receives the keyboard focus. This option can 
be used in combination with "-takefocus" so that either the text entry widget, 
the button, or both or neither receive keyboard focus. If both options are set, 
the entry field first receives focus, then pressing <Tab> causes the button 
to be focused. 

=item B<-buttonbackground>

Specify alternate background for the drop-down list button.

=item B<-buttonforeground>

Specify alternate foreground for the drop-down list button.

=item B<-colorstate>

Archaic carryover from Tk::BrowseEntry -- Appears to force the background of 
the text-entry widget to I<"lightgray"> if set to I<"1"> and state is 
I<readonly> or I<disabled>, and no B<-background> color has been set; and a 
slightly darker shade of gray (I<"gray95 ">) otherwise.  We also set the 
foreground color to I<gray30> for I<readonly> or I<disabled> states and 
I<black> otherwise to ensure that the text remains readable regardless of what 
foreground color is otherwise set.  I've also added special value of I<"2"> 
(or I<"dark">) to set a darker version of the readonly and disabled colors.  
To only make one or the other use the "darker" shades, one can instead 
specify I<"readonlydark"> or I<"disableddark">.  NOTE:  Once the widget has 
been set to a "readonly" state, the I<"-textreadonlybackground"> color remains 
fixed thru future calls to setPalette!  This seems to be a limitation of Tk 
and setPalette.  Also note that in general, changing the widget's 
I<-foreground> and / or I<-background> options later via "$widget->configure() 
may not completely change all the colors of every part of every subwidget, 
and setPalette may not completely correct everything until the widget's 
I<-state> is changed, therefore, it's a good idea to also call 
$w->state($w->state()); after dynamically changing foreground or background 
colors for the widget.

=item B<-deleteitemsok>

If set, allows user to delete individual items in the drop-down list by 
pressing the <Delete> key to delete the current (active) item.  No effect if 
the state is "text" or "textonly".

=item B<-deletecmd>

(ADDED v4.9): Specifies a callback function to call when the user deletes an 
entry (if B<-deleteitemsok> is set to true) in the popped up listbox. It is 
passed the widget and either the index of the entry being deleted OR -1. This 
function is called BOTH before AND after the entry is deleted.  The entry 
parameter is -1 on the second call, and the first call if $_[1] (the index to 
be deleted) >= 0, the function should return false/undef to permit the delete 
or true to SUPPRESS the delete (in which case, the callback will NOT be called 
a second time)!  No effect if the state is "text" or "textonly".

=item B<-farrowimage>

Allows one to specify a second, alternate bitmap for the image on the button 
which activates the drop-down list when the button has the keyboard focus.  
The default is to use the "-arrowimage" image, EXCEPT in M$-Windows, in which 
case, the default remains the default "focused" bitmap, since Windows does not 
use a focus border, but rather, the image itself must change to indicate 
focus status.  See the "-arrowimage" option under Standard BrowseEntry options 
for more details.  The default image for Linux is:  
$MainWin->Getimage('cbxarrow') and a custom bitmap for M$-Windows.

=item B<-fixedlist>

Normally the drop-down list pops up and down when requested, rolling up 
(hiding) when not.  Setting this option to a true value will cause the 
drop-down list to be a fixed listbox widget packed below the rest of the widget.  
Specifying B<-fixedlist> => I<"top"> will instead display the listbox 
I<above> the rest of the widget.  Default: 0 - drop-down list is not 
fixed (pre-v5.10 behavior).

=item B<-indicator>

Only used if B<-listboxtype> is set to HListbox, otherwise ignored.  
Specifies whether an indicator image may be included with HListbox entries.  
Default 0 (no indicator image).

=item B<-itemtype>

Only used if B<-listboxtype> is set to HListbox, otherwise ignored.  
Specifies the type of data permitted for HListbox entries.  
Valid values are:  I<"text">, I<"image">, and I<"imagetext">.  
Default: I<"text">.

=item B<-label>

Specify a label to be displayed next to the widget.  
The default is I<undef> - do not display (or pack) a label next to the widget.  
If you do not wish to specify a label initially, but plan to set a label 
later, you should set B<-label> to ''.  By default the label is displayed to 
the left of the widget (as part of it).  This can be changed using the 
B<-labelPack> option.

=item B<-labelbackground>

Specify alternate background for the label.

=item B<-labelforeground>

Specify alternate foreground for the label.

=item B<-labelfont>

Specify alternate font for the label.

=item B<-labelPack>

Specify alternate packing options for the label. The default is: 
"[-side => 'left', -anchor => 'e']" ("[-side => 'left', -anchor => 
'n'|'s', -pady => 1, -ipady => 2] if B<-fixedlist> is set 
('s' if 'top', 'n' otherwise)). The argument is an arrayref. 
Note: if no label is specified, none is packed or displayed, therefore, 
if you do not wish to specify a label initially, but plan to set a label 
later, you should set B<-label> to ''.  

=item B<-labelrelief>

Default B<"flat">

Allow relief of the label portion of the widget to be specified.

=item B<-listboxtype>

Specifies tye type of listbox widget to use for the drop-down list.  
Valid values are I<"Listbox"> and I<"HListbox">.  
Default is I<"Listbox"> (Tk::Listbox).  
If I<"HListbox"> is specified, you must have Tk::HListbox (v2.1+) installed 
or the application will fail with an error.

=item B<-listcmd>

Specifies a callback function to call when the button next to the entry is 
pressed to popup the choices in the listbox. This is called before popping up 
the listbox, so can be used to populate the entries in the listbox. 

=item B<-listfont>

Specify an alternate font for the text in the listbox. Use "-font" to change 
the text of the text entry field. For best results, "-font" and "-listfont" 
should specify fonts of similar size. 

=item B<-listrelief>

Specifies relief for the drop-down list (default is "sunken"). 

=item B<-listwidth>

Specifies the width of the popup listbox. 

=item B<-nobutton>

Whether or not to display the button that toggles the drop-down list.  
Set to 1 to hide.  Default B<0> (display the button).

Prevents drop-down list button from being displayed if set to 1 (true).

=item B<-noselecttext>

Normally, when the widget has the focus and is set by listbox selection, the 
text will then be "selected" (highlighted and in the cut-buffer), and will not 
"appear" to be selected in the drop-down listbox, if visible. Some consider 
this annoying.  Setting this option will cause the text to not be selected, 
but will still appear selected in the drop-down listbox (if visible).  
The user can still select the text themself, but either way, the selected 
item is in the cut buffer.

=item B<-tabcomplete>

If set to "1", pressing the "<Tab>" key will cause the string in the entry 
field to be "auto-completed" to the next matching item in the list. If there 
is no match, the typed text is not changed. If it already matches a list item, 
then the listbox is removed from view and keyboard focus transfers to the next 
widget. If set to "2" and there is no match in the list, then entry is reset 
to the default value or empty string.  If set to "0", focus is simply advanced 
to the next widget in the main window.  In either case, if the text field is 
changed, focus remains on the text field, otherwise focus advances to next 
widget, so, after completing, pressing [Tab] again advances to next widget.

=item B<-textbackground>

Specify alternate background for the entry field (when editable).

=item B<-textforeground>

Specify alternate foreground for the entry field (when editable).

=item B<-textdisabledbackground>

Specify alternate background for the entry field (when I<-state> is disabled).

=item B<-textdisabledforeground>

Specify alternate foreground for the entry field (when I<-state> is disabled).
Default:  B<-disabledforeground> or a dark grey.

=item B<-textreadonlybackground>

Specify alternate background for the entry field (when I<-state> is readonly).

=item B<-textreadonlyforeground>

Specify alternate foreground for the entry field (when I<-state> is readonly).
Default is a light gray.

=back

=head1 INHERITED OPTIONS

=over 4

=item B<-activestyle>

Specifies the style in which to draw the active element. This must be one of 
dotbox (show a focus ring around the active element), none (no special 
indication of active element) or underline (underline the active element).  
The default is underline.  Ignored (not supported) if B<-listboxtype> is set 
to I<HListbox>, in which case, I<"dotbox"> is always used.

=item B<-background>

Specifies the background color for the widget and it's subwidgets.  
NOTE:  In general, changing the widget's 
I<-foreground> and / or I<-background> options later via "$widget->configure() 
may not completely change all the colors of every part of every subwidget, 
and setPalette may not completely correct everything until the widget's 
I<-state> is changed, therefore, it's a good idea to also call 
$w->state($w->state()); after dynamically changing foreground or background 
colors for the widget.

=item B<-choices>

Specifies the list of initial choices to pop up.  This is a reference to an 
array or hash of strings specifying the choices.  If a I<hashref> is specified, 
the keys represent the actual data values and the values represent the 
corresponding values the user sees displayed in the listbox.  
NOTE:  If a I<hashref> is specified, the B<-variable> should be initialized 
to one of the hash VALUES rather than it's corresponding key.  
The individual items in the referenced array are normally simple text 
strings unless B<-listboxtype> is set to I<"HListbox">, in which case, each 
can be either a simple text string or a hashref to a hash of attributes and 
values representing a valid Tk::HListbox entry, for example: 
{-image => $thumbnailimage, -text => 'text string'}.

=item B<-foreground>

Specifies the foreground color for the widget and it's subwidgets.  

=item B<-height>

Specify the maximum number of items to be displayed in the listbox before a 
vertical scrollbar is automatically added. Default is infinity (listbox will 
not be given a scrollbar regardless of the number of items added). 

=item B<-maxwidth>

Specifies the maximum width the entry and listbox widgets can expand to in 
characters. The default is zero, meaning expand to the width to accomodate the 
widest string in the list.  (Ignored if B<-width> > 0 (a fixed width) 
is specified).

=item B<-variable>

Specifies a scalar reference to the variable in which the entered value is to 
be stored/retrieved (tied). 

=item B<-width>

The number of characters (average if proportional font used) wide to make the 
entry field. The drop-down list will be set the same width as the entry widget 
plus the width of the button. If not specified, the default is to calculate 
the width to the width of the longest item in the choices list and if items 
are later added or removed the width will be recalculated. 

=back

=head1 WIDGET METHODS

=over 4

=item $widget->B<activate>(index)

activate() invokes the activate() option on the listbox to make the item with the 
index specified by the first argument "active".  Unless a second argument is 
passed containing a false value, the value of the "-textvariable" variable is also 
set to this now active value.

=item $widget->B<choices>([listref])

Sets the drop-down list listbox to the list of values referenced by I<listref>, if
specified.  Returns the current list of choices in the listbox if no arguments 
provided.  If a I<hashref> is specified, the keys represent the actual data values 
and the values represent the corresponding values the user sees displayed in the 
listbox.  NOTE:  If a I<hashref> is specified, the B<-variable> should be initialized 
to one of the hash VALUES rather than it's corresponding key.  The individual items in 
the referenced array are normally simple text strings unless B<-listboxtype> is set to 
I<"HListbox">, in which case, each can be either a simple text string or a hashref to a 
hash of attributes and values representing a valid Tk::HListbox entry, for example: 
{-image => $thumbnailimage, -text => 'text string'}.

=item $widget->B<curselection>()

Returns the currently-selected element in the listbox, if any, otherwise, B<undef>.

=item $widget->B<delete>(first [, last])

Deletes one or more elements of the listbox.  First and last are indices specifying 
the first and last elements in the range to delete.  If last isn't specified it 
defaults to first, i.e. a single element is deleted.

=item $widget->B<delete_byvalue>(hashkey)

Deletes one or more elements of the listbox.  "hashkey" specifies the element to 
be deleted by the value visible to the user.

=item $widget->B<reference>(hashkey)

Returns the value (displayed in the listbox) that corresponds to the choice key 
specified by "hashkey".  If the key is not one of the valid choices or the choices 
are a list instead of a hash, then the hashkey itself is returned.  If the choices are 
a list rather than a hash, then the value is returned as is.  Returns B<undef> on error. 

=item $widget->B<dereference>(hashvalue)

Returns the actual option key value that corresponds to the choice value displayed 
in the listbox.  (undef if there is none).  (Opposite of reference() and 
referenceOnly().  Use this function on the -variable reference variable to get 
the actual data (hash key), since the reference variable will contain the VALUE 
displayed to the user!  If the choices are a list rather than a hash, then the 
value is returned as is.  Returns B<undef> on error. 

=item $widget->B<dereferenceOnly>(hashkey)

Returns 1 if the key specified by "hashkey" is one of the valid choices and the list 
of choices is a hash, otherwise B<undef> is returned.

=item $widget->B<get_hashref_byname>()

Returns a reference to the current hash of choices (keyed by the option visable to
the user) if the choice list is a hash (reversed from the hash passed to choices()), 
otherwise, B<undef> is returned.

=item $widget->B<get_hashref_byvalue>()

Returns a reference to the current hash of choices (keyed by actual option value) 
if the choice list is a hash (same as the hash passed to choices()), 
otherwise, B<undef> is returned.

=item $widget->B<get>([first [, last]])

get() with no arguments returns the current value of the "-textvariable" variable.  
If any arguments are passed, they are passed directly to the listbox->get() 
function, ie. "0", "end" to return all I<text> values of the listbox.  For choice 
hashes, the value returned is what is displayed to the user.  If Tk::HListbox is 
used, only the I<text> part of the entries are returned.  The arguments are indices.

=item $widget->B<get_icursor>([index])

Return the location of I<index> in the I<text-entry> field.  Values known to be 
valid are:  "insert" and "end", which return the character position of the insertion 
cursor and the location of the "end" of the current input string (ie. it's length).  
The cursor is set by the $widget->B<icursor> function.  If no argument (I<index>) is 
given, the index of the insertion cursor (I<"insert">) is returned.

=item $widget->B<get_index>(value)

Returns the index number in the list (zero-based) that can be used by get() of 
the value specified by "value", or undef if "value" is not in the list of choices.  
If the choice list is a hash, then "value" should be the value displayed (stored 
in the -variable reference variable), not the hash key.  This function is the 
reverse of the B<get>() function.

=item $widget->B<hasreference>(hashkey)

Returns the value (displayed in the listbox) that corresponds to the choice key 
specified by "hashkey".  If the key is not one of the valid choices or the choices 
are a list instead of a hash, then B<undef> is returned.

=item $widget->B<icursor>(index)

Sets the location of the text-entry field's text cursor to I<index>.  Valid values 
are numeric (zero for beginning) and "end" for placing the cursor at the end of the 
text.  The index can be retrieved by using the $widget->B<get_icursor>(index) function.

=item $widget->B<index>(index)

Invokes and returns the result of the listbox->index() function.

=item $widget->B<insert>(index, [item | list | listref | hashref])

Inserts one or more elements in the list just before the element given by index.  
If I<index> is specified as "end" then the new elements are added to the end of the list.
List can be a reference to a list (I<listref>).  If a hash reference is specified, 
then the values are displayed to the user in the drop-down list, but the values 
returned by the "-textvariable" variable or the get() function are the corresponding 
hash key(s).  The individual items in the referenced array are normally simple text 
strings unless B<-listboxtype> is set to I<"HListbox">, in which case, each can be 
either a simple text string or a hashref to a hash of attributes and values representing 
a valid Tk::HListbox entry, for example: {-image => $thumbnailimage, -text => 'text string'}.

=item $widget->B<selectionRange>(index1, index2)

Select (highlight) the text in the text-entry field between I<index1> and I<index2>.
Valid values are numeric (zero for beginning), "insert" and "end".

=item $widget->B<size>()

Invokes and returns the result of the listbox size() function (the number of items in 
the list).

=item $widget->B<state>([normal | readonly | text | textonly | disabled])

Get or set the state of the widget.

=item $widget->B<Popdown>([nofocusrestore])

Roll up (undisplay) the drop-down list.  If I<nofocusrestore> is specified and is true, no 
attempt will be made to refocus the previous widget focused when the drop-down list was 
popped up.  This is useful when the developer intends to immediately focus somewhere 
else.

=item $widget->B<PressButton>([nofocussave])

Activates drop-down list as if user pressed the button (unless state is "text" or "textonly" 
or "disabled".  Returns 1 if drop-down list activated, zero otherwise.  If the drop-down 
list is already visible, then removes it (pops it back down) and returns zero.
Available in versions 5.0 and later.  The current keyboard focus is saved for restoration 
when the drop-down list is rolled up unless I<nofocussave> is specified and is true, in 
which case, focus will remain with the JBrowseEntry widget whose button was "pressed".

=back

=head1 AUTHOR

Jim Turner, C<< <https://metacpan.org/author/TURNERJW> >>.

=head1 COPYRIGHT

Copyright (c) 2001-2018 Jim Turner C<< <mailto:turnerjw784@yahoo.com> >>.
All rights reserved.  

This program is free software; you can redistribute 
it and/or modify it under the same terms as Perl itself.

This is a derived work from Tk::Listbox and Tk::HList.

This code may be distributed under the same conditions as Perl itself.

This is a derived work from Tk::BrowseEntry.  Tk::BrowseEntry is 
copyrighted by Rajappa Iyer

=cut

package Tk::JBrowseEntry;

BEGIN
{
	use vars qw($VERSION $haveHListbox);
	$VERSION = '5.21';

	use strict;
	use Carp;
	use Tk;
	use Tk::Frame;
	eval 'use Tk::HMListbox; $haveHListbox = ($Tk::HListbox::VERSION >= 2.1) ? 1 : 0; 1';
	use base qw(Tk::Frame);
};

Construct Tk::Widget 'JBrowseEntry';

my ($BITMAP, $FOCUSEDBITMAP);
my $bummer = ($^O =~ /MSWin/) ? 1 : 0;

sub ClassInit
{
	my ($class,$mw) = @_;

	unless(defined($BITMAP))  #THIS TEST ACTUALLY SAVES TIME B/C IT ONLY DOES THIS ONCE IF MULTIPLE JBrowseEntry WIDGETS ARE DEFINED!
	{
		#DEFINE OUR VERY OWN DEFAULT BITMAP IMAGES FOR THE LITTLE BUTTON WIDGET (WINDOWS NEEDS DIFFERENT BUTTONS/SIZED!:

		$BITMAP = __PACKAGE__ . "::downarrwow";

		if ($Tk::platform =~ /Win32/)  #FIXME:NOT USING "bummer" HERE SINCE NOT SURE A/B cygwin PLATFORM SINCE THIS IS TK-DEPENDENT!
		{
			my $bits = pack("b10"x10,
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
			$mw->DefineBitmap($BITMAP => 10,10, $bits);
		}
		else
		{
			my $bits = pack("b11"x12,
					"....###....",
					"....###....",
					"....###....",
					"....###....",
					".#########.",
					"..#######..",
					"...#####...",
					"....###....",
					".....#.....",
					"...........",
					".#########.",
					".#########."
			);
			$mw->DefineBitmap($BITMAP => 11,12, $bits);
		}
		$FOCUSEDBITMAP = __PACKAGE__ . "::fdownarrow";

		if ($Tk::platform =~ /Win32/)
		{
			my $bits = pack("b10"x10,
					".#.#.#.#.#",
					".#.......#",
					"..........",
					".#########",
					"..#######.",
					".#.#####.#",
					"....###...",
					".#...#...#",
					"..........",
					".##.#.#.##"
			);
			$mw->DefineBitmap($FOCUSEDBITMAP => 10,10, $bits);
		}
		else
		{
			my $bits = pack("b11"x12,
					"....###....",
					"....###....",
					"....###....",
					"....###....",
					".#########.",
					"..#######..",
					"...#####...",
					"....###....",
					".....#.....",
					"...........",
					".#########.",
					".#########."
			);
			$mw->DefineBitmap($FOCUSEDBITMAP => 11,12, $bits);
		}
	}
}

sub Populate
{
	my ($w, $args) = @_;

	$w->{'btntakesfocus'} = 0;
	$w->{'btntakesfocus'} = delete ($args->{'-btntakesfocus'})  if (defined($args->{'-btntakesfocus'}));
	$w->{'arrowimage'} = $args->{'-arrowimage'}  if (defined($args->{'-arrowimage'}));
	$w->{'farrowimage'} = delete ($args->{'-farrowimage'})  if (defined($args->{'-farrowimage'}));
	$w->{'farrowimage'} ||= $w->{'arrowimage'}  if ($w->{'arrowimage'} && !$bummer);  #IN WINDOWS, LEAVE FOCUSED DEFAULT ALONE, OTHERWISE, IF SAME, THERE'S NO FOCUS INDICATOR!
	$w->{'mylistcmd'} = $args->{'-listcmd'}  if (defined($args->{'-listcmd'}));
	$w->{'takefocus'} = 1;
	$w->{'takefocus'} = delete ($args->{'-takefocus'})  if (defined($args->{'-takefocus'}));
	$w->{'-width'} = $args->{'-width'}  if (defined($args->{'-width'}));
	$w->{'-height'} = $args->{'-height'}  if (defined($args->{'-height'}));
	$w->{'-maxwidth'} = delete($args->{'-maxwidth'})  if (defined($args->{'-maxwidth'}));
	$w->{'-listwidth'} = $w->{'-width'};
#	$w->{'-foreground'} = $args->{'-foreground'}  if (defined($args->{'-foreground'}));
#	$w->{'-background'} = $args->{'-background'}  if (defined($args->{'-background'}));
#	$w->{'-background'} ||= $w->parent->cget('-background');
	my $initFG = defined($args->{'-foreground'}) ? $args->{'-foreground'} : $w->parent->cget('-foreground');
	my $initBG = defined($args->{'-background'}) ? $args->{'-background'} : $w->parent->cget('-background');
	foreach my $i (qw/-textreadonlyforeground/)
	{
		$w->{$i} = delete($args->{$i})  if (defined($args->{$i}));
	}
	foreach my $i (qw/-textbackground -textforeground -textdisabledbackground -textdisabledforeground
			-textreadonlybackground -labelbackground -labelforeground -buttonbackground -buttonforeground/)
	{
		$w->{$i} = $args->{$i}  if (defined($args->{$i}));
	}
#	$w->{'-foreground'} = $w->parent->cget('-foreground');
#	$w->{'-borderwidth'} = delete($args->{'-borderwidth'})  if (defined($args->{'-borderwidth'}));  #CHGD. TO NEXT 20070904 FROM WOLFRAM HUMANN.
	$w->{'-borderwidth'} = defined($args->{'-borderwidth'}) ? delete($args->{'-borderwidth'}) : 2; 
	$w->{'-relief'} = 'sunken';
	$w->{'-relief'} = delete($args->{'-relief'})  if (defined($args->{'-relief'}));
	$w->{'-listrelief'} = 'sunken';
	$w->{'-listrelief'} = delete($args->{'-listrelief'})  if (defined($args->{'-listrelief'}));
	$w->{'-listfont'} = delete($args->{'-listfont'})  if (defined($args->{'-listfont'}));
	$w->{'-labelfont'} = delete($args->{'-labelfont'})  if (defined($args->{'-labelfont'}));
	$w->{'-noselecttext'} = delete($args->{'-noselecttext'})  if (defined($args->{'-noselecttext'}));
	$w->{'-browse'} = 0;
	$w->{'-browse'} = delete($args->{'-browse'})  if (defined($args->{'-browse'}));
	$w->{'-tabcomplete'} = 0;
	$w->{'-tabcomplete'} = delete($args->{'-tabcomplete'})  if (defined($args->{'-tabcomplete'}));
	$w->{'-altbinding'} = 0;  #NEXT 2 ADDED 20050112 TO SUPPORT ALTERNATE KEY-ACTION MODELS.
	$w->{'-altbinding'} = delete($args->{'-altbinding'})  if (defined($args->{'-altbinding'}));
	#NEXT LINE ADDED 20060429 TO SUPPORT OPTION FOR USER DELETION OF LISTBOX ITEMS.
	$w->{'-deleteitemsok'} = delete($args->{'-deleteitemsok'})  if (defined($args->{'-deleteitemsok'}));
	$w->{'-framehighlightthickness'} = defined($args->{'-framehighlightthickness'})
		? delete($args->{'-framehighlightthickness'}) : 1;
	#NEXT 2 OPTIONS ADDED 20070904 BY JWT:
	$w->{'-buttonborderwidth'} = defined($args->{'-buttonborderwidth'})
		? delete($args->{'-buttonborderwidth'}) : 1;
	$w->{'-entryborderwidth'} = defined($args->{'-entryborderwidth'})
		? $args->{'-entryborderwidth'} : 0;
	$w->{'-nobutton'} = defined($args->{'-nobutton'})
		? delete($args->{-nobutton}) : 0;
	$w->{'-labelrelief'} = defined($args->{'-labelrelief'})
		? delete($args->{'-labelrelief'}) : 'flat';
	$w->{'-label'} = defined($args->{'-label'})
		? $args->{'-label'} : undef;
	#NEXT OPTIONS ADDED FOR v5.1 BY JWT:
	$w->{'-fixedlist'} = defined($args->{'-fixedlist'}) ? delete($args->{'-fixedlist'}) : 0;
	#HListbox-specific options (v5.1):
	$w->{'-listboxtype'} = defined($args->{'-listboxtype'})
		? delete($args->{'-listboxtype'}) : 'Listbox';
	$w->{'-itemtype'} = defined($args->{'-itemtype'}) ? delete($args->{'-itemtype'}) : 'text';
	$w->{'-indicator'} = defined($args->{'-indicator'}) ? delete($args->{'-indicator'}) : '0';
	$w->{'-activestyle'} = defined($args->{'-activestyle'}) ? delete($args->{'-activestyle'}) : 'underline';
	$w->{'-activestyle'} = defined($args->{'-activestyle'}) ? delete($args->{'-activestyle'}) : 'underline';
#	$w->{'-colorstate'} = defined($args->{'-colorstate'})
#		? $args->{'-colorstate'} : 0;

	my $lpack = delete $args->{-labelPack};   #MOVED ABOVE SUPER:POPULATE 20050120.

	$w->SUPER::Populate($args);

	# ENTRY WIDGET AND ARROW BUTTON

	unless (defined $lpack)
	{
		my $justify = ($w->{'-fixedlist'} =~ /top/) ? 's' : 'n';
		$lpack = ($w->{'-fixedlist'}) ? [-side => 'left', -anchor => $justify, -pady => 1, -ipady => 2]
				: [-side => 'left', -anchor => 'e', -ipady => 2];
	}

	my $ll = $w->Label();
	my $tf = $w->Frame(-borderwidth => ($w->{-borderwidth} || 2),
			-highlightcolor => $initFG, -highlightbackground => $initBG,
			-highlightthickness => ($w->{'-framehighlightthickness'} || 1), 
			-relief => ($w->{'-relief'} || 'sunken'));

	#DEPRECIATED(SOLVED): FOR SOME REASON, E HAS TO BE A LABENTRY, JUST PLAIN ENTRY WOULDN'T TAKE KEYBOARD EVENTS????
	#AFTER MUCH T&E: POUNDING OUT THE "e->bindtags()" FUNCTION CALL RESOLVED THIS ISSUE! :D
	my %entryHash = (-borderwidth => $w->{'-entryborderwidth'}||0, -relief => 'flat',
			-highlightcolor => $initFG, -highlightbackground => $initBG);
	if ($args->{'-colorstate'} == 1)
	{
		$entryHash{'-background'} = 'gray95';
		$entryHash{'-foreground'} = 'black';
	}
	my $e = $tf->Entry(%entryHash);
	$w->ConfigSpecs(DEFAULT => [$e]);
	my $b = $tf->Button(-borderwidth => $w->{'-buttonborderwidth'}, -takefocus => $w->{'btntakesfocus'}, 
			-bitmap => $BITMAP);
	if (defined $w->{'-label'})
	{
		$ll->pack(@$lpack);
	}
	else
	{
		$ll->packForget();   # REMOVE LABEL, IF NO VALUE SPECIFIED.
	}
	$w->Advertise('entry' => $e);   #TEXT PART.
	$w->Advertise('arrow' => $b);   #ARROW BUTTON PART.
	$w->Advertise('frame' => $tf);  #SURROUNDING FRAME PART.
	$w->Advertise('label' => $ll);  #SURROUNDING FRAME PART.
	$b->pack(-side => 'right', -padx => 0, -pady => 0, -fill => 'y')  unless ($w->{'-nobutton'});
	$e->pack(-side => 'right', -fill => 'x', -padx => 0, -pady => 0, -expand => 1);

	# POPUP SHELL FOR LISTBOX WITH VALUES.

	my ($c, $sl);
	if ($w->{'-listboxtype'} =~ /HList/i)
	{
		die "Error: You requested Tk::HListbox, but it does not appear to be installed or is < v2.1."
				unless ($haveHListbox);
		$w->{'-listboxtype'} = 'HListbox';
	}
	else
	{
		$w->{'-listboxtype'} = 'Listbox';
	}
	if ($w->{'-fixedlist'})
	{
		$tf->pack(-side => 'top', -padx => 0, -pady => 0, -fill => 'x', -expand => 1)
				unless ($w->{'-fixedlist'} =~ /top/);
		my $height = $w->{'-height'} ||= 3;
		$c = $w->Frame(-bd => 2, -relief => 'flat', -takefocus => 0);
		$sl = $c->Scrolled($w->{'-listboxtype'}, '-takefocus' => 0, '-selectmode' => 'browse', '-height' => $height, '-scrollbars' => 'oe', '-activestyle' => $w->{'-activestyle'}
		)->pack(-fill => 'x', -expand => 1);
		(my $lbtype = $w->{'-listboxtype'}) =~ tr/A-Z/a-z/;
		$sl->Subwidget($lbtype)->configure('-takefocus' => 0);
		$w->update;
		$c->pack(-side => 'top', -padx => 0, -pady => 0, -fill => 'both', -expand => 1);
		$tf->pack(-side => 'top', -padx => 0, -pady => 0, -fill => 'x', -expand => 1)
				if ($w->{'-fixedlist'} =~ /top/);
		$c->bind('<FocusIn>' => sub {
			if ($w->{'_lbignorefocus'} == 1)  #DON'T REFOCUS ON JUST POPPED-DOWN "BOUNCY" LISTBOX!
			{
				$w->{'_lbignorefocus'} = 0;
			}
			else
			{
				$sl->focus;
			}
			Tk->break;
		});  #AIN'T SUPPOSED TO TAKE FOCUS, BUT DOES, SO, MOVE ALONG!
		$e->bind('<FocusIn>' => sub { $w->Popdown(1); Tk->break });
	}
	else
	{
		$tf->pack(-side => 'top', -padx => 0, -pady => 0, -fill => 'x', -expand => 1);
		$c = $w->Toplevel(-bd => 2, -relief => 'raised');
		$c->overrideredirect(1);
		$c->withdraw;
		$sl = $c->Scrolled($w->{'-listboxtype'}, '-selectmode' => 'browse', '-scrollbars' => 'oe');
	}

	$w->{'-listboxtype'} =~ tr/A-Z/a-z/;

	#SPECIAL HLISTBOX CONFIGS:
	if ($w->{'-listboxtype'} =~ /h/)
	{
		foreach my $arg (qw/-indicator -itemtype/)
		{
			$sl->configure($arg => $w->{$arg});
		}
	}

	$w->Advertise('choices' => $c);   #LISTBOX POPUP MAIN WINDOW PART.
	$w->Advertise('slistbox' => $sl); #ACTUAL LISTBOX ITSELF.
	$sl->pack(-expand => 1, -fill => 'both');

	# OTHER INITIALIZATIONS.

	$w->SetBindings;
	$w->{"popped"} = 0;
	$w->Delegates('insert' => $sl, 'delete' => $sl, get => $sl, DEFAULT => $e);
	$w->ConfigSpecs(
			-listwidth   => [qw/PASSIVE  listWidth   ListWidth/,   undef],
			-maxwidth    => [qw/PASSIVE  maxWidth    MaxWidth/,    undef],
			-height      => [qw/PASSIVE  height      Height/,      undef],
			-listcmd     => [qw/CALLBACK listCmd     ListCmd/,     undef],
			-browsecmd   => [qw/CALLBACK browseCmd   BrowseCmd/,   undef],
			-deletecmd   => [qw/CALLBACK deleteCmd   DeleteCmd/,   undef],
			-choices     => [qw/METHOD   choices     Choices/,     undef],
			-state       => [qw/METHOD   state       State         normal/],
			-colorstate  => [qw/METHOD   undef       undef         0/],
			#-colorstate  => [qw/PASSIVE  colorState  ColorState/,  undef],
			-arrowimage  => [ {-image => $b}, qw/arrowImage ArrowImage/, undef],
			-variable    => '-textvariable',
			-label       => [ {-text => $ll}, qw/label Label/, undef],
				-labelrelief => [ {-relief => $ll}, qw/relief Relief/, undef],
				-labelbackground => [ {-background => $ll}, qw/background Background/, undef],
				-labelforeground => [ {-foreground => $ll}, qw/foreground Foreground/, undef],
				-labelfont => [ {-font => $ll}, qw/font Font/, undef],
				-textbackground => [ {-background => $e}, qw/background Background/, undef],
				-textforeground => [ {-foreground => $e}, qw/foreground Foreground/, undef],
				-textdisabledbackground => [ {-disabledbackground => $e}, qw/disabledBackground DisabledBackground/, undef],
				-textdisabledforeground => [ {-disabledforeground => $e}, qw/disabledForeground DisabledForeground/, undef],
				-textreadonlybackground => [ {-readonlybackground => $e}, qw/readonlyBackground ReadonlyBackground/, undef],
				#THIS ONE DOESN'T EXIST!: -textreadonlyforeground => [ {-readonlyforeground => $e}, qw/background Background/, undef],
				-entryborderwidth => [ {-borderwidth => $e}, qw/borderWidth BorderWidth/, 0],
				-buttonbackground => [ {-background => $b}, qw/background Background/, undef],
				-buttonforeground => [ {-foreground => $b}, qw/foreground Foreground/, undef],
			-background  => [[SELF, DESCENDANTS], qw/background   Background/,   undef],
			-foreground  => [[SELF, DESCENDANTS], qw/foreground   Foreground/,   undef],
			-default     => ['PASSIVE', undef, undef, ''],
		DEFAULT      => [$e] );

	$sl->configure(-relief => $w->{'-listrelief'}||'sunken');
	$sl->configure(-font => $w->{'-listfont'})  if ($w->{'-listfont'});
	$sl->Subwidget('yscrollbar')->configure(-takefocus => 0);
	my $state = (defined $args->{'-state'}) ? $args->{'-state'} : 'normal';
	my %argHash = ();
	my $haveSomething = 0;
	foreach my $a (keys %{$w})  #THIS UGLY HACK NEEDED TO INITIALIZE -labelforground, -labelbackground, ETC.:
	{
		if ($a =~ /^\-label(\w+)$/o) {
			$argHash{$a} = $w->{$a};
			++$haveSomething;
		}
	}
	$w->configure(%argHash)  if ($haveSomething);
no strict 'refs';
	my $var_ref = $w->cget( '-textvariable' );

	#SET UP DUMMY SO IT DISPLAYSS IF NO VARIABLE SPECIFIED:
	unless (defined($var_ref) && ref($var_ref))
	{
		$var_ref = '';
		$w->configure(-textvariable => \$var_ref);
	}
	eval { $w->{'default'} = $_[1]->{'-default'} || ${$_[1]->{'-variable'}}; };

}

sub focus   #CALLED WHENEVER MAIN WIDGET TAKES FOCUS:
{
	my ($w) = shift;

	if ($w->{'_ignorefocus'} == 1)  #DON'T CHANGE (SUBWIDGET) FOCUS EVEN THOUGH MAIN WIDGET IS TAKING FOCUS (NEEDED BY CLICKING ON THE FIXED DD-LIST):
	{
		$w->{'_ignorefocus'} = 0;
		return;
	}
	my ($state) = $w->cget( "-state" );
	my $fw = ($state eq 'readonly') ? 'frame' : 'entry';
	$w->Subwidget($fw)->configure(-highlightcolor => $w->Subwidget('frame')->cget('-background'))
			if ($fw eq 'entry');  #CLEAN UP ANY MESS MADE BY setPalette!
	$w->Subwidget($fw)->focus;

	#BUTTON GETS FOCUS IF BUTTON TAKES FOCUS, BUT WIDGET ITSELF DOESN'T.
	$w->Subwidget('arrow')->focus  if (!$w->{'takefocus'} && $w->{'btntakesfocus'});
	$w->Subwidget('entry')->icursor('end');
	$w->Subwidget('entry')->selectionRange(0,'end')
 				unless ($w->{'-noselecttext'} || !$w->Subwidget('entry')->index('end'));
	########Tk->break   #DON'T, IT WON'T RUN!
}

sub SetBindings
{
	my $w = shift;

	my $e = $w->Subwidget('entry');
	my $f = $w->Subwidget('frame');
	my $b = $w->Subwidget('arrow');
	my $sl = $w->Subwidget('slistbox');
	my $l = $sl->Subwidget($w->{'-listboxtype'});

	local *returnFn = sub   #HANDLES RETURN-KEY PRESSED IN ENTRY AREA.
	{
		my $self = shift;
		my $keyModifier = shift || '';
		$keyModifier .= '-'  if ($keyModifier =~ /\S/o);
		my ($state) = $w->cget( "-state" );
		my $altbinding = $w->{'-altbinding'};
		return if ($state eq 'disabled' || $altbinding =~ /Return\=None\b/io);

		if ($altbinding =~ /Return\=SingleGo/io
				&& $w->Subwidget('slistbox')->index('end') < 1)
		{
			#MAKE <RETURN> "GO" IF THE LISTBOX IS EMPTY:
			$w->Callback(-browsecmd => $w, $w->Subwidget('entry')->get, "entry.${keyModifier}return.go");
			Tk->break;
			return  if ($state =~ /text/o);
		}
		elsif ($altbinding =~ /Return\=Go/io)
		{
			$w->Popdown  if  ($w->{"popped"});   #ROLL UP (HIDE) LISTBOX.
			$w->Callback(-browsecmd => $w, $w->Subwidget('entry')->get, "entry.${keyModifier}return.go");
			Tk->break;
		}
		elsif ($altbinding =~ /Return\=NonEmptyGo/io)
		{
			my $textval = $w->get();
			if ($textval ne '')
			{
				$w->Popdown  if  ($w->{"popped"});   #UNDISPLAYS LISTBOX.
				$w->Callback(-browsecmd => $w, $w->Subwidget('entry')->get, "entry.${keyModifier}return.go");
				Tk->break;
			}
		}
		elsif ($altbinding =~ /Return\=Next/io)
		{
			$w->Popdown  if  ($w->{"popped"});   #UNDISPLAYS LISTBOX.
			$w->Callback(-browsecmd => $w, $w->Subwidget('entry')->get, "entry.${keyModifier}return.browse")
					if ($w->{'-browse'} == 1);
			$self->focusNext;
			Tk->break;
		}
		$w->LbFindSelection();
		if ($w->{'popped'})  #LISTBOX IS SHOWING:
		{
			$w->LbCopySelection(0,'entry.${keyModifier}return');
			Tk->break;
		}
		else
		{
			$w->Callback(-browsecmd => $w, $w->Subwidget('entry')->get, "entry.${keyModifier}return.browse")
					if ($w->{'-browse'} == 1);
			$w->PopupChoices;
		}
	};

	local *rightFn = sub   #RIGHT-ARROW PRESSED IN ENTRY: COMPLETE TEXT TO NEXT MATCHING SELECTION.
	{
		Tk->break  if ($e->index('insert') < $e->index('end')
				|| $w->{'-altbinding'} =~ /Right\=NoSearch/io);
		my ($state) = $w->cget( "-state" );
		return  if ($state eq 'textonly' || $state eq 'disabled' || $w->{'-altbinding'} =~ /Right\=None/io);

no strict 'refs';
		my $var_ref = $w->cget( '-textvariable' );
		return  unless ($$var_ref =~ /\S/o);  #TEXT FIELD EMPTY, PUNT!

		my @listsels = $w->getText('0','end');
		return  if ($#listsels < 0);  #NO LIST TO SEARCH, SO PUNT!

		my $srchPattern = $$var_ref;
		my $found = $w->LbFindSelection();   #SEARCH FOR CURRENT TEXT: RETURNS 1 IF FULL MATCH (IN LIST), -1 IF CONTAINS, 0 IF NO MATCH.
		return  unless ($found);  #NO MATCH, PUNT!

		my $index;
		$index = $w->LbIndex(2)  if ($found < 0 && $w->LbFindSelection($srchPattern)); #IF MATCH ONLY CONTAINS TEXT, SEARCH AGAIN STARTING AT *NEXT* ENTRY.
		if (defined $index) {
			$$var_ref = $listsels[$index];
			$e->icursor('end');
			$e->selectionRange(0,'end')  unless ($w->{'-noselecttext'} || !$e->index('end'));
		}
	};

	local *downFn = sub   #HANDLES DOWN-ARROW PRESSED IN ENTRY AREA.
	{
		my ($state) = $w->cget( '-state' );
		return  if ($state eq 'textonly' || $state eq 'disabled' || $w->{'altbinding'} =~ /Down\=None/io);

		if ($w->{'-altbinding'} =~ /Down\=Popup/io && $state !~ /text/o)  #MAKE DOWN-ARROW POP UP DD-LIST.
		{
			$w->LbFindSelection(); 
			if (!$w->{'-fixedlist'} && $w->{'popped'})  #LISTBOX IS SHOWING:
			{
				$w->LbCopySelection(1,'entry.down');
				Tk->break;
			}
			else
			{
				$w->PopupChoices;
			}
			return;
		}
		if ($w->{'popped'})  #LISTBOX IS SHOWING:
		{
			return if ($state eq 'text');

			$w->LbFindSelection(); 
			$w->Subwidget("slistbox")->focus;
		}
		else
		{
			$w->LbFindSelection();
			my $l = $w->Subwidget('slistbox')->Subwidget($w->{'-listboxtype'});
			my @listsels = $w->getText('0','end');
			my $index = $w->LbIndex(3);
			$l->selectionClear($index++);
			$index = 0  if ($index > $#listsels);
no strict 'refs';
			my $var_ref = $w->cget( '-textvariable' );
			$$var_ref = $listsels[$index];
			$l->activate($index);      #ADDED 20070904 PER PATCH FROM WOLFRAM HUMANN.
			$l->selectionSet($index);
			$l->see($index)  if ($w->{'-fixedlist'});
			$e->icursor('end');
			$e->selectionRange(0,'end')  unless ($w->{'-noselecttext'} || !$e->index('end'));
		}
	};

	local *upFn = sub   #HANDLES UP-ARROW PRESSED IN ENTRY AREA.
	{
		my ($state) = $w->cget( '-state' );
		return  if ($state eq 'textonly' || $state eq 'disabled' || $w->{'-altbinding'} =~ /Up\=None/io);

		if ($w->{'-altbinding'} =~ /Up\=Popup/io && $state !~ /text/o)  #MAKE DOWN-ARROW POP UP DD-LIST.
		{
			$w->LbFindSelection(); 
			if (!$w->{'-fixedlist'} && $w->{'popped'})  #LISTBOX IS SHOWING:
			{
				$w->LbCopySelection(1,'entry.down');
				Tk->break;
			}
			else
			{
				$w->PopupChoices;
			}
			return;
		}
		if ($w->{'popped'})  #LISTBOX IS SHOWING:
		{
			return if ($state eq 'text');

			$w->LbFindSelection();
			$w->Subwidget("slistbox")->focus;
		}
		else
		{
			$w->LbFindSelection();
			my $l = $w->Subwidget('slistbox')->Subwidget($w->{'-listboxtype'});
			my @listsels = $w->getText('0','end');
			my $index = $w->LbIndex(3);
			$l->selectionClear($index--);
			$index = $#listsels  if ($index < 0);
no strict 'refs';
			my $var_ref = $w->cget( '-textvariable' );
			$$var_ref = $listsels[$index];
			$l->activate($index);      #ADDED 20070904 PER PATCH FROM WOLFRAM HUMANN.
			$l->selectionSet($index);
			$l->see($index)  if ($w->{'-fixedlist'});
			$e->icursor('end');
			$e->selectionRange(0,'end')  unless ($w->{'-noselecttext'} || !$e->index('end'));
		}
	};

	local *escapeFn = sub   #HANDLES ESCAPE-KEY PRESSED IN ENTRY AREA.
	{
		return  if ($w->{'-altbinding'} =~ /Esc\=None/io);

		if ($w->{'popped'})  #LISTBOX IS SHOWING, ROLL IT UP:
		{
			$w->Popdown;
		}
		else   #JUST RESET TEXT FIELD TO DEFAULT OR EMPTY:
		{
no strict 'refs';
			my $var_ref = $w->cget( '-textvariable' );
			#if ($$var_ref eq $w->{'default'} && $w->cget( '-state' ) ne 'readonly')
			#CHGD. TO NEXT 20030531 PER PATCH BY FRANK HERRMANN.
			$$var_ref = (defined $w->{'default'} and $$var_ref eq $w->{'default'} 
					and $w->cget( '-state' ) ne 'readonly') ? '' : $w->{'default'};
			$e->icursor('end');
		}
		$e->selectionRange(0,'end')  unless ($w->{'-noselecttext'} || !$e->index('end'));   #ADDED 20020716
		Tk->break;
	};

	local *spacebarFn = sub   #HANDLES SPACEBAR PRESSED IN ENTRY AREA (ONLY MATTERS IN READONLY STATE):
	{
		return  if ($w->{'-altbinding'} =~ /Space\=None/io);

		my ($state) = $w->cget( '-state' );
		if ($state eq 'readonly')
		{
			my $res = $w->LbFindSelection();
			if ($w->{'popped'})  #LISTBOX IS SHOWING:
			{
				$w->LbCopySelection(0,'entry.space');
				Tk->break;
			}
			else
			{
				$w->PopupChoices;
				unless ($res)   #ADDED 20090320 TO CAUSE DROP-DOWN LIST TO POP DOWN W/ACTIVE CURSOR IN RIGHT PLACE (INSTEAD OF BOTTOM) IF NO MATCH:
				{
					$l->selectionClear('0','end');
					$l->activate(0);
					$l->selectionSet(0);
					$l->update();
					$l->see(0);
				}
			}
		}
	};

	# SET BIND TAGS

	$w->bindtags([$w, 'Tk::JBrowseEntry', $w->toplevel, 'all']);
########!!!!!!!!OK FOR LABENTRY, BUT *NOT* ENTRY (NOT SURE WHAT IT EVER DID)!!!: 	$e->bindtags([$e, $e->toplevel, 'all']);

	# IF USER-SPECIFIED IMAGE(S), CHANGE BUTTON IMAGE WHEN GETTING/LOSING FOCUS.

	$b->bind('<FocusIn>', sub
	{
		my $img = $w->{'farrowimage'};
		if ($img)
		{
			$b->configure(-image => $img);					
		}
		else   #RESET TO FOCUSED DEFAULT BITMAP:
		{
			$b->configure(-image => undef);
			$b->configure(-bitmap => $FOCUSEDBITMAP);
		}
		$w->{'savehl'} = $f->cget('-highlightcolor');
		my $framehlcolor = $f->cget('-background');
		$f->configure(-highlightcolor => $framehlcolor);
		Tk->break;
	});

	$b->bind('<FocusOut>', sub
	{
		$f->configure(-highlightcolor => $w->{'savehl'})  if ($w->{'savehl'});
		unless ($w->focusCurrent =~ /Listbox/o) {
			my $img = $w->{'arrowimage'}; # || $b->cget('-image');
			if ($img)
			{
				$b->configure(-image => $img);
			}
			else   #RESET TO UNFOCUSED DEFAULT BITMAP:
			{
				$b->configure(-image => undef);					
				$b->configure(-bitmap => $BITMAP);
			}
			Tk->break;
		}
	});

	$b->bind('<ButtonPress-1>', sub   #MOUSE CLICKED ON THE BUTTON:
	{
		unless ($b->cget( '-state' ) eq 'disabled')
		{
$w->LbFindSelection()  if ($w->{'popped'});  #(IF LISTBOX IS SHOWING, FIND & HIGHLIGHT CLOSEST MATCH TO TEXT):
			$w->PopupChoices;   #TOGGLES DISPLAY OF LISTBOX!
			if ($w->{'popped'})
			{
my $index = $w->LbIndex(1);

				$sl->focus;
				$sl->raise;
$l->activate($index);         #THIS UNDERLINES IT.
$l->selectionClear(0,'end');  #THIS HIGHLIGHTS IT (NEEDED 1ST TIME?!)
$l->selectionSet($index);     #THIS HIGHLIGHTS IT (NEEDED 1ST TIME?!)
				$w->{'_ignorefocus'} = 1;
			}
			else
			{
				$w->{'_ignorefocus'} = 0;
				$w->focus;
			}
$w->LbCopySelection(1,'button.button1');
		}
		Tk->break;
	});

	$b->bind('<Shift-ButtonRelease-1>', sub   #SHIFT-MOUSE1: SO USER CAN AVOID BOUNCE ON BOUNCY MENUS!
	{
		Tk->break;
	});

	$b->bind('<ButtonRelease-1>', sub   #MOUSE CLICKED ON THE BUTTON:
	{
		if ($w->{'popped'} && $w->{'-altbinding'} =~ /List\=Bouncy/io)
		{
			$w->{'_ignorefocus'} = 0;
			$w->{'_lbignorefocus'} = 1;
			$w->Popdown(1); #  if ($w->{'popped'} && $w->{'-altbinding'} =~ /List\=Bouncy/io);
			$w->focus();
		}
		Tk->break;
	});

	$b->bind('<space>', sub    #USER HIT SPACEBAR WHILST BUTTON FOCUSED (TOGGLE DD-LIST):
	{
		my ($state) = $w->cget( '-state' );
		return if ($state =~ /text/o || $state eq 'disabled');

		$w->LbFindSelection();
		$w->PopupChoices;
	});

	$b->bind('<Return>', sub   #USER HIT [RETURN] KEY WHILST BUTTON FOCUSED (TOGGLE DD-LIST):
	{
		my ($state) = $w->cget( '-state' );
		return if ($state =~ /text/o || $state eq 'disabled');

		$w->LbFindSelection();
		$w->PopupChoices;
		Tk->break;
	});

	$b->bind('<Down>', sub   #USER HIT [DOWN-ARROW] KEY WHILST BUTTON FOCUSED (TOGGLE DD-LIST):
	{
		my ($state) = $w->cget( '-state' );
		return if ($state =~ /text/o || $state eq 'disabled');

		$w->LbFindSelection();
		$w->PopupChoices;
		Tk->break;
	});

	$e->bind('<Shift-Return>', [\&returnFn, 'mod.Shift']);  #REPORT ANY MODIFIERS PRESSED W/[RETURN] KEY:
	$f->bind('<Shift-Return>', [\&returnFn, 'mod.Shift']);
	$e->bind('<Control-Return>', [\&returnFn, 'mod.Control']);
	$f->bind('<Control-Return>', [\&returnFn, 'mod.Control']);
	$e->bind('<Alt-Return>', [\&returnFn, 'mod.Alt']);
	$f->bind('<Alt-Return>', [\&returnFn, 'mod.Alt']);
	$e->bind('<Return>', \&returnFn);
	$f->bind('<Return>', \&returnFn);

	$e->bind('<Down>', \&downFn);
	$f->bind('<Down>', \&downFn);

	$e->bind('<space>', \&spacebarFn);
	$f->bind('<space>', \&spacebarFn);

	$e->bind('<Up>', \&upFn);
	$f->bind('<Up>', \&upFn);

	$e->bind('<Escape>' => \&escapeFn);
	$f->bind('<Escape>' => \&escapeFn);

	$e->bind('<Left>', sub {Tk->break;});
	$e->bind('<Right>', \&rightFn);
	$f->bind('<Left>', sub {Tk->break;});
	$f->bind('<Right>', \&rightFn);

	$e->bind('<<LeftTab>>', sub      #ADDED 20070904 PER PATCH FROM WOLFRAM HUMANN (HANDLES REVERSE-TABBING):
	{
		my ($state) = $w->cget( '-state' );
		$w->Popdown  if  ($w->{'popped'});
		if ($state =~ /only/o || (!$w->{'takefocus'} && !$w->{'btntakesfocus'}))
		{
			$w->focusPrev;
		}
		else
		{
			$w->focusCurrent->focusPrev;
			$w->focusCurrent->focusPrev  unless ($state =~ /only/o);
		}
		Tk->break;
	});

	$f->bind('<<LeftTab>>', sub   #FRAME HAS FOCUS INSTEAD OF ENTRY WHEN READONLY!:
	{
		my ($state) = $w->cget( '-state' );
		$w->Popdown  if  ($w->{'popped'});
		if ($state =~ /only/o || (!$w->{'takefocus'} && !$w->{'btntakesfocus'}))
		{
			$w->focusPrev;
		}
		else
		{
			$w->focusCurrent->focusPrev;
			$w->focusCurrent->focusPrev  unless ($state =~ /only/o);
		}
		Tk->break;
	});

	$b->bind('<<LeftTab>>', sub   #ADDED 20180621 TO PROPERLY REVERSE TABBING FROM ENTRY TO BUTTON (JFileDialog)!
	{
		$w->Popdown  if  ($w->{'popped'});
		if ($w->{'takefocus'})
		{
			$w->focus;
		}
		else
		{
			$w->focusPrev;
		}
		Tk->break;
	});

	$b->bind('<Tab>', sub
	{
		$w->Popdown(1)  if (!$w->{'-takefocus'});
		#DON'T BREAK, JUST ALLOW TAB TO MOVE ON TO NEXT WIDGET.
	});

	$e->bind('<Tab>', sub
	{
		my $same = 1;  #VALUE HASN'T CHANGED, MOVE TO NEXT WIDGET (TAB-COMPLETE STOPS THIS!)
		#NEXT LINE ADDED 20030531 PER PATCH BY FRANK HERRMANN.
		$w->Callback(-browsecmd => $w, $w->Subwidget('entry')->get, 'entry.tab')
				if ($w->{'-browse'} == 1);
		if ($w->{'-tabcomplete'} && $w->cget('-state') !~ /(?:textonly|disabled)/o)
		{
no strict 'refs';
			my $var_ref = $w->cget( '-textvariable' );
			return  unless ($$var_ref =~ /\S/o);  #TEXT FIELD EMPTY, PUNT!

			my @listsels = $w->getText('0','end');
			my $srchPattern = $$var_ref;
			my $found = $w->LbFindSelection();   #SEARCH FOR CURRENT TEXT: RETURNS 1 IF FULL MATCH (IN LIST), -1 IF CONTAINS, 0 IF NO MATCH.
			if ($found)
			{
				my $index;
				$index = $w->LbIndex(2)  if ($found < 0 && $w->LbFindSelection($srchPattern)); #IF MATCH ONLY CONTAINS TEXT, SEARCH AGAIN STARTING AT *NEXT* ENTRY.
				if (defined $index) {
					$$var_ref = $listsels[$index];
					$e->icursor('end');
					$e->selectionRange(0,'end')  unless ($w->{'-noselecttext'} || !$e->index('end'));
					$same = 0;
				}
			}
			elsif ($w->{'-tabcomplete'} == 2)
			{
				#THIS CODE FORCES TAB TO CHANGE TEXT ENTERED TO THE DEFAULT VALUE IF NOTHING MATCHED!
				#THIS SUCKS IF THERE IS NO LIST OR USER WISHES TO OVERRIDE THE VALUE AND THEN TAB ON!
				unless ($$var_ref eq ((defined $w->{'default'}) ? $w->{'default'} : ''))
				{
					$$var_ref = (defined $w->{'default'}) ? $w->{'default'} : '';
					$e->icursor('end');
					$same = 0;
				}
			}
			$e->selectionRange(0,'end')  unless ($w->{'-noselecttext'} || !$e->index('end'));
		}
		else
		{
			$w->{'searchindx'} = 0;
		}
		my $wasPoppedAlready = $w->{'popped'};
		$w->Popdown(1)  if ($wasPoppedAlready);   #UNDISPLAYS LISTBOX.
		if ($same)  #TEXT NOT CHANGED TY TAB-COMPLETION:
		{
			my $state = $w->cget('-state');
			if (!$wasPoppedAlready && $w->{'-altbinding'} =~ /Tab\=Popup/io
					&& $state !~ /(?:text|disabled)/o)
			{
				$w->PopupChoices;   #TOGGLE STATE OF DD-LIST:
			}
			else   #JUST TRY TO GO TO NEXT WIDGET IN MAIN WINDOW:
			{
				my $self = shift;
				$self->focusNext;
			}
		}
		Tk->break;
	});

	$f->bind('<Tab>', sub
	{
		#NEXT LINE ADDED 20030531 PER PATCH BY FRANK HERRMANN.
		$w->Callback(-browsecmd => $w, $w->Subwidget('entry')->get, 'frame.tab')
				if ($w->{'-browse'} == 1);
		$w->{'searchindx'} = 0;
		my $wasPoppedAlready = $w->{'popped'};
		$w->Popdown(1)  if ($wasPoppedAlready);   #UNDISPLAYS LISTBOX.
		my $state = $w->cget('-state');
		if (!$wasPoppedAlready && $w->{'-altbinding'} =~ /Tab\=Popup/io
				&& $state !~ /(?:text|disabled)/o)
		{
			$w->PopupChoices;
		}
		else   #TRY TO GO TO NEXT WIDGET IN MAIN WINDOW:
		{
			my $self = shift;
			$self->focusNext;
		}
		Tk->break;
	});

	# KEYBOARD BINDINGS FOR LISTBOX

	$l->configure(-selectmode => 'browse');

	local *ListboxMoused = sub {
		if ($w->cget('-state') =~ /^(?:normal|readonly)/)
		{
			my $self = shift;
			my $keyModifier = shift || '';
			my $s = $w->Subwidget("slistbox");
			my $e = $s->XEvent;

			$s->focus;
			$w->LbClose  unless (defined $e);   #POPS DOWN (ROLLS UP LIST)
			$w->LbChoose($l->XEvent->x, $l->XEvent->y, $keyModifier);
			if (($w->{'-altbinding'} !~ /List\=Bouncy/io || $keyModifier =~ /mod/o)
					&& $w->{'-fixedlist'} && !$w->{'popped'})  #"POP UP" DD-LIST W/O ACTUALLY POPPING IT UP (CALLING PopupChoices() PUTS FOCUS BACK ON ENTRY FIELD)!
			{
				$s->Subwidget($w->{'-listboxtype'})->configure('-takefocus' => 1);
				$w->{'popped'} = 1;
#MUSN'T DO (& DON'T NEED!):			$w->LbFindSelection();
				$s->see('active');
				$w->Subwidget('choices')->configure(-cursor => 'arrow');
				$w->{'_ignorefocus'} = 1;
			}
			else
			{
				$w->{'_lbignorefocus'} = 1  if ($w->{'-fixedlist'} && $w->{'-altbinding'} =~ /List\=Bouncy/io && $keyModifier !~ /mod/o);
				$w->{'_ignorefocus'} = 0;
				$w->focus;
			}
		}
		Tk->break;
	};

	$l->bind('<Shift-ButtonRelease-1>', [\&ListboxMoused,'mod.Shift']);
	$l->bind('<Control-ButtonRelease-1>', [\&ListboxMoused,'mod.Control']);
	$l->bind('<Alt-ButtonRelease-1>', [\&ListboxMoused,'mod.Alt']);
	$l->bind('<ButtonRelease-1>', [\&ListboxMoused]);
	$l->bind('<Escape>' => sub   #[Escape] PRESSED IN DD-LIST (CLEAR ANY ENTRY SELECTED AND ROLL IT UP):
	{
		$w->{'_ignorefocus'} = 0;
		$w->LbClose;
		Tk->break;
	});

	$l->bind('<Return>' => sub   #[Return] PRESSED IN DD-LIST (COPY SELECTED ENTRY TO TEXT FIELD):
	{
		$w->{'_ignorefocus'} = 0;
		$w->LbCopySelection(0,'listbox.return');
		Tk->break;
	});

	$l->bind('<space>' => sub    #[Spacebar] PRESSED IN DD-LIST (COPY SELECTED ENTRY TO TEXT FIELD):
	{
		my $state = $w->cget('-state');
		my $index = $w->LbIndex(1);

		$w->{'_ignorefocus'} = 0;
		$w->LbCopySelection(0,'listbox.space',1);
		Tk->break;
	});

	$l->bind('<Tab>' => sub   #[Tab] PRESSED IN DD-LIST:
	{
		#THE TRICK HERE IS WE WANT TO UN-POP (ROLL-UP) THE DD-LIST WHEN TABBING OFF OF
		#IT UNLESS "Tab=KeepList" IS SET AND WE'RE NOT A "FIXED" LIST:
		$w->{'_ignorefocus'} = 0;
		if ($w->{'-fixedlist'} || ($w->{'-altbinding'} !~ /Tab\=KeepList/io
				&& $w->{'-altbinding'} !~ /Tab\=Popup/io))  #THIS LAST TEST JUST TO PREVENT TRAPPING USER IN A TABBING CIRCLEJERK BETWEEN DD-LIST AND ENTRY FIELD!
		{
			#BEHAVE LIKE MODERN COMBOS - SIMPLY HIDE THE LISTBOX AND FOCUS BACK ON THE TEXT FIELD 
			#W/O CHANGING IT'S CONTENT:
			#NOTE: IF WE'RE A "FIXED" LIST, WE *MUST* CALL "Popdown" EVEN THOUGH THE 
			#LIST *ALWAYS* REMAINS DISPLAYED, THE PGM IS TOLD THAT IT'S "POPPED DOWN"!!
			if ($w->{'-altbinding'} !~ /Tab\=Popup/io)  #GO TO NEXT WIDGET:
			{
				$w->Popdown;  #ROLLS UP DD-LIST (WHEN NOT FIXED), THEN MOVES FOCUS (BACK) TO THE ENTRY FIELD.
				Tk->break;    #WE'VE SET FOCUS, SO DON'T LET TAB DO IT'S NORMAL THING AND MOVE FOCUS!
			}
			else  #GO BACK TO CURRENT WIDGET'S ENTRY (OR BUTTON):
			{
				$w->Popdown(1);  #ROLLS UP DD-LIST (WHEN NOT FIXED) & LETS TAB MOVE FOCUS TO *NEXT* WIDGET (DON'T WANT TO END UP IN A TABBING CIRCLEJERK)!
			}
		}
		else  #BEHAVE OUR OLD WAY: LEAVE DD-LIST SHOWING (DON'T "Popdown"), BUT PUT FOCUS ON THE TEXT FIELD W/O CHANGING IT'S CONTENT (UNLESS "TAB-COMPLETE" CHANGES IT):
		{
			if ($w->{'-tabcomplete'} && $w->LbFindSelection())  #IF TAB COMPLETES SELECTION, SET TEXT FIELD TO NEAREST MATCH IN LIST:
			{
				#WE'RE DOING TAB-COMPLETE, SO FIND THE NEAREST MATCHING ITEM IN DD-LIST AND SET TEXT TO IT:
				my @listsels = $w->getText('0','end');
				my $index = $w->LbIndex(1);
no strict 'refs';
				my $var_ref = $w->cget( '-textvariable' );
				$$var_ref = $listsels[$index]  unless ($$var_ref eq $listsels[$index])
			}   #OTHERWISE, LEAVE TEXT FIELD ALONE.
			#SET THE TEXT CURSOR TO END AND HIGHLIGHT (UNLESS -noselectext):
			$e->icursor('end');
			$e->selectionRange(0,'end')  unless ($w->{'-noselecttext'} || !$e->index('end'));
			$w->focus;   #MANUALLY MOVE FOCUS BACK TO THE ENTRY FIELD (OR BUTTON).
			Tk->break;   #WE'VE SET FOCUS, SO DON'T LET TAB DO IT'S NORMAL THING AND MOVE FOCUS!
		}
	});

	$l->bind('<<LeftTab>>' => sub   #[Shift-Tab] (REVERSE-TAB) PRESSED IN DD-LIST:
	{
		$w->{'_ignorefocus'} = 0;  #MAKE SURE THE WIDGET WILL TAKE THE FOCUS.
		$w->Popdown; #THIS ROLLS UP DD-LIST (WHEN NOT FIXED), THEN ALWAYS MOVES FOCUS (BACK) TO THE ENTRY FIELD.
		Tk->break;   #WE'VE SET FOCUS, SO DON'T LET TAB DO IT'S NORMAL THING AND MOVE FOCUS!
	});

	if ($w->{'-deleteitemsok'})   #USER IS ALLOWED TO DELETE DD-LIST ENTRIES W/[Delete] KEY:
	{
		$l->bind('<Delete>' => sub  #[Delete] KEY PRESSED IN DD-LIST (DELETE SELECTED ENTRY, IF USER ALLOWED TO):
		{
			my $index = $w->LbIndex;

			$w->{'_ignorefocus'} = 0;
			if (defined($index) && $index >= 0)
			{
				my $x = $w->Callback('-deletecmd', $w, $w->LbIndex);  #CALL 1ST (W/INDEX OF ITEM 2B DELETED) BEFORE DELETING (PROGRAMMER CAN BLOCK THE DELETE PENDING THE RESULT)!
				if (!defined($x) || !$x)   #IF NO CALLBACK -OR- CALLBACK RETURNS FALSE, DELETE THE ITEM HIGHLIGHTED:
				{
					$w->delete($index);
					$w->Callback('-deletecmd', $w, -1);   #CALL AGAIN W/-1 TO ALLOW PROGRAMMER TO DO SOMETHING WHEN DELETED, IE. UPDATE A CURRENT ITEM LIST VARABLE, ETC!
				}
			}
		});   #ADDED 20060429 TO SUPPORT OPTION FOR USER DELETION OF LISTBOX ITEMS.
	}
	if ($ENV{'jwtlistboxhack'}) {   #WE'RE USIN' OUR HACKED LISTBOX THAT CAN TELL US IF WE'RE AT TOP OR BOTTOM!:
		$l->bind('<<ListboxTop>>' => sub {
			if ($w->{'-altbinding'} =~ /Listbox\=Circular/io) {  #WE'RE AT TOP OF CIRCULAR LIST, SO CIRCLE BACK TO BOTTOM!:
				$l->selectionClear('0','end');
				$l->activate('end');
				$l->selectionSet('end');
				$l->update();
				$l->see('end');
				Tk->break;
			} elsif ($w->{'-altbinding'} =~ /(?:Down|Up)\=Popup/io) {  #WE'RE AT TOP, UN-POP THE LISTBOX!:
				$w->Popdown;
				$e->icursor('end');
				$e->selectionRange(0,'end')  unless ($w->{'-noselecttext'} || !$e->index('end'));   #ADDED 20020716
			}
		});
		$l->bind('<<ListboxBottom>>' => sub {
			if ($w->{'-altbinding'} =~ /Listbox\=Circular/io) {  #WE'RE AT BOTTOM OF CIRCULAR LIST, SO CIRCLE BACK TO TOP!:
				$l->selectionClear('0','end');
				$l->activate(0);
				$l->selectionSet(0);
				$l->update();
				$l->see(0);
				Tk->break;
			} elsif ($w->{'-altbinding'} =~ /(?:Down|Up)\=Popup/io) {  #WE'RE AT TOP, UN-POP THE LISTBOX!:
				$w->Popdown;
				$e->icursor('end');
				$e->selectionRange(0,'end')  unless ($w->{'-noselecttext'} || !$e->index('end'));   #ADDED 20020716
			}
		});
	}
	$l->bind('<Key>' => [\&keyFn,$w,$e,$l,1]);  
	$e->bind('<Key>' => [\&keyFn,$w,$e,$l]);
	$f->bind('<Key>' => [\&keyFn,$w,$e,$l]);
	$e->bind('<ButtonRelease-1>' => sub {    #MOUSE CLICKED ON ENTRY FIELD:
		my ($state) = $w->cget( '-state' );
		if ($state eq 'readonly')
		{
			my $res = $w->LbFindSelection();
			if ($w->{'popped'})  #LISTBOX IS SHOWING:
			{
				$w->Popdown(1);
			}
			else
			{
				unless ($res)   #ADDED 20090320 TO CAUSE DROP-DOWN LIST TO POP DOWN W/ACTIVE CURSOR IN RIGHT PLACE (INSTEAD OF BOTTOM) IF ENTRY FIELD EMPTY.
				{
					$l->selectionClear('0','end');
					$l->activate(0);
					$l->selectionSet(0);
					$l->update();
					$l->see(0);
				}
				$w->PopupChoices;
			}
 	    		Tk->break;
		}
		else
		{
			$w->Popdown  if ($w->{'popped'});
 	    		Tk->break;
		}
	});

	#NEXT 3 LINES ADDED 20030531 PER PATCH BY FRANK HERRMANN.
	# ALLOW CLICK OUTSIDE THE POPPED UP LISTBOX TO POP IT DOWN.

	$w->bind('<ButtonRelease-1>', sub
	{
		$w->Popdown(1)  if ($w->{'popped'});
		Tk->break;
	});

	$w->parent->bind('<ButtonRelease-1>', sub
	{
		$w->Popdown(1)  if ($w->{'popped'});
		Tk->break;
	});

	$w->bind('<FocusIn>', \&focus);
}

sub keyFn   #JWT: TRAP LETTERS PRESSED AND ADJUST SELECTION ACCORDINGLY.
{
	my ($x,$w,$e,$l,$flag) = @_;   #FLAG IS 1 IF CALLED FROM THE LISTBOX.
	my $mykey = $x->XEvent->A;     #DOESN'T SEEM TO GET CALLED IF USER TYPES A SPACE?!

	$flag = 0  unless (defined $flag);
	#NEXT LINE ADDED 20030531 PER PATCH BY FRANK HERRMANN.
	if (!$flag && $w->{'-browse'} == 1 && ($mykey =~ /\S/o || $mykey eq ' ')) {
		$w->Callback(-browsecmd => $w, $w->Subwidget('entry')->get, "key.$mykey");
	}

	if ($w->cget( '-state' ) eq 'readonly')  #ADDED 20020711 TO ALLOW TYPING 1ST LETTER TO SELECT NEXT VALID ITEM!
	{
		$w->LbFindSelection($mykey)  if ($mykey);  #JUMP TO 1ST ITEM STARTING WITH THIS KEY
		$w->LbCopySelection(1,"key.$mykey");
	}
	elsif ($flag == 1)      #LISTBOX HAS FOCUS:
	{
		$w->{'_ignorefocus'} = 0;
		$w->LbFindSelection($mykey)  if ($mykey =~ /\S/o);  #JUMP TO NEXT ITEM STARTING WITH THIS KEY
	}
	else                    #TEXT FIELD HAS FOCUS:
	{
		$w->LbFindSelection()  if ($mykey =~ /\S/o);  #JUMP TO 1ST ITEM MATCHING TEXT FIELD.
		if (!$flag && $w->{'-browse'} == 1 && ($mykey =~ /\S/o || $mykey eq ' ')) {
			$w->Subwidget('entry')->selectionRange(0,'end')
					unless ($w->{'-noselecttext'} || !$w->Subwidget('entry')->index('end'));
			$e->icursor('end');
		}
	}
}

sub PressButton  #NEW USER-CALLABLE FUNCTION (v5.0+) TO EFFECT A DROP-DOWN BUTTON PRESS (POPUP DD-LIST & GIVE IT FOCUS):
{
	my $w = shift;
	my $nofocussave = shift||0;
	my $state = $w->cget( '-state' );
	return 0  if ($state =~ /text/o || $state eq 'disabled');

	$w->{'savefocus'} = $w->focusCurrent  unless ($nofocussave);
	$w->PopupChoices;
	return 1;
}

sub PopupChoices   #TOGGLE STATE OF DD-LIST (POP UP OR DOWN):
{
	my $w = shift;
	my ($state) = $w->cget( '-state' );

	return  if ($state =~ /text/o || $state eq 'disabled');
	return  unless ($w->getText('0','end'));

	if ($w->{'popped'})  #DD-LIST DISPLAYED, ROLL IT UP:
	{
		$w->Popdown(1);
	}
	else                 #DD-LIST NOT DISPLAYED, POP IT UP:
	{
		my $x = $w->Callback(-listcmd, $w);
		return undef  if (defined($x) && $x =~ /nolist/io);   #IF -listcmd CALLBACK RETURNS 'nolist',
		my $c = $w->Subwidget('choices');
		my $s = $w->Subwidget('slistbox');
		if ($w->{'-fixedlist'})  #IF WE'RE A FIXED LIST (ALWAYS DISPLAYED), JUST MARK IT POPPED UP & GIVE IT FOCUS:
		{
			$s->Subwidget($w->{'-listboxtype'})->configure('-takefocus' => 1);
			$w->{'popped'} = 1;
			$w->LbFindSelection();
			$s->see('active');
			$c->configure(-cursor => 'arrow');
			$s->focus;
			$w->grab;
			return;
		}
		my $e = $w->Subwidget('entry');
		my $a = $w->Subwidget('arrow');
		my $wheight = $w->cget('-height');
		my $sll = $s->Subwidget($w->{'-listboxtype'});
		my $rw = $c->width; 
		my ($itemcnt) = $sll->index('end');
		$wheight = 10  unless ($wheight);
		$wheight = $itemcnt  if ($itemcnt < $wheight);
		$wheight = $itemcnt  unless ($wheight);
		$wheight = $itemcnt  unless ($wheight || $itemcnt > 10);
		if ($wheight)
		{
			$sll->configure(-height => ($wheight * $w->height));
			$w->update;
		}

		my $y1 = $e->rooty + $e->height + 3;
		#my $bd = $c->cget(-bd) + $c->cget(-highlightthickness);  #CHGD. TO NEXT 20050120.
		my $bd = $c->cget(-bd);
		my ($unitpixels, $ht, $x1, $ee, $width, $x2);
		if ($bummer)
		{
			$y1 -= 3 - ($w->{'-borderheight'} || 2);
			#$unitpixels = $e->height + 1;  #CHGD. TO NEXT 20040827 - WINBLOWS XP SEEMS TO NOT BEVEL THE HIGHLIGHT CURSOR, 
			$unitpixels = $e->height - 1;   #SO THE WIDTH OF EACH ITEM IS NOW 2 PIXELS SMALLER! (USE OLD LINE, IF BEVELLED)!
			$ht = ($wheight * $unitpixels) + (2 * $bd) + 4;
			$ee = $w->Subwidget('frame');
			$x1 = $ee->rootx;
			$x2 = $a->rootx + $a->width;
			$width = ($w->{'-nobutton'}) ? ($e->width + ($w->{'-borderwidth'} || 2)) : ($x2 - $x1);
			if ($w->{'-nobutton'})
			{
				my $wheight = $w->cget('-height');
				if (defined($wheight) && $wheight > 0) {
					my $itemcnt = $sll->index('end');
					$width += $s->Subwidget('yscrollbar')->cget('-width') + 6;
				}
			}
			#$rw = $width + $w->{'-borderwidth'};
			#CHGD. TO NEXT 20030531 PER PATCH BY FRANK HERRMANN.
			#$rw = ($width || 0) + ($w->{'-borderwidth'} || 0);
			$rw = $width;
			$x1 += 1;  #FUDGE MORE FOR WINDOWS (THINNER BORDER) TO MAKE DROP-DOWN LINE UP VERTICALLY W/ENTRY&BUTTON.
		}
		else
		{
			$y1 -= 3 - ($w->{'-borderheight'} || 2);
			#$unitpixels = $e->height - 1;   #CHGD. TO NEXT 2 20050120.
			$unitpixels = $e->height - (2 * $w->cget('-highlightthickness'));
			$unitpixels += 1;
			$ht = ($wheight * $unitpixels) + (2 * $bd) + 6;
			$ee = $w->Subwidget('frame');
			$x1 = $ee->rootx;
			$x2 = $a->rootx + $a->width;
			$width = ($w->{'-nobutton'}) ? ($e->width + ($w->{'-borderwidth'} || 2)) : ($x2 - $x1);
			if ($w->{'-nobutton'})
			{
				my $wheight = $w->cget('-height');
				if (defined($wheight) && $wheight > 0) {
					my $itemcnt = $sll->index('end');
					$width += $s->Subwidget('yscrollbar')->cget('-width') + 6;
				}
			}
			$rw = $width;    #ADDED 20020815 TO CAUSE LISTBOX TO ADJUST WIDTH TO SAME AS VARYING ENTRY FIELD!
#			if ($first)   -- REMOVED 20070904 PER PATCH BY WOLFRAM HUMANN
#			{
				#NEXT LINE ADDED 20030531 PER PATCH BY FRANK HERRMANN.
				$w->{'-borderwidth'} = 0  unless (defined $w->{'-borderwidth'});
#				$rw += 1 + int($w->{'-borderwidth'} / 2);  -- CHGD. TO NEXT 20070904 - SEEMS TO WORK BETTER!
				$rw += $w->{'-borderwidth'};
#				$first = 0;   -- REMOVED 20070904 PER PATCH BY WOLFRAM HUMANN
				#THANKS, WOLFRAM!
#			}

			# IF LISTBOX IS TOO FAR RIGHT, PULL IT BACK TO THE LEFT

			$x1 = $w->vrootwidth - $width  if ($x2 > $w->vrootwidth);
			$x1 += 1;  #FUDGE MORE FOR WINDOWS (THINNER BORDER) TO MAKE DROP-DOWN LINE UP VERTICALLY W/ENTRY&BUTTON.
		}

		# IF LISTBOX IS TOO FAR LEFT, PULL IT BACK TO THE RIGHT

		$x1 = 0  if ($x1 < 0);

		# IF LISTBOX IS BELOW BOTTOM OF SCREEN, PULL IT UP.

		my $y2 = $y1 + $ht;
		$y1 = $y1 - $ht - ($e->height - 5)  if ($y2 > $w->vrootheight);
		$c->geometry(sprintf('%dx%d+%d+%d', $rw, $ht, $x1, $y1));
		$c->deiconify;
		$c->raise;
		$s->focus;
		$w->{'popped'} = 1;

		$w->LbFindSelection();
		$s->see('active');
		$c->configure(-cursor => 'arrow');
		$w->grabGlobal;
		$s->focus;
	}
}

sub LbChoose  # CHOOSE VALUE FROM LISTBOX WITH THE MOUSE IF APPROPRIATE.
{
	my ($w, $x, $y, $keyModifier) = @_;
	my $l = $w->Subwidget('slistbox')->Subwidget($w->{'-listboxtype'});

	$keyModifier ||= ''  unless (defined $keyModifier);
	$keyModifier .= '-'  if ($keyModifier =~ /\S/o);
	if ((($x < 0) || ($x > $l->Width)) || (($y < 0) || ($y > $l->Height)))
	{
		# MOUSE WAS CLICKED OUTSIDE THE LISTBOX... CLOSE THE LISTBOX
		$w->LbClose;
	}
	else
	{
		#NEXT 5 ADDED @v5 FROM Tk::BrowseEntry DUE TO STUFF NOT ALWAYS BEING SELECTED W/MOUSE:
		my $inx = $l->nearest($y);
		if (defined $inx) {
			$l->selectionClear(0, "end");
			$l->selectionSet($inx);
		}
		# SELECT APPROPRIATE ENTRY AND CLOSE THE LISTBOX
		my $popornotFlag = $w->{'-fixedlist'} ? -1 : 0;
		$w->LbCopySelection($popornotFlag,"listbox.${keyModifier}button1");
	}
}

sub LbClose  # CLOSE THE LISTBOX AFTER CLEARING SELECTION.
{
	my $w = shift;
	my $l = $w->Subwidget('slistbox')->Subwidget($w->{'-listboxtype'});
	$l->selection('clear', 0, 'end');
	$w->Popdown;
}

# COPY THE LISTBOX-SELECTION TO THE ENTRY FIELD, AND CLOSE (ROLL UP) LISTBOX (UNLESS JUSTCOPY SET).

sub LbCopySelection
{
	my ($w, $justcopy, $action, $forceSelect) = @_;
	my $index = $w->LbIndex($forceSelect);
	my $e = $w->Subwidget('entry');

	if (defined $index)
	{
no strict 'refs';
		my $var_ref = $w->cget( '-textvariable' );
		$$var_ref = $w->getText($index);
		$e->icursor('end');
		$e->selectionRange(0,'end')  unless ($w->{'-noselecttext'} || !$e->index('end'));
	}
	if ($justcopy <= 0)  #1 MEANS JUST COPY, NO SEARCH & CALLBACK -1 MEANS LEAVE DD-LIST UP & FOCUSED (USER CLICKED ON IT!):
	{
		$w->{'searchindx'} = 0;
		$w->Popdown  unless ($justcopy < 0);  # ROLL UP THE LISTBOX, SINCE IT'S VISIBLE:
		my $altbinding = $w->{'-altbinding'};
		if ($altbinding =~ /NoListbox\=([^\;]+)/io) {
			my @noActions = split(/\,/o, $1);
			my $res;
			foreach my $i (@noActions) {
				$i = 'listbox.' . $i  unless ($i =~ /listbox\./io);
				eval "\$res = (\$action =~ /^$i/i);";
				return  if ($res);
			}
		}
		my $gettext = $e->get;
		$w->Callback(-browsecmd => $w, $gettext, $action)  if (defined $index);
	}
}

# GRAB TEXT TYPED IN AND FIND NEAREST ENTRY IN LISTBOX AND SELECT IT.
# LETTERSEARCH SET MEANS SEARCH FOR *NEXT* MATCH OF SPECIFIED LETTER,
# CLEARED MEANS SEARCH FOR *1ST* ITEM STARTING WITH CURRENT TEXT ENTRY VALUE.
# THE TRICK HERE IS THAT WHEN USER CLEARS AND THEN TYPES LETTERS INTO THE 
# TEXT BOX OR A LETTER INTO THE DROP-DOWN LIST, WE "REMEMBER" WHERE WE 
# WERE IN THE LIST SO THAT IF THEY RIGHTARROW-COMPLETE IT COMPLETES 
# THE TEXT FIELD WITH THAT ENTRY, THEN, IF THEY DO IT AGAIN, WE START 
# WITH THE NEXT INDEX SO THAT, IF THERE ARE MORE THAN ONE MATCHING 
# VALUES, THEY'LL ADVANCE TO THE *NEXT* MATCH RATHER THAN GETTING 
# IT COMPLETED WITH THE SAME ONE AGAIN!:  (searchindx)

sub LbFindSelection
{
	my ($w, $srchval) = @_;

	my $lettersearch = 0;
	if (defined($srchval) && $srchval =~ /\S/o)
	{
		$lettersearch = 1;
	}
	else
	{
		$srchval = $w->get();
		unless ($srchval =~ /\S/o)
		{
			$w->Subwidget('slistbox')->Subwidget($w->{'-listboxtype'})->activate(0);

			return 0;
		}
	}
	my $l = $w->Subwidget('slistbox')->Subwidget($w->{'-listboxtype'});
	my @listsels = $w->getText('0','end');

	return 0  if ($#listsels < 0);

	unless ($lettersearch)   #DON'T BOTHER W/EXACT MATCHING IF JUST SEARCHING FOR (FIRST FEW) LETTERS:
	{
		foreach my $i (0..$#listsels)   #SEARCH FOR TRUE EQUALITY.
		{
			if ($listsels[$i] eq $srchval)
			{
				$l->selectionClear('0','end');
				$l->activate($i);
				$l->selectionSet($i);
				$l->update();
				$l->see($i);

				return 1;    #EXACT MATCH
			}
		}
	}

	my $index = $w->{'searchindx'} || 0;
		
	foreach my $i (0..$#listsels)   #SEARCH W/O REGARD TO CASE, START W/CURRENT SELECTION.
	{
		#if ($listsels[$index] =~ /^$srchval/i)
		#CHGD. TO NEXT 20030531 PER PATCH BY FRANK HERRMANN.
#		if (defined $srchval && $listsels[$index] =~ /^$srchval/i) #CHGD TO NEXT 20060429 TO PREVENT TK-ERROR ON "("!
		if ($listsels[$index] =~ /^\Q$srchval\E/i)
		{
			$l->selectionClear('0','end');
			$l->activate($index);
			$l->selectionSet($index);
			$l->update();
			$l->see($index);
			if ($lettersearch) {
				++$w->{'searchindx'};
				$w->{'searchindx'} = 0  if ($w->{'searchindx'} > $#listsels);
			}
			return ($listsels[$index] =~ /^\Q$srchval\E$/i) ? 1 : -1;  #(1=EXACT MATCH, CASE INSENSITIVE, -1=MATCH CONTAINS SEARCH STRING.
		}
		++$index;
		$index = 0  if ($index > $#listsels);    #ROLL BACK AROUND IF AT BOTTOM.
		$w->{'searchindx'} = $index;
	}
	$l->selectionClear('0','end');
	$l->activate(0);
	$l->see(0);
	$w->{'searchindx'} = 0;
	return 0;  #NO MATCH!
}

sub LbIndex   #FETCH THE INDEX OF THE SELECTED OR ACTIVE ENTRY FROM THE DD-LIST:
{
	my ($w, $flag) = @_;

	my $slistbox = $w->Subwidget('slistbox');
	#CHANGED NEXT 5 TO FOLLOWING 2 (20180707) TO *NOT* TREAT ACTIVE ELEMENT AS SELECTED IF IT ISN'T.
	#SPACEBAR WILL SELECT IT, HITTING [Enter] WILL LEAVE ENTRY TEXT UNCHANGED SINCE NOTHING SELECTED - 
	#I DECIDED THIS WAS PREFERRED, IN PARTICULAR IF ONE PRESSED A CHARACTER, HIT [Enter] AND NOTHING 
	#MATCHES, DO NOT JUST SELECT THE CURRENTLY-ACTIVE ENTRY (THAT DOESN'T MATCH)!
#	my $sel = $w->Subwidget('slistbox')->Subwidget('listbox')->curselection 
#		|| $w->Subwidget('slistbox')->Subwidget('listbox')->index('active');
#	$sel = $w->Subwidget('slistbox')->Subwidget('listbox')->index('active')
#			unless ($sel =~ /^\d+$/o);   #JWT:  ADDED 20040819 'CAUSE CURSELECTION SEEMS TO RETURN "ARRAY(XXXX)" NOW?!?!?!
#	return (defined $sel) ? int($sel) : 0;
	(my $sel) = $slistbox->Subwidget($w->{'-listboxtype'})->curselection;
	#REPLACE REMAINING LINES WITH COMMENTED CODE IF DESIRE IS TO SELECT ACTIVE IS NOTHING SELECTED (AS BEFORE).
	#IF NO SELECTION THEN:  IF NO FLAG:  undef, FLAG=0: zero(1st element), 1: active (underlined) element.
	#FLAG=2|3 && DD-LIST IS DISABLED(state==text): SAME AS 0|1 RESPECTIVELY, BUT SEARCH CHOICES FOR AN INDEX.
	#THIS IS NEEDED FOR THE TABCOMPLETE, RIGHTCOMPLETE, UP/DOWN FUNCTIONS TO STILL FIND THE NEAREST CHOICE!
	if (defined $sel)   #SOMETHING'S ACTUALLY SELECTED:
	{
		return int($sel);
	}
	elsif (defined($flag) && $flag)   #NOTHING SELECTED, DO WE WANT THE ACTIVE ENTRY INSTEAD?
	{
		if ($flag == 1)   #WILL RETURN FIRST ENTRY(0) IF NOTHING'S ACTIVE:
		{
			return $slistbox->Subwidget($w->{'-listboxtype'})->index('active') || 0;
		}
		elsif ($flag > 1)  #WE MUST FIND THE INDEX OF THE CHOICE EVEN THOUGH THE DD-LIST IS DISABLED:
		{
			if ($slistbox->cget('-state') eq 'disabled')
			{
				my @listsels = $w->getText('0','end');
				my $index = $w->{'searchindx'} || 0;
				my $textval = $w->get();
				if ($textval =~ /\S/o)
				{
					for (my $i=0; $i<=$#listsels;$i++)
					{
						return $index  if ($listsels[$index] =~ /^\Q$textval\E/i);
						++$index;
						$index = 0  if ($index > $#listsels);    #ROLL BACK AROUND IF AT BOTTOM.
						$w->{'searchindx'} = $index;
					}
				}
			}
			return ($flag == 3) ? 0 : undef;
		}
	}
	return undef;
}

sub Popdown   # POP DOWN (ROLL UP/HIDE) THE DD-LIST BOX!
{
	my ($w, $flag) = @_;
	my ($state) = $w->cget( '-state' );

	if ($w->{'popped'})  #LISTBOX IS SHOWING:
	{
		if ($w->{'-fixedlist'}) {   #DON'T LET FIXED DD-LIST TAKE FOCUS WHEN NOT "POPPED" (FOCUSED) W/O CALLING PopupChoices() FIRST (SO TABBING WILL WORK RIGHT)!:
			$w->Subwidget('slistbox')->Subwidget($w->{'-listboxtype'})->configure('-takefocus' => 0);
		}
		else   #ROLL UP ("UN-POP") THE DD-LIST:
		{
			$w->Subwidget('choices')->withdraw;
		}
		$w->grabRelease;
		$w->{'popped'} = 0;
		$w->Subwidget('entry')->selectionRange(0,'end')  
				unless ($w->{'-noselecttext'} || !$w->Subwidget('entry')->index('end'));
	}

	if ($w->{'savefocus'} && Tk::Exists($w->{'savefocus'}))  #USED BY PressButton FUNCTION TO RESTORE FOCUS TO WIDGET THAT HAD IT WHEN DEVELOPER CALLED IT:
	{
		$w->{'savefocus'}->focus;
		delete $w->{'savefocus'};
	}
	else
	{
		$w->focus  unless ($flag);  #WILL PUT FOCUS BACK ONTO ENTRY|FRAME|BUTTON! (flag SAYS LEAVE FOCUS WHERE IT IS!)
	}
}

sub _adustLBsize   #ADJUST THE DD-LIST WIDTH / HEIGHT, IF WE NEED TO:
{
	my $w = shift;
	my @l = $w->getText(0, 'end');
	$w->{'-width'} = $w->{'-maxwidth'}  if ($w->{'-maxwidth'} > 0 && $w->{'-width'} > $w->{'-maxwidth'});
	my $width = $w->{'-width'};
	unless ($width)
	{
		$width = 0;
		for (my $i=0;$i<=$#l;$i++)
		{
			$width = length($l[$i])  if ($width < length($l[$i]));
		}
		$width = $w->{'-maxwidth'}  if (defined($w->{'-maxwidth'}) 
				&& $width > $w->{'-maxwidth'} && $w->{'-maxwidth'} > 0);
	}
	if ($w->{'-fixedlist'} || $width != $w->{'-width'})  #ADJUST WIDTH IF CHANGED & ALLOWED TO CHANGE:
	{
		++$width;
		$w->Subwidget('entry')->configure(-width => $width);
		$w->Subwidget('slistbox')->configure(-width => $width);
	}
}

sub getText  #GET THE ACTUAL TEXT OF ENTRIES (EVEN IF THEY'RE HList HASHES!) (WRAPS *Listbox->get & ALLOWS FOR NO ARGS TO == 0..'end'(ALL)):
{
	my ($w, @indices) = @_;

	@indices = (0, 'end')  unless (defined $indices[0]);
	return $w->Subwidget('slistbox')->Subwidget($w->{'-listboxtype'})->get(@indices)  unless ($w->{'-listboxtype'} =~ /h/o);
	
	if (defined $indices[1])  #TWO INDEX ARGS GIVEN, RETURN LIST OF ITEMS BETWEEN firstArg & secondArg INCLUSIVE:
	{
		my @items = $w->Subwidget('slistbox')->Subwidget($w->{'-listboxtype'})->get(@indices);
		for (my $i=0;$i<=$#items;$i++)
		{
			$items[$i] = $items[$i]->{'-text'}  if (ref($items[$i]) && defined($items[$i]->{'-text'}));
		}
		return @items;   #RETURNS ARRAY.
	}
	else  #SINGLE INDEX ARG. GIVEN:
	{
		my $item = $w->Subwidget('slistbox')->Subwidget($w->{'-listboxtype'})->get($indices[0]);
		if (ref $item)
		{
			return (defined $item->{'-text'}) ? $item->{'-text'} : '';
		}
		return $item;   #RETURNS SCALAR (THE SINGLE ITEM MATCHING THE INDEX:
	}
}

sub choices   #(RE)SET THE CHOICES IN THE DD-LIST:
{
	my $w = shift;
	unless( @_ )   #NO ARGS, RETURN CURRENT CHOICES.
	{
		return ($w->getText( qw/0 end/ ));
	}
	else           #POPULATE DROP-DOWN LIST WITH THESE CHOICES.
	{
		my $choices = shift;
		if ($choices)
		{
			$w->delete( qw/0 end/ );
			$w->{'hashref'} = {}  if (defined $w->{'hashref'});   #ADDED 20050125.
			$w->{'hashref_bydesc'} = {}  if (defined $w->{'hashref_bydesc'});   #ADDED 20110226.
			$w->insert($choices);
			#NOOOOOOOOO! (INITIAL VARIABLE MAY NOT BE IN CHOICES)!:  $w->activate(0);
		}

		#NO WIDTH SPECIFIED, CALCULATE TEXT & LIST WIDTH BASED ON LONGEST CHOICE.

		$w->_adustLBsize();
		$w->state($w->state());
#		return ('');
		return undef;
	}
}

# INSERT NEW ITEMS INTO DROP-DOWN LIST.

sub insert   #ADD CHOICES TO THE DD-LIST:
{
	my $w = shift;
	my $pos = ($_[1]) ? shift : 'end';
	my $item = shift;            #POINTER TO OR LIST OF ITEMS TO INSERT.
	my $res;
	my $slistbox = $w->Subwidget('slistbox');

	#FORCE LISTBOX TO BE TEMP. ENABLED, IF DISABLED IN ORDER TO INSERT STUFF (WHICH IS ALLOWED, TO KEEP SYNC W/CHOICES):
	local *listboxInsert = sub {
		my $state = $slistbox->cget('-state');
		$slistbox->configure(-state => 'normal')  if ($state eq 'disabled');
		my $res = $slistbox->insert(@_);
		$slistbox->configure(-state => $state)  if ($state eq 'disabled');
		return $res;
	};

	if (ref($item))
	{
		if (ref($item) eq 'HASH')
		{
			my @choiceKeys = ();
			@choiceKeys = sort { $item->{$a} cmp $item->{$b} } keys(%$item);
			my @choiceVals = sort values(%$item);
			$res = &listboxInsert($pos, @choiceVals);
			my $choiceHashRef = (defined $w->{'hashref'}) ? $w->{'hashref'}
					: {};    #ADDED 20050125.
			my $choiceReverseHashRef = (defined $w->{'hashref_bydesc'}) ? $w->{'hashref_bydesc'}
					: {};    #ADDED 20110226.
			for (my $i=0;$i<=$#choiceKeys;$i++)   #ADDED 20050125.
			{
				$choiceHashRef->{$choiceKeys[$i]} = $choiceVals[$i];
				$choiceReverseHashRef->{$choiceVals[$i]} = $choiceKeys[$i];
			}
			$w->{'hashref_bydesc'} = $choiceReverseHashRef;
			$w->{'hashref'} = $choiceHashRef;
		}
		else
		{
			$res = &listboxInsert($pos, @$item);
		}
	}
	else
	{
		$res = &listboxInsert($pos, $item, @_);
	}

	#NO WIDTH SPECIFIED, (RE)CALCULATE TEXT & LIST WIDTH BASED ON LONGEST CHOICE.

	$w->_adustLBsize();
	$w->state($w->state());  #MAKE SURE THE BUTTON'S STATE GETS PROPERLY RESET IF LIST WAS EMPTY.
	return $res;
}

sub delete   #DELETE SELECTED ENTRY(S) FROM THE DD-LIST BY INDICES:
{
	my $w = shift;
	if (defined $w->{'hashref'})   #ADDED 20050125.
	{
		my ($key, $val);
		foreach my $i (@_)
		{
			$val = $w->get($i);
			$key = $w->{'hashref_bydesc'}->{$val};
			next  unless ($val);
			delete $w->{'hashref_bydesc'}->{$val}  if (defined $w->{'hashref_bydesc'}->{$val});
			delete $w->{'hashref'}->{$key}  if (defined $w->{'hashref'}->{$key});
		}
	}
	my $res = $w->Subwidget('slistbox')->delete(@_);
#CHGD. TO NEXT 2 @v5.0: 	unless ($w->Subwidget('slistbox')->size > 0 || $w->{'mylistcmd'})
#	{
#		my $button = $w->Subwidget( 'arrow' );
#		$button->configure( -state => 'disabled', -takefocus => 0);
#	}
	$w->_adustLBsize();
	$w->state($w->state())  #MAKE SURE THE BUTTON'S STATE GETS DISABLED, IF NEEDED & EMPTY LIST.
			unless ($w->Subwidget('slistbox')->size > 0);
	return $res;
}

sub delete_byvalue  #DELETE SELECTED ENTRY(S) FROM THE DD-LIST BY TEXT VALUES:
{
	my $w = shift;
	return undef  unless (@_);

	my @keys = $w->get(0, 'end');
	my $v;
	my $delThisValue;
	my $delCnt = 0;
	while (@_)
	{
		$delThisValue = shift;
		if (defined $w->{'hashref'})   #ADDED 20050125.
		{
			for (my $k=0;$k<=$#keys;$k++)
			{
				if ($keys[$k] eq $delThisValue)
				{
					$v = $w->{'hashref_bydesc'}->{$keys[$k]};
					delete $w->{'hashref_bydesc'}->{$keys[$k]}  if (defined $w->{'hashref_bydesc'}->{$keys[$k]});
					delete $w->{'hashref'}->{$v}  if (defined $w->{'hashref'}->{$v});
					$w->Subwidget('slistbox')->delete($k);
					$delCnt++;
					last;
				}
			}
		}
	}
	$w->state($w->state())  #MAKE SURE THE BUTTON'S STATE GETS TURNED OFF IF THE DD-LIST IS NOW EMPTY.
			unless ($w->Subwidget('slistbox')->size > 0);
	return $delCnt;
}

sub curselection  #RETURN CURRENT LISTBOX SELECTION.
{
	return shift->Subwidget('slistbox')->curselection;
}

sub _set_edit_state  #CHANGE APPEARANCES BASED ON CHANGES IN "-STATE" OPTION:
{
	my( $w, $state ) = @_;
	$state ||= 'normal';      #JWT: HAD TO ADD THIS IN TK804...
	my $entry  = $w->Subwidget('entry');
	my $frame  = $w->Subwidget('frame');
	my $label  = $w->Subwidget('label');
	my $button = $w->Subwidget('arrow');
	my $slistbox = $w->Subwidget('slistbox');
	my $txtfg = ($w->cget('-colorstate') == 1) ? 'black' : $w->{'-textforeground'} || $frame->cget('-foreground');
	my $txtbg = ($w->cget('-colorstate') == 1) ? 'gray95' : $w->{'-textbackground'} || $frame->cget('-background');
	my $texthlcolor = $frame->cget('-background');
	my $framehlcolor = $frame->cget('-foreground');
	my $framehlbg = $texthlcolor;
	if( $state eq 'readonly')
	{
		$framehlcolor = $frame->cget('-foreground') || $entry->cget( '-foreground' );
		if ($w->cget('-colorstate') == 1)
		{
			$txtbg = 'lightgray';
		}
		elsif ($w->cget('-colorstate') =~ /^(?:2|dark|readonlydark)$/io
				|| !defined $Tk::Widget::TwilightThreshold)  #DEFINED IF USING OUR MODIFIED "setPalette.pl"!
		{
			$txtfg = ($txtbg eq $entry->cget('-readonlybackground')) ? 'gray30' : 'black';
		}
		elsif ($bummer)  #WINDOWS SETPALETTE DOESN'T "SHADE" THE READONLY TEXT FIELD BG, SO WE NEED TO MAKE FG LOOK DIFFERENT FROM NORMAL STATE!:
		{
			$txtfg = ($txtfg =~ /black/io) ? 'gray30' : 'lightgray';
		}
		$txtfg = $w->{'-textreadonlyforeground'}  if ($w->{'-textreadonlyforeground'});
		$txtbg = $w->{'-textreadonlybackground'}  if ($w->{'-textreadonlybackground'});
		my %entryHash = (-state => $state, -takefocus => 0, 
				-foreground => $txtfg, -background => $txtbg,
				-highlightcolor => $texthlcolor,
				-highlightbackground => $texthlcolor);
		#PROGRAMMER NOTE:  ONCE THIS PARAMETER IS "SET", SWITCHING PALETTES WILL *NOT* UPDATE IT!:
		$entryHash{'-readonlybackground'} = $w->{'-textreadonlybackground'} || 'lightgray'  if ($w->cget('-colorstate') == 1);
		$entry->configure(%entryHash);

		$button->configure(-state => 'normal', -takefocus => $w->{'btntakesfocus'}, -relief => 'raised',
				-highlightcolor => $framehlcolor, -highlightbackground => $framehlbg);
		$frame->configure(-relief => ($w->{'-relief'} || 'raised'), 
				-takefocus => (1 & $w->{'takefocus'}), -highlightcolor => $framehlcolor,
				-highlightbackground => $framehlbg);
		$slistbox->configure(-state => 'normal')		if ($w->{'-fixedlist'});
	}
	elsif ($state =~ /text/o)
	{
		$button->configure( -state => 'disabled', -takefocus => 0, -relief => 'flat',
				-highlightbackground => $framehlbg);
		$frame->configure(-relief => ($w->{'-relief'} || 'sunken'), 
				-takefocus => 0, -highlightcolor => $framehlcolor,
				-highlightcolor => $texthlcolor, -highlightbackground => $framehlbg);
		$entry->configure( -state => 'normal', 
				-takefocus => (1 & ($w->{'takefocus'} || $w->{'btntakesfocus'})), 
				-foreground => $txtfg, -background => $txtbg, -highlightcolor => $texthlcolor,
				-highlightbackground => $texthlcolor);
		if ($w->{'-fixedlist'})
		{
			$w->Popdown(1)  if ($w->{"popped"});   #UNFOCUS BEFORE DISABLING!
			$w->update;
			$slistbox->configure(-state => 'disabled',  -takefocus => 0);
		}
	}
	elsif ($state eq 'disabled')
	{
		$frame->configure(-relief => ($w->{'-relief'} || 'groove'), 
				-takefocus => 0, -highlightcolor => $framehlcolor,
				-highlightbackground => $framehlbg);

		$txtfg = $w->{'-textdisabledforeground'}  if ($w->{'-textdisabledforeground'});
		$txtbg = $w->{'-textdisabledbackground'}  if ($w->{'-textdisabledbackground'});
		my %entryHash = (-state => $state, -takefocus => 0, 
				-foreground => $txtfg, -background => $txtbg,
				-highlightcolor => $texthlcolor,
				-highlightbackground => $texthlcolor);
		$entryHash{'-disabledbackground'} = ''  if ($w->cget('-colorstate') =~ /^(?:2|dark|disableddark)$/io);
		$entry->configure(%entryHash);

		$button->configure(-state => $state,  -takefocus => 0, -relief => 'flat',
				-highlightcolor => $framehlcolor, -highlightbackground => $framehlbg);
		if ($w->{'-fixedlist'})
		{
			$w->Popdown(1)  if ($w->{"popped"});   #UNFOCUS BEFORE DISABLING!
			$w->update;
			$slistbox->configure(-state => $state,  -takefocus => 0);
		}
	}
	else   #NORMAL.
	{
		$entry->configure( -state => $state, -takefocus => 0, 
				-foreground => $txtfg, -background => $txtbg,
				-highlightcolor => $texthlcolor,
				-highlightbackground => $texthlcolor);
		$button->configure(-state => $state, -relief => 'raised', 
				-takefocus => $w->{'btntakesfocus'},
				-highlightcolor => $framehlcolor, -highlightbackground => $framehlbg);
		$frame->configure(-relief => ($w->{'-relief'} || 'sunken'), 
				-takefocus => (1 & $w->{'takefocus'}), 
				-highlightcolor => $framehlcolor,
				-highlightbackground => $framehlbg);
		$slistbox->configure(-state => $state)		if ($w->{'-fixedlist'});
	}

	$label->configure( -background => $w->{'-labelbackground'})  if ($w->{'-labelbackground'});
	$label->configure( -foreground => $w->{'-labelforeground'})  if ($w->{'-labelforeground'});
	$button->configure( -state => 'disabled', -takefocus => 0)  #DISABLE BUTTON IF EMPTY LIST.
			unless ($w->Subwidget('slistbox')->size > 0);
}

sub state   #DYNAMICALLY CHANGE THE -state OF THE WIDGET:
{
	my $w = shift;

	if (@_)
	{
		my $state = shift;
		$w->{'Configure'}{'-state'} = $state;
		$w->_set_edit_state($state);
	}
	else
	{
		return $w->{'Configure'}{'-state'};
	}
}

sub colorstate   #DYNAMICALLY CHANGE THE -state OF THE WIDGET:
{
	my $w = shift;

	if (@_)
	{
		my $state = $w->cget('-state') || 'normal';
		$w->{'Configure'}{'-colorstate'} = shift;
		$w->_set_edit_state($state);
	}
	else
	{
		return $w->{'Configure'}{'-colorstate'};
	}
}

sub dereference   #USER-CALLABLE FUNCTION, ADDED 20050125.
{
	my $w = shift;
	return undef  unless (defined $_[0]);
	my $userValue = shift;
	return (defined($w->{'hashref_bydesc'}) && defined($w->{'hashref_bydesc'}->{$userValue}))
			? $w->{'hashref_bydesc'}->{$userValue} : $userValue;
}

sub dereferenceOnly   #USER-CALLABLE FUNCTION, ADDED 20050125.
{
	my $w = shift;
	return undef  unless (defined $_[0]);
	my $userValue = shift;
	return (defined($w->{'hashref_bydesc'}) && defined($w->{'hashref_bydesc'}->{$userValue}))
			? $w->{'hashref_bydesc'}->{$userValue} : undef;
}

sub reference   #USER-CALLABLE FUNCTION, ADDED 20110227, v. 4.8:
{
	my $w = shift;
	return undef  unless (defined $_[0]);
	my $userValue = shift;
	return (defined($w->{'hashref'}) && defined($w->{'hashref'}->{$userValue}))
			? $w->{'hashref'}->{$userValue} : $userValue;
}

sub hasreference   #USER-CALLABLE FUNCTION, ADDED 20050125.
{
	my $w = shift;
	return undef  unless (defined $_[0]);
	my $userValue = shift;
	return (defined($w->{'hashref_bydesc'}) && defined($w->{'hashref_bydesc'}->{$userValue}))
			? 1 : 0;
}

sub get_hashref_byname   #USER-CALLABLE FUNCTION, ADDED 20110227, v. 4.8:
{
	my $w = shift;
	return (defined $w->{'hashref_bydesc'}) ? $w->{'hashref_bydesc'} : undef;
}

sub fetchhash   #DEPRECIATED, RENAMED get_hashref_byname():
{
	my $w = shift;
	return $w->get_hashref_byname;
}

sub get_hashref_byvalue   #USER-CALLABLE FUNCTION, ADDED 20110227, v. 4.8:
{
	my $w = shift;
	return (defined $w->{'hashref'}) ? $w->{'hashref'} : undef;
}

sub get    #USER-CALLABLE FUNCTION, ADDED 20090210 v4.72 (returns DISPLAYED VALUE for choice hashes)!
{
	my $w = shift;
	if ( @_ )   #RETURN TEXT VALUES FOR GIVEN INDEX(ES).
	{
		return $w->getText( @_ );
	}
	else        #NO ARGS, RETURN CURRENT TEXT FIELD VALUE:
	{
no strict 'refs';
		my $var_ref = $w->cget( '-textvariable' );
		return $$var_ref;
	}
}

sub get_index    #USER-CALLABLE FUNCTION, ADDED 20110227, v. 4.8:
{
	my $w = shift;
	return undef  unless (@_);
	my $val = shift;
	my @keys = $w->get(0, 'end');
	for (my $k=0;$k<=$#keys;$k++)
	{
		return $k  if ($keys[$k] eq $val);
	}
	return undef;
}

sub activate    #USER-CALLABLE FUNCTION, ADDED 20090210 v4.72
{
	my $w = shift;
	my $indx = shift;
	my $res = $w->Subwidget('slistbox')->Subwidget($w->{'-listboxtype'})->activate($indx);
no strict 'refs';
	my $var_ref = $w->cget( '-textvariable' );
	$$var_ref = $w->getText($indx);
	return $res;
}

sub index
{
	my $w = shift;
	return $w->Subwidget('slistbox')->Subwidget($w->{'-listboxtype'})->index(@_);
}

sub size
{
	my $w = shift;
	return $w->Subwidget('slistbox')->Subwidget($w->{'-listboxtype'})->size(@_);
}

sub get_icursor
{
	my $w = shift;
	return $w->Subwidget('entry')->index(@_)  if (@_);
	return $w->Subwidget('entry')->index('insert');
}

1

__END__
