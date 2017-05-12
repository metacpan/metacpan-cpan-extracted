package Tk::PopEntry;

use strict;
require Tk::Entry;

use vars qw(@ISA $VERSION);
@ISA = qw(Tk::Derived Tk::Entry);
$VERSION = 0.06;

Construct Tk::Widget 'PopEntry';

sub Populate{
   my($dw, $args) = @_;
   $dw->SUPER::Populate($args);
   
   my $menuitems = delete $args->{-menuitems};
   my $nomenu = delete $args->{-nomenu};
   
   # Create the toplevel here, for easier reference later
   my $menu = $dw->Toplevel(-bd=>2, -relief=>'raised');
   $menu->withdraw;
   $menu->overrideredirect(1);
   $menu->transient;
   
   # The default menu items
   if(!defined($menuitems)){
      $menuitems = [
         ["Cut",     'Tk::PopEntry::cutToClip',      '<Control-x>', 2],
         ["Copy",    'Tk::PopEntry::copyToClip',     '<Control-c>', 0],
         ["Paste",   'Tk::PopEntry::pasteFromClip',  '<Control-v>', 0],
         ["Delete",  'Tk::PopEntry::deleteSelected', '<Control-d>', 0],
         ["Sel. All",'Tk::PopEntry::selectAll',      '<Control-a>', 7],
      ];
   }

   $dw->Advertise('popupmenu' => $menu);
   
   #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   # The -menu options is for convenience, but is not generally 
   # meant to be called as a configure option once created.  Caveat Progammor.
   #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   $dw->ConfigSpecs(
      -pattern    => ['PASSIVE'],
      -case       => ['PASSIVE'],
      -maxwidth   => ['PASSIVE'],
      -maxvalue   => ['PASSIVE'],
      -minvalue   => ['PASSIVE'],
      -nomenu     => ['PASSIVE',undef,undef,$nomenu],
      -nospace    => ['PASSIVE',undef,undef,0],
      -menuitems  => ['PASSIVE',undef,undef,$menuitems],
      -menu       => ['PASSIVE',undef,undef,$menu],
      DEFAULT     => [$dw],
   );
    
   $dw->setBindings($menuitems);
}

