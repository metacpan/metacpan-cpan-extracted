#######################################################################
## LICENSE:
## This source code, is copyright (c) 2001-2006 of Rob Seegel
## <RobSeegel@comcast.net>, and is free software; you can
## redistribute and/or modify it under the same terms as Perl itself.
##
## ACKNOWLEDGEMENTS:
## Very little comes from nothing, and as the name suggests,
## JComboBox.pm is *superficially* similar to the javax.swing.JComboBox
## class which is owned by Sun Microsystems. At best, this module shares
## some method names, and basic look and feel, but the similarities end 
## there. None of this code comes from the Swing class. 
##
## JComboBox.pm owes its original structure to Graham Barr's MenuEntry
## (Thanks, Graham - it was a fine base). It also uses various methods
## and options borrowed from BrowseEntry, Optionmenu, and the
## ComboEntry widget (part of Tk-DKW). This was done to make the widget
## seem familiar to users of those widgets, and lessen the pain of
## migration, and because I thought they were *good* features that I 
## wanted in one widget. In addition, features that others have asked
## for have been added over time. So this widget represents a combo box
## stew with a few extra spices that I've come up with myself. 
##
## Finally, thanks to all those who have contributed bug reports,
## patches, and new ideas over the years. I have attempted to track 
## who did what within the Changes file, and in some cases within the
## source when patches were submitted. Your help and feedback has been
## appreciated.
#######################################################################
package Tk::JComboBox;

use strict;
use Carp;

use Tie::Watch;
use Tk;
use Tk::CWidget;
use Tk::CWidget::Util::Boolean qw(:all);

use vars qw($VERSION);
our $VERSION = "1.14";

BEGIN
{
   ## Setup a series of private accessors used within public/private
   ## methods. These are all intended for INTERNAL use only. The
   ## methods act as a way of consolidating the internal hash keys
   ## that are being used. Using method calls instead of hash keys
   ## helps ensure consistant usage throughout, and easier on my eyes.

   sub CreateGetSet
   {
      my ($method, $key) = @_;
      my $sub = sub {
         my ($cw, $value) = @_;
         return $cw->{$key} unless defined $value;
         $cw->{$key} = $value;
      };
      no strict 'refs';
      *{$method} = $sub;
   }
   CreateGetSet(IsButtonDown  => '__JCB__BTN_DOWN');
   CreateGetSet(LastAFIndex   => '__JCB__LAST_INDEX');
   CreateGetSet(LastAFSearch  => '__JCB__LAST_SEARCH');
   CreateGetSet(LastSelection => '__JCB__LAST_SELECT');
   CreateGetSet(LastSelName   => '__JCB__LAST_SNAME');
   CreateGetSet(List          => '__JCB__LIST');
   CreateGetSet(Mode          => '__JCB__MODE');
   CreateGetSet(LongestEntry  => '__JCB__ENTRY_LEN');
   CreateGetSet(Selected      => '__JCB__SELECTION');
   CreateGetSet(TempRelief    => '__JCB__RELIEF');
   CreateGetSet(WatchVar      => '__JCB__WATCH_VAR');
   CreateGetSet(WatchList     => '__JCB__WATCH');
}

use base qw(Tk::CWidget);
Tk::Widget->Construct('JComboBox');

## this struct below meant to represent the contents displayed in the
## pulldown list. Name is the text which is displayed, value is for
## text which could be offered as an alternative to the displayed
## text. It is slightly overkill having a structure to hold these
## values, but it is intended to hold additional values in the
## future (bitmaps, images, formats, etc).

use Class::Struct;
struct '_JCBListItem' =>
[
   name  => '$',
   value => '$',
];

## The following constants are meant for internal use only. I wanted
## to use hash keys that were not likely to be used by anyone else
## (including classes that I extended), but the longer versions
## seemed clumsy within the code. It is also a convenient means in
## tracking all of the keys that I'm using.

use constant {
   MODE_UNEDITABLE    => "readonly",
   MODE_EDITABLE      => "editable",
   VAL_MODE_CSMATCH   => "cs-match",
   VAL_MODE_MATCH     => "match",
};

my $BITMAP;
my $SWAP_BG = "__JCB__SWAP_BG";
my $SWAP_FG = "__JCB__SWAP_FG";

sub ClassInit {
   my($class,$mw) = @_;

   unless(defined($BITMAP)) {
      $BITMAP = __PACKAGE__ . "::downarrow";

      ## A smaller bitmap suits Win32 better I think
      if ($Tk::platform =~ /Win32/) {
         my $bits = pack("b10"x4,
            ".11111111.",
            "..111111..",
            "...1111...",
            "....11...."
         );
         $mw->DefineBitmap($BITMAP => 10,4, $bits);

      ## Just as this size looks better on other platforms
      } else {
         my $bits = pack("b12"x5,
            ".1111111111.",
            "..11111111..",
            "...111111...",
            "....1111....",
            ".....11....."
         );
         $mw->DefineBitmap($BITMAP => 12,5, $bits);
      }
      $mw->bind($class, '<ButtonRelease-1>', 'NonSelect');
      $mw->bind($class, '<FocusIn>', 'RedirectFocus');
   }
}

sub Populate {
   my ($cw ,$args) = @_;

   my $choices = delete $args->{-choices} || delete $args->{-options};
   $cw->SUPER::Populate($args);

   ## Initiallize Member variables
   $cw->LastAFIndex(-1);
   $cw->LastAFSearch("");
   $cw->LastSelection(-1);
   $cw->LastSelName("");
   $cw->List([]);
   $cw->LongestEntry(0);
   $cw->Selected(-1);

   my $frame = $cw->Component(
     Frame => 'Frame',
     -background => 'white',
     -bd => 2,
     -highlightthickness => 0
   )->pack(qw/ -side right -fill both -expand 1/);

   ## Mode is set once at construction time, things get overly 
   ## complicated if mode can be switched after construction time, 
   ## and how often is this sort of thing done? Mode determines the 
   ## widget that makes up the Entry, a Button. I used to allow the 
   ## mode to be switched on-the-fly, and may again in the future.

   my $mode = delete $args->{'-mode'} || MODE_UNEDITABLE;
   $cw->mode(lc($mode), $args);

   ## Layout ComboBox controls 
   $cw->LayoutControls();
   $cw->CreateListboxPopup();
   $cw->BindSubwidgets();

   ## Get All Advertised Widgets - constructed within Subroutines
   ## So that they can be used for ConfigSpecs routine
   my $entry   = $cw->Subwidget('Entry');
   my $button  = $cw->Subwidget('Button');
   my $listbox = $cw->Subwidget('Listbox');
   my $popup   = $cw->Subwidget('Popup');

   ## This ConfigSpecs functions as a core set for the entire 
   ## widget, and assumes that the mode is MODE_UNEDITABLE. Some 
   ## specs are overridden if the mode is MODE_EDITABLE.
   $cw->ConfigSpecs(
      ## Basic
      -arrowbitmap         => [{-bitmap => $button}, undef, undef, $BITMAP],
      -arrowimage          => [{-image => $button}],
      -background          => [qw/DESCENDANTS background  Background/],
      -borderwidth         => [qw/Frame borderwidth BorderWidth 2/],
      -cursor              => [qw/DESCENDANTS cursor Cursor/],
      -disabledbackground  => [qw/METHOD/, undef, undef, Tk::NORMAL_BG],
      -disabledforeground  => [qw/METHOD/, undef, undef, Tk::DISABLED],
      -entrybackground     => [{-background => [$entry, $button, $listbox]}],
      -entrywidth          => [qw/METHOD entryWidth EntryWidth -1/],
      -font                => [[$entry, $listbox], qw/font Font/],
      -foreground          => [[$entry, $listbox], qw/foreground Foreground/],
      -gap                 => [qw/METHOD gap Gap 0/],
      -highlightbackground => [qw/METHOD/, undef, undef, 
                                 $frame->cget('-highlightbackground')],
      -highlightcolor      => [qw/METHOD/, undef, undef, 
                                 $frame->cget('-highlightcolor')],
      -highlightthickness  => [$frame, undef, undef, 0],
      -pady                => [qw/METHOD padY PadY/],
      -relief              => [qw/Frame relief Relief groove/],
      -selectbackground    => [$listbox],
      -selectforeground    => [$listbox],
      -selectborderwidth   => [$listbox],
      -state               => [qw/METHOD state State normal/],
      -takefocus           => [$entry, qw/takeFocus TakeFocus/, TRUE],
      -textvariable        => [qw/METHOD textVariable Variable/],

      ## Callbacks
      -buttoncommand       => [qw/CALLBACK/, undef, undef, \&see],
      -keycommand          => [qw/CALLBACK/],
      -matchcommand        => [qw/CALLBACK/],
      -popupcreate         => [qw/CALLBACK/],
      -popupmodify         => [qw/CALLBACK/],
      -selectcommand       => [qw/CALLBACK/],
      -validatecommand     => [qw/CALLBACK/],

      ## Functionality
      -autofind            => [qw/PASSIVE/],
      -choices             => [qw/METHOD/],
      -listhighlight       => [qw/PASSIVE lightHighlight ListHighlight/, TRUE],
      -listwidth           => [qw/PASSIVE listWidth ListWidth -1/],
      -maxrows             => [qw/METHOD maxRows MaxRows 10/],
      -mode                => [qw/METHOD mode Mode/],
      -updownselect        => [qw/PASSIVE updownSelect UpDownSelect/, TRUE],
      -validate            => [qw/METHOD validate Validate none/],
   );

   ## Override readonly option settings
   if ($cw->mode eq MODE_EDITABLE) {
      $cw->ConfigSpecs(
         -entrybackground    => [{-background => [$entry, $listbox]}],
         -relief             => [$frame, qw/relief Relief sunken/],
         -selectbackground   => [[$entry, $listbox]],
         -selectforeground   => [[$entry, $listbox]],
         -selectborderwidth  => [[$entry, $listbox]],
      );
   }

   $cw->ConfigAlias(
      -browsecmd   => '-selectcommand',
      -listcmd     => '-popupcreate',
      -options     => '-choices',
    );

   $cw->choices($choices) if $choices;

    return $cw;
}

############################################################
## Configuration Methods
############################################################
sub choices
{
   my ($cw, $newAR) = @_;
   return $cw->WatchList unless defined $newAR;
   return if $newAR eq "" && !defined $cw->WatchList;

   my $oldAR = $cw->WatchList;
   my $tie = Tk::JComboBox::Tie->tie($cw, $newAR, $oldAR);
   if (defined($tie)) { $cw->WatchList($newAR); }
   else               { $cw->WatchList("");  }
}

sub disabled
{
   my ($cw, $option, $color) = @_;
   return $cw->{Configure}{"-disabled$option"} unless defined $color;

   my $entry = $cw->Subwidget('Entry');
   if ($cw->mode eq MODE_EDITABLE && $Tk::VERSION >= 804) {
      $entry->configure("-disabled$option" => $color);
      return;
   }
   if ($cw->state eq 'disabled') {
      $entry->configure("-$option" => $color);
      $cw->Subwidget('Button')->configure("-$option" => $color)
         if $cw->mode eq MODE_UNEDITABLE;
   }
}

sub disabledbackground
{
   my ($cw, $color) = @_;
   return $cw->disabled("background", $color);
}

sub disabledforeground
{
   my ($cw, $color) = @_;
   return $cw->disabled("foreground", $color);
}

sub entrybackground
{
   my ($cw, $val) = @_;
   return $cw->{Configure}{'-entrybackground'} unless defined $val;
   $cw->configureSubwidgets([qw/Entry Listbox/] => {-bg => $val});
}

sub entrywidth
{
   my ($cw, $width) = @_;
   return $cw->{Configure}{'-entrywidth'} unless defined $width;
   $cw->gap(0) if !defined($cw->gap);
   $cw->UpdateWidth('delete', "");
}

sub gap
{
   my ($cw, $gap) = @_;
   if (!defined($gap)) {
      return $cw->{Configure}{'-gap'} if defined $cw->{Configure}{'-gap'};
      return 0;
   }
   $cw->UpdateWidth('add', "");
}

sub highlightbackground
{
   my ($cw, $color) = @_;
   return $cw->{Configure}{'-highlightbackground'} unless defined $color;
   $cw->Subwidget('Frame')->configure(-highlightbackground => $color);
}

sub highlightcolor
{
   my ($cw, $color) = @_;
   return $cw->{Configure}{'-highlightcolor'} unless defined $color;
   $cw->Subwidget('Frame')->configure(-highlightcolor => $color);
}

sub maxrows
{
   my ($cw, $rows) = @_;
   return $cw->{Configure}{'-maxrows'} unless defined $rows;
   $cw->UpdateListboxHeight;
}

sub mode
{
   ## Stores the mode within another variable. One problem with how the 
   ## configuration methods currently work is that they current "store"
   ## the new value before the method is even called. If a method was 
   ## intended to validate prior to changing the value then this complicates
   ## things, because the original value is no longer available. In this
   ## case, the variable is only allowed to be set once per instance.

   my ($cw, $mode, $args) = @_;
   return $cw->Mode unless defined $mode;
   return if $cw->Mode;

   my $frame = $cw->Subwidget('Frame');
   my $entry;
   if ($mode eq MODE_EDITABLE) {
      $entry = $frame->Entry(
         -highlightthickness => 0,
         -borderwidth => 1,
         -insertwidth => 1,
         -relief => 'flat',
         -validatecommand => [$cw => 'ValidateCommand']
      );
      $cw->Advertise(Entry => $entry);
      $cw->Advertise(ED_Entry => $entry);
   }
   elsif ($mode eq MODE_UNEDITABLE) {
      $entry = $cw->CreateButton(
         -ignoreleave => TRUE,
         -anchor => 'w',
         -padx => 4,
         -borderwidth => 0,
         -takefocus => 1
      );
      $cw->Advertise(Entry => $entry);
      $cw->Advertise(RO_Entry => $entry);
   }
   else {
      croak "Invalid JComboBox mode: $mode\n";
      return;
   }
   $cw->Mode($mode);
}

sub pady
{
   my ($cw, $pad) = @_;
   return $cw->{Configure}{'-pady'} unless defined $pad;
   my $button = $cw->Subwidget('Button');
   my %gridInfo = $button->gridInfo;
   $gridInfo{'-ipady'} = $pad;
   $button->gridForget;
   $button->grid(%gridInfo);
}

sub state
{
   my ($cw, $state) = @_;
   return $cw->{Configure}{'-state'} || "normal" unless defined $state;

   $state = lc($state);
   croak "Invalid value for -state: $state!" 
      if ($state !~ /normal|disabled/);

   my $button = $cw->Subwidget('Button');
   my $entry = $cw->Subwidget('Entry');

   if    ($state eq 'disabled') { $cw->DisableControls; }
   elsif ($state eq 'normal')   { $cw->EnableControls;  }
}

sub textvariable
{
   my ($cw, $value) = @_;
   my $existing = $cw->{Configure}{'-textvariable'};
   return $existing unless defined $value;

   croak "Invalid textvariable type! Expected scalar reference" 
      if defined($value) && ref($value) ne "SCALAR";

   $cw->WatchVar->Unwatch if defined($cw->WatchVar);
   my $tmpVal = $$value;

   untie $value if tied $value;

   my $watch = Tie::Watch->new(
      -variable => $value,
      -store    => sub {$cw->TextvarStore(@_);},
      -fetch    => sub {return $cw->TextvarFetch(@_);}
   );
   $cw->WatchVar($watch);
   $cw->TextvarStore($watch, $tmpVal) if defined($tmpVal);
}