# Set the default bindings
sub setBindings{
   my($dw, $menuitems) = @_;
      
   my($callback, $binding);
   my $popupmenu = $dw->Subwidget('popupmenu');

   $dw->bind("<Key>", sub{ $dw->validate } );

   $dw->bind("<Button-3>",
      sub{ $dw->displayMenu if(!$popupmenu->ismapped) },
   );

   $dw->bind("<Button-1>",
      sub{ $dw->withdrawMenu if($popupmenu->ismapped) },
   );

   #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   # Remove the bindings from the 'Control' and 'Alt' keys.  This is necessary
   # to prevent a minor annoyance trying to manually cut, etc, with the keys.
   #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   $dw->bind("<Control_L>", sub{ Tk::NoOp });
   $dw->bind("<Control_R>", sub{ Tk::NoOp });
   $dw->bind("<Alt_L>",     sub{ Tk::NoOp });
   $dw->bind("<Alt_R>",     sub{ Tk::NoOp });

   # Set the bindings for the default menu items
   foreach my $item(@$menuitems){
      $callback = $item->[1];
      $binding  = $item->[2];
      $dw->bind($binding, \&$callback);
   }

}

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Validate the Entry widget's value as the user types in data.  This is tied
# to the 'Key' event, set in the 'setBindings' method.
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
sub validate{
   my $dw = shift;

   my $pattern  = $dw->cget(-pattern);
   my $nospace  = $dw->cget(-nospace);
   my $maxwidth = $dw->cget(-maxwidth);
   my $case     = $dw->cget(-case);
   
   #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   # If the user specifies -maxvalue, take their word for it that they will
   # only enter numeric values.  Otherwise they'll be comparing ascii values,
   # which may or may not be what they wanted.  
   #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   my $maxValue = $dw->cget(-maxvalue);
   my $minValue = $dw->cget(-minvalue);
   
   #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   # Get the original string before the key was pressed.  This means getting
   # all but the last character.
   #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   my $length = $dw->index('end');   
   my $string = $dw->get;
   my $oldString = substr($string,0,$length-1);
   
   if($nospace){
      if($string =~ /^\s*$/){ 
         $dw->bell;
         return 0;
      }
   }
   
   # Change all characters to uppercase or lowercase if appropriate
   if($case && $case eq "upper"){ $string =~ tr/a-z/A-Z/ }
   if($case && $case eq "lower"){ $string =~ tr/A-Z/a-z/ }
   
   if($pattern){
      if($pattern =~ /^unsigned_int.*?$/i){
         if($nospace){ $pattern = '^\d*$' }
         else{ $pattern = '^(\s*\d*\s*)*$' }
      }  
      elsif($pattern =~ /^signed_int.*?$/i){
         if($nospace){ $pattern = '^[\+\-]?\d*$' }
         else{ $pattern = '^(\s*[\+\-]?\d*\s*)*$' }
      }
      elsif($pattern =~ /^float.*?$/i){
         if($nospace){ $pattern = '^-?\d*\.?\d*$' }
         else{ $pattern = '^\s*?-?\d*\.?\d*\s*$' }
      }
      elsif($pattern =~ /^alphanum.*?$/i){
         if($nospace){ $pattern = '^[A-Za-z0-9]*$' }
         else{ $pattern = '^(\s*?[A-Za-z0-9]*?\s*)*$' }
      }
      elsif($pattern =~ /^alpha.*?$/i){
         if($nospace){ $pattern = '^[A-Za-z]*$' }
         else{ $pattern = '^(\s*[A-Za-z]*\s*)*$' }
      }
      elsif($pattern =~ /^capsonly.*?$/i){
         if($nospace){ $pattern = '^[A-Z]*$' }
         else{ $pattern = '^(\s*[A-Z]*\s*)*$' }
      }
      elsif($pattern =~ /^nondigit.*?$/i){
         if($nospace){ $pattern = '^\D*$' }
         else{ $pattern = '^(\s*\D*\s*)*$' }
      }
      # Check for a user-defined pattern
      else{} # do nothing
   }
   
   #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   # If the string entered by the user doesn't match the pattern, replace 
   # it with the old string and ring the bell.  Otherwise, allow the new 
   # value.
   #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   if( defined($pattern) ){
      unless($string =~ /$pattern/){
         $dw->restore(-oldval=>$oldString);
         return;
      }
   }
   
   #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   # If the maximum or minimum value is not entered, replace it with the old
   # string and ring the bell.  Otherwise, allow the new value.  Note that
   # 'minvalue' is not perfect, as it could fail on the first number.
   #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   if(defined($maxValue) && ($string > $maxValue)){
      $dw->restore(-oldval=>$oldString);
      return;
   }
   if(defined($minValue) && ($string < $minValue)){
      $dw->restore(-oldval=>$oldString);
      return;
   }

   if(defined($maxwidth) && (length($string) > $maxwidth)){
      $dw->restore(-oldval=>$oldString);
      return;
   }
   
   # If the validation rule is obeyed, insert the new string.
   $dw->delete(0,'end');
   $dw->insert('end',$string);
   $dw->xview($dw->index('insert')); # Scroll to right as needed
}