#############################################################################
## For the most part, this option is delegated to the Entry subwidget in 
## MODE_EDITABLE, however two additional options: match and cs-match will
## indicate that the entry should use the Listbox entries for validation. If 
## either of these two options are set, then a default validatecommand will
## be used.
#############################################################################
sub validate
{
   my ($cw, $mode) = @_;

   return $cw->{Configure}{'-validate'} unless $mode;
   return if $cw->mode eq MODE_UNEDITABLE;

   $mode = lc($mode);
   croak "Invalid validate value: $mode" 
      if ($mode !~ /^(none|focus|focusin|focusout|key|match|cs-match)$/);

   ## validate is only used in editble mode as a way of constraining
   ## what a user can type in the Entry. If the mode is match or cs-match
   ## a default -validate callback is provided. Otherwise, the validation
   ## mode is passed directly to the Entry widget's validate option.

   my $entry = $cw->Subwidget('Entry');
   if ($mode =~ /match/)
   {
      $entry->configure(
         -validate => 'key',
      );
   }
   else {
      $entry->configure(-validate => $mode);
   }
}

## ======================================================================== ##
## Public Methods                                                           ##
## ======================================================================== ##

sub addItem { shift->insertItemAt('end', @_) };

sub clearSelection
{
   my $cw = shift;
   $cw->LastAFIndex(-1);
   $cw->LastAFSearch("");
   $cw->Selected(-1);

   $cw->Subwidget('Listbox')->selectionClear(0, 'end');
   my $entry = $cw->Subwidget('Entry');
   if ($cw->mode eq MODE_EDITABLE) {
      my $v = $entry->cget('-validate');
      $entry->configure(-validate => 'none');
      $entry->delete(0, 'end');
      $entry->configure(-validate => $v);
   }
   elsif ($cw->mode eq MODE_UNEDITABLE) {
      $entry->configure(-text => "");
   }
}

## Override the following focus methods to ensure the
## correct
sub focus { shift->Subwidget('Entry')->focus; }
sub tabFocus { shift->Subwidget('Entry')->focus; }

sub getItemCount
{
   return scalar( @{shift->List} ); 
}

sub getItemIndex
{
   my ($cw, $searchStr, %args) = @_;

   ## start - which index to start looking. Defaults to 0;
   ## if the start is out of range, then reset it to 0.
   my $start = delete $args{'-start'} || 0;
   $start = 0 if $start >= $cw->Subwidget('Listbox')->size || $start < 0;

   ## wrap - only use when start is not 0, it determines 
   ## whether or not the search should continue at the beginning
   ## of the list until the start point when at the end of the list
   my $wrap = delete $args{'-wrap'} || 0;

   ## type - which string is being searched - the name, or value.
   my $type = lc($args{'-type'}) || "name";
   if ($type !~ /^(name|value)$/) {
      carp "Invalid value for -type in getItemIndex (valid: name|value)";
      return;
   }

   my $index;
   foreach my $i ($start .. ($cw->getItemCount - 1)) {
      my $field;
      if    ($type eq 'name')  { $field = $cw->List->[$i]->name   }
      elsif ($type eq 'value') { $field = $cw->getItemValueAt($i) }

      if ($cw->MatchCommand($searchStr, $field, %args)) {
         $index = $i; last;
      }
   }

   $index = $cw->getItemIndex($searchStr, %args)
      if (!defined($index) && IsTrue($wrap));

   return $index;
}

sub getItemNameAt
{
   my ($cw, $index) = @_;
   $index = $cw->index($index);
   return $cw->DisplayedName() if (!defined($index) || $index < 0);
   return $cw->List->[$index]->name;
}

sub getItemValueAt
{
   my ($cw, $index) = @_;
   $index = $cw->index($index);

   ## If index is out of array bounds or indicated non-selection
   ## then the value will come from the displayed name.
   return $cw->DisplayedName() if (!defined($index) || $index < 0);

   my $item = $cw->List->[$index];
   return $item->value if defined($item->value) && $item->value ne "";
   return $item->name;
 }

sub getSelectedIndex { return shift->Selected; }

sub getSelectedValue { return shift->getItemValueAt('selected'); }

sub hidePopup
{
   my ($cw) = @_;
   my $popup = $cw->Subwidget('Popup');
   return unless $popup->ismapped;

   $popup->withdraw;
   $cw->grabRelease;

   ## PATCH (submitted by Ken Prows for CPAN bug#12372)
   ## PATCH Modified to fix CPAN bug#14520
   if ($Tk::oldGrab && Exists($Tk::oldGrab) && $Tk::oldGrab->ismapped)
   {
      if ($Tk::oldGrabStatus) {
         $Tk::oldGrab->grab       if $Tk::oldGrabStatus eq 'local';
         $Tk::oldGrab->grabGlobal if $Tk::oldGrabStatus eq 'global';
      }
   }
   ## END PATCH
}

sub index
{
   my ($cw, $index) = @_;
   return undef unless defined($index);

   return 0                       if (lc($index) eq 'first');
   return $cw->getSelectedIndex   if (lc($index) eq 'selected');
   return $cw->getItemCount - 1   if (lc($index) eq 'last');
   return $cw->getItemCount       if (lc($index) eq 'end');

   my $listbox = $cw->Subwidget('Listbox');
   return $listbox->index($index) if ($index =~ /\D/);
   return $index;
}

sub insertItemAt
{
   my ($cw, $i, $name, %args) = @_;

   if (!defined($name)) {
      carp "Insert failed: undefined element";
      return;
   }
   my $index = $cw->index($i);
   my $lb = $cw->Subwidget('Listbox');

   ## Create new ListItem and set name
   my $item = _JCBListItem->new;
   $item->name($name);

   ## Set the value if it's given
   my $value = $args{'-value'};
   $item->value($value) if defined($value);

   ## Add ListItem to Internal Array and Listbox(append or splice)
   my $listAR = $cw->List;
   if ($lb->index('end') == $index) {
      push @{$listAR}, $item;
   } else {
      splice(@$listAR, $index, 0, ($item, splice(@$listAR, $index))); 
   }

   $cw->List($listAR);
   $cw->ListboxInsert($index, $name);

   ## Set Entry as selected if option is set
   my $selIndex = $cw->Selected;
   my $sel = $args{'-selected'};
   if ($sel && $sel =~ /yes|true|1/i) {
      $cw->setSelectedIndex($index);
   }
   elsif ($index <= $selIndex) 
   {
      $cw->setSelectedIndex($selIndex + 1);
   }
   $cw->UpdateWidth('add', $name);
}

sub popupIsVisible { return shift->Subwidget('Popup')->ismapped; }

sub removeAllItems
{
   my $cw = shift;
   return unless $cw->getItemCount > 0;

   $cw->clearSelection;
   $cw->List([]);
   $cw->ListboxClear;
   $cw->LongestEntry(0);
}

sub removeItemAt
{
   my ($cw, $index) = @_;
   my $count = $cw->getItemCount;
   if ($count == 0) {
      carp "There are no list elements to remove";
      return;
   }

   my $delIndex = $cw->index($index);
   $delIndex-- if (defined($index) && $index eq "end");
   return unless defined $delIndex;

   if ($delIndex < 0 || $delIndex >= $count) {
      carp "Index: $index is out of array bounds!";
      return;
   }

   my $selIndex = $cw->getSelectedIndex;
   $cw->clearSelection;

   ## Delete from List and Listbox
   my $listAR = $cw->List;
   splice(@$listAR, $delIndex, 1);
   $cw->List($listAR);
   $cw->ListboxDelete($delIndex);

   if ($selIndex != $delIndex) {
      $selIndex-- if $delIndex < $selIndex;
      $cw->setSelectedIndex($selIndex);
   }
   $cw->UpdateWidth('delete');
}

sub see
{
   my ($cw, $index) = @_;
   $index = $cw->index($index);
   $cw->showPopup;
   $cw->Subwidget('Listbox')->see($index) if defined($index);
}

sub setSelected
{
   my ($cw, $str, %args) = @_; 
   my $index = $cw->getItemIndex($str, %args);
   $cw->setSelectedIndex($index) if defined($index);
   return 1 if defined($index);
   return 0;
}

sub setSelectedIndex
{
   my ($cw, $index) = @_;
   $index = $cw->index($index) unless $index == -1;
   return unless defined($index);

   $cw->LastSelection($cw->Selected);
   $cw->Selected($index);

   ## Adjust Listbox selection
   my $listbox = $cw->Subwidget('Listbox');
   $listbox->selectionClear(0, 'end');

   if ($index >= 0) {

      $listbox->selectionSet($index);
      my $display = $cw->getItemNameAt($index);
      $cw->DisplayedName($display);
   }
   $cw->SelectCommand();
}

sub showPopup
{
   my $cw = shift;

   $cw->Callback(-popupcreate => $cw)
      if (ref($cw->cget('-popupcreate')) eq 'Tk::Callback');

   ## Set up Popup height/width and positioning, based on various 
   ## configured options.
   $cw->PopupCreate;

   ## Provide a hook for developers to override details taken
   ## care of within PopupCreate. -popupcreate should be 
   ## encouraged over -popupmodify.
   $cw->Callback(-popupmodify => $cw)
      if (ref($cw->cget('-popupmodify')) eq 'Tk::Callback');

   return if ($cw->popupIsVisible || $cw->getItemCount == 0);

   my $popup = $cw->Subwidget('Popup');
   $popup->deiconify;
   $popup->raise;
   $cw->Subwidget('Entry')->focus;

   ## PATCH (submitted by Ken Prows for CPAN BUG#12372)
   if ($cw->grabCurrent)
   {
      $Tk::oldGrab = $cw->grabCurrent;
      $Tk::oldGrabStatus = $Tk::oldGrab->grabStatus;      
   }
   ## END PATCH

   $cw->grabGlobal;
}

## ===================================================================== ##
## Private Methods - avoid calling these directly - they may change      ##
## ===================================================================== ##

sub AddList
{
   my ($cw, $listAR, $where) = @_;

   $where = "end" unless defined $where;
   croak "2nd Parameter may only be 'start' or 'end'\n"
      unless $where =~ /end|start|\d+/;
   $where = 0 if $where eq "start";

   foreach my $el (@{$listAR}) {
      if (ref($el) eq 'HASH') {
         my $name = $el->{'-name'} ||
            croak "Invalid Menu Item. -name must be given when " . 
              "using a Hash reference";

         my $index = $cw->insertItemAt($where, $name, %$el);
      }
      else {
         $cw->insertItemAt($where, $el);
      }
      $where++ if $where ne "end";
   }
}

sub AutoFind
{
   my ($cw, $letter, $key) = @_;

   ## Determine if autofind is enabled/disabled return 
   ## immediately if disabled. No need to continue if AutoFind 
   ## is disabled

   my $params      = $cw->cget('-autofind') || {};
   my $enabledOpt  = GetProperty('-enable' ,       $params, TRUE);
   my $casesensOpt = GetProperty('-casesensitive', $params, FALSE);
   my $popupOpt    = GetProperty('-showpopup',     $params, TRUE);
   my $completeOpt = GetProperty('-complete',      $params, FALSE);
   my $selectOpt   = GetProperty('-select',        $params, FALSE);
   return unless IsTrue($enabledOpt);

   ## select takes priority over complete
   $completeOpt = "false"
      if (IsTrue($completeOpt) && IsTrue($selectOpt));

   my $mode = $cw->cget('-mode');
   my $entry = $cw->Subwidget('Entry');
   my $listbox = $cw->Subwidget('Listbox');

   my $searchStr = $letter;
   if ($mode eq MODE_EDITABLE) {
      $searchStr = substr($entry->get, 0, $entry->index('insert'));
   }

   if (! defined($searchStr) || length($searchStr) == 0) {
      if ($mode eq MODE_EDITABLE) {
	 $cw->clearSelection;
         $cw->hidePopup if $cw->popupIsVisible;
      }
      return;
   }

   ## -casesensitive option: if enabled then distinguishes 
   ## between a k and K key press or search string.

   my $csVal = "ignorecase"; 
   $csVal = "usecase" if IsTrue($casesensOpt);

   my $start = 0;
   $start = $cw->LastAFIndex + 1 
      if $searchStr eq $cw->LastAFSearch && defined $cw->LastAFIndex;

   my $index = $cw->getItemIndex($searchStr,
      -mode => $csVal,
      -start => $start,
      -wrap => 1);

   $index = -1 if (! defined($index));
   $cw->LastAFIndex($index);
   $cw->LastAFSearch($searchStr);

   ## For all Cases, clear the selection from the Listbox
   $listbox->selectionClear(0, 'end');

   ## There is no matching entry: Hide the popup if displayed, and
   ## Delete any autocompletion characters from the Edit Box, if
   ## -complete is enabled.

   if (!defined($index) || $index < 0) {
      $cw->hidePopup;
      if ($mode eq MODE_EDITABLE) {
         $cw->clearSelection;
         $cw->DisplayedName($searchStr);
         $entry->icursor(length($searchStr));
      }
      return;
   }

   ## -select option: if enabled set Box and Listbox selection, 
   ## otherwise only set Listbox selection. -select and -complete
   ## should never be enabled at the same time.
   if (IsTrue($selectOpt)) { 
      $cw->setSelectedIndex($index);
      $entry->icursor(length($searchStr)) if $mode eq MODE_EDITABLE;
   } else {
      $listbox->selectionSet($index);
   }

   ## -complete option: enables autocompletion for the entry
   ## autocompletion does nothing in MODE_UNEDITABLE, and is 
   ## ignored if the -select option is enabled.

   if (IsTrue($completeOpt) && $mode eq MODE_EDITABLE) {

      my $insertIndex = $entry->index('insert');
      $insertIndex-- if $key eq "BackSpace";
      my $endLetters = substr($cw->getItemNameAt($index), $insertIndex);
      my $validateMode = $entry->cget('-validate');
      $entry->configure(-validate => 'none');
      $entry->selectionClear();
      $entry->delete($insertIndex, 'end');
      $entry->insert('end', $endLetters);
      $entry->icursor($insertIndex);
      $entry->selectionRange($insertIndex, 'end');
      $entry->configure(-validate => $validateMode);
   }

   ## -showpopup option: Some ComboBox implementations do not
   ## show a popup when their version of AutoFind is called. This
   ## option allows that behavior to be configured.
   $cw->showPopup if IsTrue($popupOpt);

   ## BUG FIX (cpan#11707/Ken Prows) As of v1.03/03 Mar 05
   $listbox->see($index);
}

sub BindSubwidgets
{
   my $cw = shift;
   my $e = $cw->Subwidget('Entry');

   $e->bind('<Alt-Down>', [$cw => 'AltDown']);
   $e->bind('<Alt-Up>',   [$cw => 'hidePopup']);
   $e->bind('<Down>',     [$cw => 'UpDown', '1']);
   $e->bind('<Return>',   [$cw => 'Return']);
   $e->bind('<FocusIn>',  [$cw => 'Focus', 'In']);
   $e->bind('<FocusOut>', [$cw => 'Focus', 'Out']);
   $e->bind('<Escape>',   [$cw => 'hidePopup']);
   $e->bind('<KeyPress>', [$cw => 'KeyPress', Ev('A'), Ev('K')]);
   $e->bind('<Tab>',      [$cw => 'Tab']);
   $e->bind('<Up>',       [$cw => 'UpDown', '-1']);

   if ($cw->mode eq MODE_UNEDITABLE) {
      my $b = $cw->Subwidget('Button');
      $b->bind('<Leave>', [$cw => 'ButtonLeave', $b, [$e]]);
      $e->bind('<Leave>', [$cw => 'ButtonLeave', $e, [$b]]);
   }
}

##############################################################################
## Creates a "pseudo-Button" which is a Label with some
## simpleButton-like bindings. At last check, a Button has a slightly
## different appearance on Windows than on Unix, and a Label is more
## consistent on the two platforms. On the downside, users expecting a
## Button when extracting the Subwidget are going to be disappointed...
##############################################################################
sub CreateButton {
   my ($cw, %args) = @_;

   my $ignoreLeave = delete $args{'-ignoreleave'};
   my $frame = $cw->Subwidget('Frame');
   my $button = $frame->Label(%args);
   $button->bind('<ButtonPress-1>',   [$cw => 'ButtonDown']);
   $button->bind('<ButtonRelease-1>', [$cw => 'ButtonUp']);
   $button->bind('<Leave>',           [$cw => 'ButtonUp'])
      if (IsFalse($ignoreLeave));
   return $button;
}