# Restore the original string if a validation check fails.
sub restore{
   my($dw, %args) = @_;
   
   my $oldVal = delete $args{-oldval};
   
   $dw->bell;
   $dw->delete(0,'end');
   $dw->insert('end',$oldVal);
}

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Display the right-click menu.  The contents of that menu are derived from
# the -menuitems option.  There are five options by default, found in the
# 'Populate()' method above.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
sub displayMenu{
   my $dw = shift;

   my($button,$string,$callback,$index,$binding);
   
   if($dw->cget(-nomenu)){ return }
   
   my $menu = $dw->cget(-menu);
   my $menuitems = $dw->cget(-menuitems);

   my $popupmenu = $dw->Subwidget('popupmenu');
   $dw->withdrawMenu if($popupmenu->ismapped);
   
   # Create the menu item buttons
   foreach my $item(@$menuitems){
      $string   = $item->[0];
      $callback = $item->[1];
      $binding  = $item->[2];
      $index    = $item->[3];     

      # Turn "<Control-x>" into "<Ctrl-x>"
      if($binding =~ /^\<control\-(.)\>$/i){ $binding = "<Ctrl-$1>" }
      
      $dw->{"mb_$string"} = $menu->Button(
         -text       => "$string\t$binding",
         -underline  => $index,  
         -command    => [$callback, $dw],
      );
      
      # Disable the default menu items initially.
      if($string =~ /Cut|Copy|Paste|Delete|Sel.*?All/i){
         $dw->{"mb_$string"}->configure(-state=>'disabled');
      }
   }
   
   #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   # Perform some additional configuration options and pack the buttons onto
   # the screen.  Note that all buttons are disabled by default, and enabled
   # later in the 'setState()' method.
   #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   foreach my $item (@$menuitems){
      $button = $dw->{"mb_$item->[0]"};
      $button->configure(-relief=>'flat', -padx=>0, -pady=>0, -anchor=>'w');
      $button->pack(-expand=>1, -fill=>'x');
      $button->bind("<Enter>", sub{
         if($_[0]->cget('-state') ne "disabled"){
               $_[0]->configure(-relief=>'raised')
            }
         }
      );
      $button->bind('<Leave>', sub{$_[0]->configure(-relief=>'flat')});
   }
   
   # Check for state each time the menu appears
   $dw->setState;
   
   #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   # I like this bit of code.  This 'snaps' the pull down to the bottom left
   # corner of the Entry widget.
   #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   $menu->geometry(sprintf("+%d+%d", $dw->rootx, $dw->rooty+20));
   
   # A 'grabGlobal()' call is necessary here to retain selection in some cases.
   $dw->grabGlobal;
   
   # Finally, raise the menu
   $menu->deiconify;
   $menu->raise;

}

# Withdraw the menu and destroy any children to prevent "menu buildup".
sub withdrawMenu{
   my $dw = shift;

   my $menu = $dw->cget(-menu);
   if($menu->state eq 'normal'){
      $menu->withdraw;
   }
   
   my @children = $menu->children;
   foreach my $child(@children){ $child->destroy }
   
   $dw->grabRelease;
}

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Set the state of the various buttons based on certain criterion, detailed
# below.  Note that any non-default menu-items should automatically have 
# their state set to 'normal'.
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
sub setState{
   my $dw = shift; 
   my($dwVal, $selection, $clipboard);

   my $menuitems = $dw->cget(-menuitems);

   $dwVal  = $dw->get;
   $selection = getSelection($dw, 'PRIMARY');
   $clipboard = getSelection($dw, 'CLIPBOARD');

   foreach my $item(@$menuitems){
      if($item->[0] =~ /Cut|Copy|Paste|Delete|Sel. All/){
         eval{$dw->{"mb_$item->[0]"}->configure(-state=>'disabled')};
      }
   }

   #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   # Only set state to 'normal' for default items if clipboard is
   # not empty or selection is present.
   #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   if(($clipboard) && ($dw->{mb_Paste})){
      eval{$dw->{mb_Paste}->configure(-state=>'normal')};
   }
   if(($selection) && ($dw->{mb_Cut})){
      eval{$dw->{mb_Cut}->configure(-state=>'normal')};
   }
   if(($selection) && ($dw->{mb_Copy})){
      eval{$dw->{mb_Copy}->configure(-state=>'normal')};
   }
   if(($selection) && ($dw->{mb_Delete})){
      eval{$dw->{mb_Delete}->configure(-state=>'normal')};
   }
   if(($dw) && ($dw->{"mb_Sel. All"}) && ($selection eq "") && ($dw->get ne "")){
      eval{$dw->{"mb_Sel. All"}->configure(-state=>'normal')};
   }

   return;


   #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   # Only set state to 'normal' for default items if clipboard is
   # not empty or selection is present.
   #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   if(defined $dw->{"mb_Paste"}){
      if(($clipboard) && ($dw->{"mb_Paste"}->cget(-state) ne 'normal')){
         eval{ $dw->{mb_Paste}->configure(-state=>'normal') };
      }
   }
   if(defined $dw->{"mb_Cut"}){
      if(($selection) && ($dw->{"mb_Cut"}->cget(-state) ne 'normal')){
         eval{ $dw->{mb_Cut}->configure(-state=>'normal') };
      }
   }
   if(defined $dw->{"mb_Copy"}){
      if(($selection) && ($dw->{"mb_Copy"}->cget(-state) ne 'normal')){
         eval{ $dw->{mb_Copy}->configure(-state=>'normal') };
      }
   }
   if(defined $dw->{"mb_Delete"}){
      if(($selection) && ($dw->{"mb_Delete"}->cget(-state) ne 'normal')){
         eval{ $dw->{mb_Delete}->configure(-state=>'normal') };
      }
   }
   if(defined $dw->{"mb_Sel. All"}){
      if(($dwVal) && ($dw->{"mb_Sel. All"}->cget(-state) ne 'normal')){
         eval{ $dw->{"mb_Sel. All"}->configure(-state=>'normal') };
      }
   }   
}