#############################################################################
## Creates and advertises the widgets used for the ComboBox Popup window. The
## Popup consists of a Toplevel widget, advertised as 'Popup', that contains
## a Listbox Widget and Scrollbar. These widgets are gridded, except for the
## Scrollbar which will be gridded only when it needs to be.
#############################################################################
sub CreateListboxPopup {
   my $cw = shift;

   my $c = $cw->Component(
      Toplevel => 'Popup',
      -bd => 2,
      -relief => 'groove'
   );
   $c->overrideredirect(1);
   $c->withdraw;

   my $lb = $c->Listbox(
      -takefocus => 0,
      -selectmode => "browse",
      -exportselection => 0,
      -bd => 0,
      -width => 0,
      -highlightthickness => 0,
    )->grid(qw/-row 0 -column 0 -sticky nsew/);
   $cw->Advertise(Listbox => $lb);
   $cw->ListboxClear;

   $c->gridRowconfigure(0, -weight => 1);
   $c->gridColumnconfigure(0, -weight => 1);

   my $sb = $c->Scrollbar(
      -takefocus => 0,
      -command => [yview => $lb]);
   $lb->configure(-yscrollcommand => [set => $sb]); 
   $cw->Advertise(Scrollbar => $sb);

   $lb->bind('<Motion>', [$cw => 'ListboxMotion', Ev('@')]);
   $lb->bind('<Leave>',  [$cw => 'ListboxLeave', Ev('x'), Ev('y')]);
   $lb->bind('<Enter>',  [$cw => 'ListboxEnter']); 
   $lb->bind('<ButtonRelease-1>', 
              [$cw => 'ButtonRelease', Ev('index',Ev('@'))]);
}

#############################################################################
## Responsible for handling logic that implements state changes to and from
## a disabled state.
##
## NOTE: Code in this method was updated using a patch submitted by 
## Neal, 8 MAY 2006 that corrected a bug. When state was set to disabled 
## twice in a row, the foreground color would not be changed back.
#############################################################################
sub DisableControls
{
   my $cw = shift;
   my $button = $cw->Subwidget('Button');
   my $entry = $cw->Subwidget('Entry');

   my $bg = $cw->cget('-disabledbackground');
   my $fg = $cw->cget('-disabledforeground');
   if ($fg ne $button->cget('-foreground')) {
      $button->{$SWAP_FG} = $button->cget('-foreground');
      $button->configure(-foreground => $fg);
   }
   $cw->configure(-takefocus => 0);
   if ($cw->mode eq MODE_EDITABLE) {
      $entry->configure(-state => 'disabled');
      return if $Tk::VERSION >= 804;

      if ($bg ne $button->cget('-background')) {
         $entry->{$SWAP_BG} = $entry->cget('-background');
         $entry->configure(-background => $bg);
      }
   }
   if ($fg ne $button->cget('-foreground')) {
      $entry->{$SWAP_FG} = $entry->cget('-foreground');
      $entry->configure(-foreground => $fg);
   }
}

sub EnableControls
{
   my $cw = shift;
   my $button = $cw->Subwidget('Button');
   my $entry = $cw->Subwidget('Entry');

   my $fg = $button->{$SWAP_FG};
   return unless defined $fg;

   $button->{$SWAP_FG} = $button->cget('-foreground');
   $button->configure(-foreground => $fg);

   if ($cw->mode eq MODE_EDITABLE) {
      $entry->configure(-state => 'normal');
      return if $Tk::VERSION >= 804;

      my $bg = $entry->{SWAP_BG};
      $entry->{$SWAP_BG} = $entry->cget('-background');
      $entry->configure(-background => $bg);
   }
   $fg = $entry->{$SWAP_FG};
   $entry->{$SWAP_FG} = $entry->cget('-foreground');
   $entry->configure(-foreground => $fg);
   $cw->configure(-takefocus => 1);
}

#############################################################################
## Displays a value within the Entry Subwidget, and hides the differences 
## between the different modes.
#############################################################################
sub DisplayedName 
{
   my ($cw, $value) = @_;
   my $entry = $cw->Subwidget('Entry');

   ## "Get routine"
   if (!defined($value)) {
      if ($cw->mode eq MODE_EDITABLE) {
         my $val = $entry->get;
         my $index = $entry->index('insert');
         return substr($val, 0, $index);
      }
      elsif ($cw->mode eq MODE_UNEDITABLE) {
         return  $entry->cget('-text') || "";
      }
      return "";
   }

   ## Mode is readonly, so we're dealing with Label widget.
   if ($cw->mode eq MODE_UNEDITABLE) {
      $entry->configure(-text => $value);

   ## If the mode is editable, then we're dealing with an Entry
   ## Widget which may have validation routines bound to it so 
   ## there's a chance that the selected value will be rejected.
   ## The main idea of using a ComboBox is that the List should
   ## contain several values, any of which should already be valid.
   ## For this reason, validation is temporarily disabled then
   ## reenabled after Entry has been set.

   } elsif ($cw->mode eq MODE_EDITABLE) {
      my $validateMode = $cw->cget('-validate');
      $cw->configure(-validate => 'none');
      $entry->delete(0, 'end');
      $entry->insert(0, $value);
      $cw->configure(-validate => $validateMode);
   }
}

sub GetProperty {
   my ($name, $hashRef, $default, $delete) = @_;

   croak "Unable to extract property from undefined Hash Reference\n"
      if (!defined($hashRef));

   my $val = $hashRef->{$name};
   $val = $default if (!defined($val) && defined($default));
   delete $hashRef->{$name} if IsTrue($delete);
   return $val;
}

#############################################################################
## Arranges layout of the Advertised Entry and Button widgets. These subwidgets
## are laid out using the grid manager, which I find tends to scale downwards
## better.
#############################################################################
sub LayoutControls {
   my $cw = shift;

   my $frame = $cw->Subwidget('Frame');
   my $entry = $cw->Subwidget('Entry');

   ## Editable "Button" is really a Label widget with minimal bindings. There
   ## were Win32 display issues with the Button widget, so I created a VERY
   ## basic version using Label. Look at using ImageButton in a future release.
   my $button = $cw->CreateButton(
      -anchor => 'center',
      -bitmap => $BITMAP,
      -pady => 0,
   );
   $button->configure(-relief => 'raised') 
      if $cw->mode eq MODE_EDITABLE;

   $cw->Advertise(Button => $button);
   $cw->Advertise(ED_Button => $button) if $cw->mode eq MODE_EDITABLE;
   $cw->Advertise(RO_Button => $button) if $cw->mode eq MODE_UNEDITABLE;

   my %buttonInfo = (qw/-row 0 -column 2 -sticky nsew -ipadx 2/);
   $buttonInfo{"-ipady"} = 5 if $cw->mode eq MODE_UNEDITABLE;

   $frame->GeometryRequest($button->ReqWidth + 2,0);
   $entry->grid(qw/-row 0 -column 0 -sticky nsew/);
   $button->grid(%buttonInfo);

   $frame->gridRowconfigure(qw/0 -weight 1/);
   $frame->gridColumnconfigure(qw/0 -weight 1/);
}

sub ListboxClear 
{
   my $cw = shift;
   if ($Tk::version >= 8.4) {
      $cw->Subwidget('Listbox')->configure(-listvariable => []);
   } else {
      $cw->Subwidget('Listbox')->delete(0, 'end');
   }
}

sub ListboxDelete
{
   my ($cw, $index) = @_;
   if ($Tk::version >= 8.4) {
      my @data = $cw->Subwidget('Listbox')->get(0, 'end');
      splice(@data, $index, 1);
      $cw->Subwidget('Listbox')->configure(-listvariable => \@data);
   } else {
      $cw->Subwidget('Listbox')->delete($index);
   }
}
     