# Get the selected contents of the Entry widget
sub getSelection{
   my($dw, $selectionType) = @_;

   my($string);

   Tk::catch { $string = $dw->SelectionGet(-selection=>$selectionType) };

   $string = '' unless defined $string;
   return $string;
}

# Select all the contents of the Entry widget
sub selectAll{
   my $dw = shift;

   $dw->selectionRange(0,'end');
   setState($dw);
}

# Copy data to the clipboard
sub copyToClip{
   my $dw = shift;

   if($dw->selectionPresent){
      my $string = $dw->SelectionGet(-selection=>'PRIMARY');
      $dw->clipboardClear;
      $dw->clipboardAppend('--',$string);
   }

   my $popupmenu = $dw->Subwidget('popupmenu');
   $dw->withdrawMenu if($popupmenu->ismapped);
}

# Automatically put cut data into the clipboard
sub cutToClip{
   my $dw = shift;

   if($dw->selectionPresent){
      my $string = deleteSelected($dw);
      $dw->clipboardClear;
      $dw->clipboardAppend('--', $string);
   }

   my $popupmenu = $dw->Subwidget('popupmenu');
   $dw->withdrawMenu if($popupmenu->ismapped);
}

# Delete selected text
sub deleteSelected{
   my $dw = shift;

   my($deleted_string);

   my($from,$to);
   if( ($dw->selectionPresent) ){
      $from = $dw->index('sel.first');
      $to = $dw->index('sel.last');
      $deleted_string = substr($dw->get, $from, $to-$from);
      $dw->delete($from,$to);
   }

   my $popupmenu = $dw->Subwidget('popupmenu');
   $dw->withdrawMenu if($popupmenu->ismapped);
   
   return $deleted_string;
}