sub ListboxInsert
{
   my ($cw, $index, $value) = @_;

   ## There appear to be issues associated with using cget to retrieve
   ## the array ref from the listbox, and reusing that object. Creating
   ## a new array seems to work fine... odd.
   if ($Tk::version >= 8.4) {
      my @data = $cw->Subwidget('Listbox')->get(0, 'end');
      if ($cw->Subwidget('Listbox')->index('end') == $index) {
         push @data, $value;
      } else {
         splice(@data, $index, 0, ($value, splice(@data, $index)));
      }
      $cw->Subwidget('Listbox')->configure(-listvariable => \@data);
   } else {
      $cw->Subwidget('Listbox')->insert($index, $value);
   }
}

sub MatchCommand
{
   my ($cw, $searchStr, $field, %args) = @_;

   ## Check for and use matchcommand if it exists
   ## Otherwise use default routines
   my $retVal = $cw->Callback(-matchcommand => $searchStr, $field, %args)
      if (ref($cw->cget('-matchcommand')) eq 'Tk::Callback');
   return $retVal if defined $retVal;

   ## Extract mode (defaults to exact if not set
   my $mode = lc($args{'-mode'}) || "exact";
   if ($mode !~ /^((use|ignore)case|exact)$/) {
      $mode = "exact";
      carp "Invalid value $mode for -mode in getItemIndex - " .
         "value of 'exact' assumed";
   }
   return 1 if $mode eq 'exact'      && $field eq $searchStr;
   return 1 if $mode eq 'usecase'    && $field =~ /^\Q$searchStr\E/;
   return 1 if $mode eq 'ignorecase' && $field =~ /^\Q$searchStr\E/i;
   return 0;
}

#############################################################################
## Takes a list of one or more subwidgets and returns 1
## if the mouse pointer is pointed over any one of them.
## Returns 0 otherwise.
#############################################################################
sub PointerOverWidget {
   my ($cw, @widgets) = @_;
   my $xPos = $cw->pointerx;
   my $yPos = $cw->pointery;
   my $overWidget = $cw->containing($xPos, $yPos);

   foreach my $w (@widgets) {
      return TRUE if defined $overWidget && $w == $overWidget ;
   }
   return FALSE;
}

#############################################################################
## Notifies a registered SelectCommand that a new item has
## been selected. A selection can occur in a large number 
## of ways. The tricky bit is to ensure that it gets called
## when the selection changes, but does not get called 
## repeatedly for the same selection. Most of the complication
## has to do with the editable mode. 
#############################################################################
sub SelectCommand
{
   my $cw = shift;
   my $selIndex = $cw->getSelectedIndex;
   my $selName  = $cw->DisplayedName || "";

   ## First validate each index
   my $newIndex;
   $newIndex = $cw->getItemIndex($selName) unless $selName eq "";
   $newIndex = -1 unless defined($newIndex);
   if ($selIndex != $newIndex) {
      $cw->setSelectedIndex($newIndex);
      return;
   }

   ## Selected index has been validated - now, check to
   ## see if there was a difference between it and the
   ## last selection.
   my $notifyObserver = 0;
   $notifyObserver = 1 if 
     ($selIndex != $cw->LastSelection || $selName ne $cw->LastSelName);

   if ($notifyObserver) {
      my $selValue = $cw->getSelectedValue;
      $cw->LastSelName($selName);
      $cw->LastSelection($selIndex);
      $cw->Callback(-selectcommand => $cw, $selIndex, $selName, $selValue)
         if (ref($cw->cget('-selectcommand')) eq 'Tk::Callback');	
   }
}

#############################################################################
## Default Callback for -popupcreate option this method determines the correct
## size and placement of the Popup triggered by the ComboBox Button, and then
## displays it. Just prior to displaying the Popup, the Callback assigned to
## to -popupmodify will be called allowing additional popup configuration to
## be modified prior to being displayed. This would be used if someone wants 
## to make minor changes to Popup, but still use the ShowPopup implementation.
#############################################################################
sub PopupCreate {
   my $cw = shift;

   my $popup     = $cw->Subwidget("Popup");
   my $listbox   = $cw->Subwidget("Listbox");
   my $scrollbar = $cw->Subwidget("Scrollbar");
   my $entry     = $cw->Subwidget("Entry");

   $cw->UpdateListboxHeight;

   ## Scrolled turns propagate off, but I need it on
   $listbox->Tk::pack('propagate',1);

   my $maxX = $cw->vrootwidth;  ## Max X position
   my $maxY = $cw->vrootheight; ## Max Y position

   ## Determine X/Y position of Popup -- Initially, the Popup should be 
   ## displayed directly below the ComboBox, and aligned to the left side.
   ## This may change depending on placement of the ComboBox on the Screen.
   my $popupPosX   = $cw->rootx;
   my $popupPosY   = $cw->rooty + $cw->height;
   my $popupWidth  = $cw->width;  ## Defaults to width of the ComboBox
   my $popupHeight = $listbox->ReqHeight + $popup->cget('-borderwidth') * 2;

   ## Override width if -listwidth is defined
   my $listWidth = $cw->cget('-listwidth');
   if (defined $listWidth && $listWidth > -1) {
      $listbox->configure(-width => $listWidth);
      $popupWidth = $listbox->ReqWidth + $popup->cget('-borderwidth') * 2;
      $popupWidth = $popupWidth + $scrollbar->ReqWidth if $scrollbar->manager;
   }

   ## X/Y values must be at least 0, to display popup on screen. Typically, 
   ## this will only ever be a problem for the X value.
   $popupPosX = 0 if $popupPosX < 0;
   $popupPosY = 0 if $popupPosY < 0;

   ## X/Y values must not allow the popup to be displayed beyond the maximum 
   ## limits allowed for the screen. Again, this will might happen
   $popupPosX = $maxX - $popupWidth  if (($popupPosX + $popupWidth) > $maxX);
   $popupPosY = $maxY - $popupHeight if (($popupPosY + $popupHeight) > $maxY);

   ## Unfortunately, just moving the Popup will only do so much if the Popup 
   ## is larger than what the screen will support. So, to prevent this from
   ## occurring the following failsafe should prevent the popup from being
   ## displayed off screen. A mandatory maximum height is placed on the List.
   ## Currently, this does not override the maxrows option and will have to be
   ## calculated each time the popup is displayed. Hopefully, this condition
   ## will only be needed for exceptional cases.
   my $listboxHeight = $listbox->size;
   if ($popupHeight > $maxY) {
      while ($popupHeight > $maxY) {
         $listboxHeight--;
         $listbox->configure(-height => $listboxHeight);
         $listbox->update;
         $popupHeight = $listbox->ReqHeight + $popup->cget('-borderwidth') * 2;
      }
      $popupPosY = $maxY - $popupHeight;
   }
 
   ## Position and adjust the width/height of the Popup prior to display.
   $popup->geometry(sprintf("%dx%d+%d+%d",
      $popupWidth,
      $popupHeight,
      $popupPosX,
      $popupPosY));
}

sub UpdateListboxHeight
{
   my $cw = shift;
   my $listbox = $cw->Subwidget('Listbox');
   my $sb = $cw->Subwidget('Scrollbar');

   ## Ensure that the Listbox is no larger than the maxrow size
   ## and at least as large as 1. If maxrow size is set to 0 or
   ## lower then the Listbox will grow/shrink as large as it needs
   ## to display all items. The Listbox drives what the height of the
   ## popup will be.

   my $rows = $listbox->size;
   my $maxRows = $cw->cget('-maxrows');

   if ($maxRows >= 0 && $maxRows < $rows) {
      $rows = $maxRows;
      $sb->grid(qw/-row 0 -column 1 -sticky ns/) if ! $sb->manager;
   }
   else {
      $sb->gridForget if $sb->manager;
   }
   $listbox->configure(-height => $rows);
}