# Paste data from the clipboard into the Entry widget
sub pasteFromClip{
   my $dw = shift;

   my($from);

   if($dw->selectionPresent){
      $from = $dw->index('sel.first');
      deleteSelected($dw);
   }
   else{ $from = $dw->index('insert') }

   my $string = getSelection($dw,'CLIPBOARD');

   $dw->insert($from,$string);

   my $popupmenu = $dw->Subwidget('popupmenu');
   $dw->withdrawMenu if($popupmenu->ismapped);
}

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Add an item to the popup menu at the specified index.  The 'item' passed 
# is a reference to an anon. array that contains four items (in this order):
# 
# 1 - A label
# 2 - A callback associated with that label
# 3 - The bind event associated with that callback
# 4 - The 'underline' index value associated with the callback
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
sub addItem{
   my($dw, $index, $item) = @_;
   
   #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   # Permit the programmer to omit an index, in which case the item will be
   # added to the end of the menu.
   #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   if(ref($index) =~ /array/i){
      $item = $index;
      $index = 'end';
   }
   
   my $menu = $dw->cget(-menu);
   my $menuitems = $dw->cget(-menuitems);
   
   my $callback = $item->[1];
   my $binding  = $item->[2];
   
   my $length = scalar(@$menuitems);
   
   #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   # If index is not specified, 'end', or greater than the number of elements, 
   # just push it onto the end of the menuitem array.  
   #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   if( ($index eq 'end') || ($index > $length) ){ push(@$menuitems, $item) }
   
   #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   # If the index *is* specified, use a temporary array to hold the removed
   # elements using splice, insert the item, then push the temporary array
   # back onto the original array.
   #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   else{
      for(my $n = 0; $n < $length + 1; $n++){
         if($index == $n){
            my @temp = splice @$menuitems, $n;
            @$menuitems[$n] = $item;
            push(@$menuitems, @temp);
         }
      }
   }
   
   # Bind the item to the callback
   $dw->bind($binding, \&$callback);

   return $menuitems;          
}

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Delete an item from the menu based on the index passed.  The index 'end' may
# also be used as a valid index.  A group of items may be deleted as well.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
sub deleteItem{
   my($dw, $index, $last) = @_;
   
   # Make sure an index is supplied, or things could get ugly.
   if($index eq ""){ die "\nNo index supplied to 'deleteItem'" }
      
   my $menuitems = $dw->cget(-menuitems);
   my $length = scalar(@$menuitems);
   
   # Accept 'end' as a valid argument
   if($index eq 'end'){ $index = $length - 1 }
   if($last eq 'end'){ $last = $length }
   
   # Ensure that the first index is less than the second
   if( (defined $last) && ($last < $index) ){ 
      die "\nThe second index must be greater than the first";
   }
   
   my $numItems = $last - $index;
   
   # Remove a single item or group of items, as appropriate
   for(my $n = 0; $n < $length; $n++){
      if(($index == $n) && ($last eq "")){ 
         my $spliced = splice @$menuitems, $n, 1;
         return $spliced;
      }
      if(($index == $n) && ($last ne "")){
         my @spliced = splice @$menuitems, $n, $numItems;
         return \@spliced;
      } 
   }
}   
1;

__END__


=head1 NAME

PopEntry - An Entry widget with an automatic, configurable right-click
menu built in, plus input masks.

=head2 SYNOPSIS

  use PopEntry;
  $dw = $parent->PopEntry(
      -pattern   => 'alpha', 'alphanum', 'capsonly', 'signed_int', 
                 'unsigned_int', 'float', 'nondigit', or any supplied regexp.
      -nomenu    => 0 or 1,
      -case      => 'upper', 'lower', 'capitalize',
      -maxwidth  => int,
      -minvalue  => int,
      -maxvalue  => int,
      -nospace   => 0 or 1,
      -menuitems => ['string', 'package::callback', 'binding', 'index'],
   );
   $dw->pack;

=head2 DESCRIPTION

An Entry widget with a right-click menu attached automatically.
In addition, certain field masks can easily be applied to the Entry
widget in order to force the end-user into entering only the values
you want him or her to enter.

By default, there are five items attached to the right-click menu: Cut, Copy,
Paste, Delete and Sel. All.  The default bindings for the items are Control-x,
Control-c, Control-v, Control-d, and Control-a, respectively.

The difference between 'Cut' and 'Delete' is that the former automatically
copies the contents that were cut to the clipboard, while the latter does not.