##############################################################################
## Updates the width of the widget dynamically based on the longest list 
## entry. This is similar to specifying 0 or less for the Listbox widget. If 
## -entrywidth is greater than 0
#############################################################################
sub UpdateWidth {
   my ($cw, $action, $name) = @_;
   my $entry = $cw->Subwidget('Entry');

   ## updates the width automatically if width has been set to -1, which
   ## is the default, and anything greater than the default will force the 
   ## width to be static, otherwise it will be as wide as the longest element
   ##  in the List. *Feature request: Bryan Williams (bitbucketz2002@yahoo.com)
   ## - 2003-06-18
   my $w = $cw->cget('-entrywidth');
   $w = -1 unless defined $w;  ## Assume -1
   if ($w >= 0) {
      my $gap = $cw->gap;
      $w = $w + $gap if $w > 0; 
      $entry->configure(-width => $w);
      return;
   }

   if ($action eq "add") {
      my $len = length($name);
      return if ($len <= $cw->LongestEntry);
      $cw->LongestEntry($len);
   }
   elsif ($action eq "delete") {
      my $currLen = 0;
      foreach my $item (@{$cw->List}) {
         $currLen = length($item->name) if $currLen < length($item->name);
      }
      $cw->LongestEntry($currLen) if $cw->LongestEntry > $currLen;
   }
   $cw->LongestEntry($cw->gap + $cw->LongestEntry);
   $entry->configure(-width => $cw->LongestEntry);
}

#############################################################################
## Callback registered to -validatecommand when the -validate options values
## is "match" or "cs-match".
#############################################################################
sub ValidateCommand 
{
   my ($cw, $str, $chars, $currval, $i, $action) = @_;
   my $mode = $cw->cget('-validate');

   if ($mode !~ /match/) {
      my $vc = $cw->cget('-validatecommand');
      return TRUE unless defined $vc;
      return $vc->Call($str, $chars, $currval, $i, $action) if defined($vc);
   }

   my $index;
   if ($mode eq VAL_MODE_MATCH) { 
      $index = $cw->getItemIndex($str, -mode => 'ignorecase');
   }
   elsif ($mode eq VAL_MODE_CSMATCH) {
      $index = $cw->getItemIndex($str, -mode => 'usecase');
   }
   return TRUE if (defined($index));
   return FALSE;
}

## ========================================================= ##
## JComboBox Event Handler Routines
## ========================================================= ##

sub AltDown 
{
   my $cw = shift;
   return unless $cw->state eq 'normal';
   if ($cw->popupIsVisible) { $cw->hidePopup; }
   else                     { $cw->showPopup; }
}

sub ButtonDown 
{
   my $cw = shift;
   return unless ($cw->state eq 'normal');
   my $mode = $cw->cget('-mode');

   my $button;
   $button = $cw->Subwidget('Frame') if $cw->mode eq MODE_UNEDITABLE;
   $button = $cw->Subwidget('Button') if $cw->mode eq MODE_EDITABLE;

   $cw->IsButtonDown(TRUE);
   $cw->TempRelief($button->cget('-relief'));
   $button->configure(-relief => 'sunken');

   ## Call buttoncommand if defined
   $cw->Callback(-buttoncommand => $cw, $cw->getSelectedIndex)
      if (ref($cw->cget('-buttoncommand')) eq 'Tk::Callback');
}

sub ButtonLeave 
{
   my ($cw, $trigger, $ignoreLeave) = @_;
   return unless $cw->state eq 'normal';
   return if (IsFalse($cw->IsButtonDown));

   if (defined($ignoreLeave) && ref($ignoreLeave) eq "ARRAY") {
  
     if (IsTrue($cw->PointerOverWidget($ignoreLeave))) {
        $trigger->bind('<Motion>', 
           [$cw => 'ButtonMotion', $trigger, [$trigger, @$ignoreLeave]]);
        return;
     }
   }
   $cw->ButtonUp;
}

sub ButtonMotion
{
   my ($cw, $trigger, $widgetAR) = @_;
   return unless $cw->state eq 'normal';

   ## If The Button is Up, then we no longer need this binding.
   if (IsFalse($cw->IsButtonDown)) {
      $trigger->bind('<Motion>', "");
      return;
   }
   if (IsFalse($cw->PointerOverWidget(@{$widgetAR}))) {
      $cw->ButtonUp;
   }
}

sub ButtonRelease 
{ 
   my ($cw, $index) = @_;
   return unless $cw->state eq 'normal';
   return unless $cw->popupIsVisible;
   $cw->hidePopup;
   $cw->setSelectedIndex($index) if defined($index);

}

sub ButtonUp {
   my $cw = shift;
   return unless $cw->state eq 'normal';

   ## Take care of returning the button relief
   my $button;
   my $mode = $cw->cget('-mode');
   if ($mode eq MODE_UNEDITABLE)  { $button = $cw->Subwidget('Frame'); } 
   elsif ($mode eq MODE_EDITABLE) { $button = $cw->Subwidget('Button'); }

   if ($cw->TempRelief) {
      $button->configure(-relief => $cw->TempRelief);
      $cw->TempRelief(0);
   }
   $cw->IsButtonDown(FALSE);
}

sub Focus
{
   my ($cw, $inOut) = @_;
   my $bg = $cw->highlightcolor;
   my $color = $cw->highlightbackground;
   $cw->highlightcolor($color);
   $cw->highlightbackground($bg);
   $cw->SelectCommand if (defined($inOut) && $inOut eq "Out");
}

sub KeyPress
{
   my ($cw, $uChar, $keySym) = @_;
   return unless $cw->state eq 'normal';
   my $kc = $cw->cget('-keycommand');
   $kc->Call($cw, $uChar, $keySym) if defined $kc;
   $cw->AutoFind($uChar, $keySym);   
}

sub ListboxEnter 
{
   my $cw = shift;
   return if IsFalse($cw->cget('-listhighlight'));
   $cw->Subwidget('Listbox')->CancelRepeat;
}

sub ListboxLeave 
{
   my ($cw, $x, $y) = @_;
   return if IsFalse($cw->cget('-listhighlight'));
   $cw->Subwidget('Listbox')->AutoScan($x, $y);
}

sub ListboxMotion 
{
   my ($cw, $xy) = @_;
   return if IsFalse($cw->cget('-listhighlight'));
   my $listbox = $cw->Subwidget('Listbox');
   my $index = $listbox->index($xy);
   $listbox->Motion($index);
}

## TO DO -- I don't think this method is doing the right thing
## it is called NonSelect yet it IS selecting.
sub NonSelect {
   my $cw = shift;
   return unless $cw->popupIsVisible;
   $cw->hidePopup;
   my $index = $cw->getSelectedIndex;
   $cw->setSelectedIndex($index) if defined($index);
}

sub RedirectFocus { shift->Subwidget('Entry')->focus; }

sub Return
{
   my $cw = shift;
   return unless $cw->state eq 'normal';
   my ($index) = $cw->Subwidget('Listbox')->curselection;
   $index = -1 unless defined($index);

   $cw->hidePopup if $cw->popupIsVisible;
   $cw->Subwidget('Entry')->selectionClear() if $cw->mode eq MODE_EDITABLE;
   $cw->setSelectedIndex($index) if defined($index);
}

sub Tab 
{
   my $cw = shift;
   $cw->Return;
   $cw->focusNext;
}

sub TextvarFetch
{
   return shift->getItemValueAt('selected');
}

sub TextvarStore 
{
   my ($cw, $watch, $value) = @_;

   if (!defined($value) || $value eq "") {
      $cw->clearSelection();
      return;
   }

   ## If the item value exists within the list, then selected it.
   my $index = $cw->getItemIndex($value, -type => 'value');
   if (defined($index) && $index != -1) {
      $cw->setSelectedIndex($index);
   }
   ## Otherwise, only set it, if the mode is editable (allows
   ## values that are not in the list.
   else {
      $cw->DisplayedName($value) if $cw->mode eq MODE_EDITABLE;
   }
}   

sub UpDown
{
   my ($cw, $mod) = @_;
   return unless $cw->state eq 'normal';
   return unless (defined($mod) && ($mod =~ /^(|-)?\d+$/));

   my $lastIndex = $cw->getItemCount() - 1;
   my $listbox = $cw->Subwidget('Listbox');
   my ($index) = $listbox->curselection;
   $index = -1 if !defined($index) || $index eq "";

   my $modIndex = $index + $mod;
   $modIndex = $lastIndex if $modIndex > $lastIndex;
   $modIndex = 0 if $modIndex < 0;
   return if $modIndex == $index;

   my $selectOpt = $cw->cget('-updownselect');
   if (IsTrue($selectOpt)) { 
      $cw->setSelectedIndex($modIndex);
   }
   else { 
      $listbox = $cw->Subwidget('Listbox');
      $listbox->selectionClear(0, 'end');
      $listbox->selectionSet($modIndex);
   }
}

###########################################################################
## The package below is highly experimental and subject to massive change
## and/or deprecation in future versions of JComboBox. Use at your own risk.
###########################################################################
package Tk::JComboBox::Tie;

use strict;
use Carp;
use Tie::Array;

use vars qw($VERSION);
our $VERSION = "0.01";

use base qw(Tie::Array);

sub addWatcher
{
   my ($self, $watcher) = @_;
   return unless ref($watcher) eq 'Tk::JComboBox';
   push @{$self->{LISTENERS}}, $watcher
      if $self->FindWatcher($watcher) < 0;
}

sub removeWatcher
{
   my ($self, $watcher) = @_;
   my $index = $self->FindWatcher($watcher);
   splice @{$self->{LISTENERS}}, $index, 1 unless $index < 0;
}

sub tie
{
   my ($pkg, $jcb, $newListAR, $oldListAR) = @_;

   ## 1st Determine if the oldListAR has been tied to. It
   ## will almost ALWAYS be tied to, except for the first
   ## time -choices have been configured to a JComboBox.
   my $listenerAR;

   my $oldTie = tied @$oldListAR 
      if (defined $oldListAR && ref($oldListAR) eq 'ARRAY');

   if (defined($oldTie)) {

      ## This widget was the master, copy all listeners
      ## before breaking the tie, so that we can maintain
      ## existing ties.
      if ($jcb == $oldTie->Master) {
         $oldTie->CLEAR;
         $listenerAR = $oldTie->{LISTENERS};
         shift @$listenerAR;

         $oldTie = undef;
         untie @$oldListAR;
      }

      ## This widget is not the master, the tie is not ours
      ## to break. Remove this widget as a listener -- it 
      ## will be a master of a it's own tie. Then clear all
      ## its items.

      else {
         $oldTie->removeWatcher($jcb);
      }
   }
   $jcb->removeAllItems if $jcb->getItemCount > 0;

   ## At this point, there should be no tie, or the JCombobox
   ## has been removed as a listener from an existing one. This
   ## is to clear the way to either create a new tie or add it
   ## as a listener to a different tie.
   my $newTie;

   if (ref($newListAR) eq 'ARRAY') {
      $newTie = tied @$newListAR;
      my @items = @$newListAR;

      ## Check to see if the new ListAR already is tied. If it is, and 
      ## and it is tied to a JComboBox, then we will register this 
      ## widget as a listener, and will not recreate the tie.
      if (defined($newTie) && ref($newTie) eq 'Tk::JComboBox::Tie') {
         $newTie->addWatcher($jcb);
         $jcb->AddList(\@items, "end");
      }

      ## The new list has not been tied to anything yet, so we're going
      ## to create a new Tie with the specified JComboBox as the master.
      ## If this widget was a previous master, then all of its listeners
      ## will be swapped to the new tie.
      else {
         $newTie = tie @$newListAR, 'Tk::JComboBox::Tie', $jcb;
         $jcb->AddList(\@items, "end");

         foreach my $l (@$listenerAR) {
            $l->configure(-choices => \@$newListAR);
         }
      }
   }
   return $newTie;
}

## ========================================================= ##
## PRIVATE METHODS                                           ##
## ========================================================= ##

sub CLEAR 
{
   my $self = shift;
   $self->Notify(-method => 'CLEAR_W') if $self->FETCHSIZE > 0;
}
sub CLEAR_W { $_[1]->removeAllItems } 

sub DELETE { shift->SPLICE(shift, 1) }

sub DESTROY 
{
   my $self = shift;
   foreach my $listener (@{$self->{LISTENERS}}) {
      $listener->configure(-choices => "")
         if ref($listener) eq 'Tk::JComboBox' && Tk::Exists($listener);
   }
}

sub FETCH
{
   my ($self, $index) = @_;
   return undef if $index + 1 > $self->FETCHSIZE;
   return $self->GetItemValues($self->Master, $index);
}

sub FETCHSIZE { shift->Master->getItemCount }

sub FindWatcher
{
   my ($self, $watcher) = @_;
   if (ref($watcher)) {
      foreach my $i (0 .. (scalar(@{$self->{LISTENERS}})-1)) {
         return $i if ($self->{LISTENERS}->[$i] == $watcher);
      }
   }
   return -1;
}

sub GetItemValues
{
   my ($self, $w, $index) = @_;
   $index = $w->index($index);
   my $count = $w->getItemCount;
   return if $index >= $w->getItemCount;

   my $item = $w->List->[$index];
   my $rv = $item->name;

   if ($item->value) {
      $rv = { -name => $item->name };
      $rv->{'-value'} = $item->value if defined($item->value);
   }
   return $rv;
}

sub Master { return shift->{LISTENERS}->[0] } 

sub Notify
{
   my ($self, %args) = @_;

   ## For some reason, the JComboBox sticks around in memory 
   ## after it's been destroyed. Remove any destroyed 
   ## widgets from the list of listeners prior to notification.
   my @good;
   foreach my $listener (@{$self->{LISTENERS}}) {
      if (Tk::Exists($listener)) {
         push @good, $listener;
      }
      else {
         undef $listener;
      }
   }
   $self->{LISTENERS} = \@good;

   my $method  = delete $args{-method};
   my $except  = delete $args{-except};
   my $paramAR = delete $args{-params};

   foreach my $listener (@{$self->{LISTENERS}}) 
   {
      next if (defined($except) && $listener == $except);
      $self->$method($listener, @$paramAR);
   }
}

sub POP  { shift->SPLICE("last", 1)    }
sub PUSH { shift->SPLICE("end", 0, @_) }

sub RemoveItemValues
{
   my ($self, $w, $index) = @_;
   $index = $w->index($index);
   my $rv = $self->GetItemValues($w, $index);
   $w->removeItemAt($index);
   return $rv;
}

sub RemoveList
{
   my ($self, $w, $start, $length) = @_;
   my @rv;
   return if $start + 1 > $w->getItemCount;
   $length = $w->getItemCount - $start if !defined($length); 
   $length = ($w->getItemCount + $length) - $start if $length < 0;
   if ($length > 0) {
      foreach (1 .. $length) {
         push @rv, $self->RemoveItemValues($w, $start++);
      }
   }
   return @rv;
}

sub SHIFT { shift->SPLICE("first", 1) }

sub SPLICE
{
   my $self = shift;
   my $master = $self->Master;
   return if !defined($master);

   $self->Notify(
      -method => 'SPLICE_W',
      -params => \@_,
      -except => $master
   );
   $self->SPLICE_W($master, @_);
}

sub SPLICE_W
{
   my ($self, $w, $offset, $length, @list) = @_;
   my $bounds = $w->getItemCount;
   $offset = 0 unless defined $offset;
   $offset = $w->index($offset);
   $offset = $bounds + $offset  if $offset < 0;
   return if $offset > $bounds;

   my @removed = $self->RemoveList($w, $offset, $length);
   $w->AddList(\@list, $offset) if @list;

   return undef unless @removed;
   return wantarray ? @removed : $removed[scalar(@removed)-1];
}

sub STORESIZE {}
sub STORE     { shift->SPLICE(shift, 1, shift) }

sub TIEARRAY
{
   my ($class, $jcb) = @_;

   croak "Widget parameter was not a Tk::JComboBox!"
      unless defined($jcb) && ref($jcb) eq 'Tk::JComboBox';

   my $state = {
      LISTENERS => [$jcb]
   }; 
   return bless $state, $class;
}

sub UNSHIFT { shift->SPLICE(0, 0, @_) }
1;