=head2 OPTIONS

B<-pattern =E<gt>> I<string>

S<   The pattern specified here creates an input mask for the PopEntry
widget.  There are seven pre-defined masks:> 

=over 4

=item *

alpha - Upper and lower case a-z only.

=item *

alphanum - Alpha-numeric characters only.

=item *

capsonly - Upper case A-Z only.

=item *

nondigit - Any characters except 0-9.

=item *

float - A float value, which may or may not include a decimal.

=item *

signed_int - A signed integer value, which may or may not include a '+'.

=item *

unsigned_int - An unsigned integer value.

=back

S<You may also specify a regular expression of your own design using Perl's
standard regular expression mechanisms.  Be sure to use single quotes, e.g.
 '/\d\w\d/'>

B<-nomenu =E<gt>> I<B<0> or 1>

S<   If set to true, then no right-click menu will appear.  Presumably, you would
set this if you were only interested in the input-mask functionality.  The
default is, of course, 0.>

B<-nospace =E<gt>> I<B<0> or 1>

S<   If set to true (1), the user may not enter whitespace before, after or 
between words within that PopEntry widget.  The default is 0.>

B<-maxwidth =E<gt>> I<int>

S<   Specifies the maximum number of characters that the user can enter in that
particular PopEntry widget.  Note that this is not the same as the width
of the widget itself.>

B<-maxvalue =E<gt>> I<int or float>

S<   If one of the pre-defined numeric patterns is chosen, this specifies the
maximum allowable value that may be entered by a user for the widget.>

B<-minvalue =E<gt>> I<int or float>

S<   If one of the pre-defined numeric patterns is chosen, this specifies the
minimum allowable value for the first digit (0-9).  This should work better.>

B<-menuitems =E<gt>> 
I<['string', 'callback', 'E<lt>bindingE<gt>', 'underline_index']>

S<   If specified, this creates a user-defined right-click menu rather than
the one that is provided by default.  The value specified must be a four
element nested anonymous array that contains (in this order):>

=over 4

=item 1

a string that appears on the menu,

=item 2

a callback (in 'package::callback' syntax format), 

=item 3

a binding for that option (see below), 

=item 4

an index value specifying the character in the string to be underlined.

=back

S<The binding specified need only be in the form, 'E<lt>Control-xE<gt>'.  You
needn't explicitly bind it yourself.  Your callback will automatically be
bound to the event sequence you specified.>

=head2 METHODS

B<$lpe-E<gt>deleteItem(index, ?index?)> 

S<   Deletes the menu option at the specified index.  A range of values may be
deleted as well, e.g. $lpe-E<gt>deleteItem(3,'end');  Returns an array reference
if a single item is deleted, or a reference to an array of references if more
than one item is deleted.>

B<$lpe-E<gt>addItem(?index?, $item)>

S<   Adds a menu option at the specified index, where $item is an anonymous array
consisting of four elements (see the -menuitems option for details).  If no 
index is specified, the new item will be added at the end of the menu.  If an
item already exists at that index, the current menu items will be "bumped"
down.  Returns the list of menuitems.>

=head2 ADVERTISED SUBWIDGETS

B<$lpe-E<gt>Subwidget('popupmenu')>

S<Returns a reference to the popupmenu (a toplevel widget).>

=head2 KNOWN BUGS

The -minvalue only works for the first digit.

There is still potential for odd results if your bind happens to coincide
with a binding already used by the Window Manager.  In windows, where I
did most of my testing, this meant that Control-v would paste twice, once
because MS Windows told it to, and once because I told it to.  I got
different (bad) results with Control-v in KDE on Mandrake 7.2.

=head2 PLANNED CHANGES

Fix the issues mentioned above.

Automatically bind the 'Alt' key to the underlined character.

Give the option to remove bindings completely.

=head2 AUTHOR

Daniel J. Berger
djberg96@hotmail.com

=head2 SEE ALSO

Entry

=cut
