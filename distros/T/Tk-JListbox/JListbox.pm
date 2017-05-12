# Copyright (c) 2000 Daniel J. Berger. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Tk::JListbox;
use vars qw($VERSION);
$VERSION = '.01';

use warnings;

require Tk::Derived;
require Tk::Listbox;
require Tk::Toplevel;

@ISA = qw(Tk::Derived Tk::Listbox Tk::Toplevel);

Construct Tk::Widget 'JListbox';
   
sub Populate{
	my ($dw,$args) = @_;
   $dw->SUPER::Populate($args);
   
   my $popupmenu = delete $args->{-popupmenu};
   my $justifyVal = $args->{-justify};
   
   my $menuitems;
   
   if(defined($popupmenu)){
      $popupmenu = $dw->Toplevel(-bd=>2, -relief=>'raised');
      $popupmenu->withdraw;
      
      # Default menu items.  Format is: label, callback, bind, underline.
      if(!defined($menuitems)){
         $menuitems = [
            ["Cut", 'Tk::JListbox::Jcut', '<Control-x>', 2],
            ["Copy", 'Tk::JListbox::Jcopy', '<Control-c>', 0],
            ["Paste", 'Tk::JListbox::Jpaste', '<Control-v>', 0],
         ]
      }
      
      $dw->setBindings;
   }
   
   $dw->Advertise('popupmenu' => $popupmenu) if defined $popupmenu;
 
   $dw->ConfigSpecs(
      -justify    => [qw/METHOD justify Justify left/],
      -autowidth  => [qw/PASSIVE autowidth Autowidth 0/],
      -popupmenu  => [qw/PASSIVE undef undef/, $popupmenu],
      -menuitems  => [qw/PASSIVE undef undef/, $menuitems],
      -justifyVal => [qw/PASSIVE undef undef/, $justifyVal],
      DEFAULT  => [$dw],
   );
   
}

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Use the appropriate subroutine based on whether the user selected the 'right'
# or 'center' option, and on the type of font (proportional vs. fixed).
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
sub justify{
    my ($dw,$flag) = @_;
    
    my $font = $dw->cget(-font);
    my $fontVal = $dw->fontMetrics($font, -fixed);
    
    if($flag eq 'center'){     
      if($fontVal == 1){ justifyCenter_fixed($dw) }
      else{ justifyCenter_variable($dw) }
    }
    if($flag eq 'right'){ 
      if($fontVal == 1){ justifyRight_fixed($dw) }
      else{ justifyRight_variable($dw) }
    }
  
    return;
}

# Center the text for variable width fonts
sub justifyCenter_variable{
   my $dw = shift;
   my $fontref = $dw->cget(-font);                     # Get the font name
   my @textArray = $dw->get(0, 'end');                 # Get the text
   my $blank = ' ';                                    # Set a blank
   my $blanksize = $dw->fontMeasure($$fontref,$blank); # Measure a blank space
   my $pixelwidth = $dw->width;                        # Get width of Listbox
   $dw->delete(0,'end');                               # Delete text
   
   foreach my $word(@textArray){
      $word =~ s/^\s+//;                                # Remove whitespace
      $word =~ s/\s+$//;
      my $textsize = $dw->fontMeasure($$fontref,$word); # Measure the text
      my $pixelsleft = $pixelwidth - $textsize;         # Total pixels left
      my $pixelhalf  = $pixelsleft/2;                   # Pixels left per side
      my $spaceequiv = int($pixelhalf/$blanksize);      # Fixed space equiv.
      my $spaces = ' ' x $spaceequiv;                   # Build whitespace
  
      $word =~ s/$word/$spaces$word/;                   # Prepend spaces
           
      $dw->insert('end',$word);                         # Finally re-insert
   } 
   $dw->bind("<Configure>", \&justifyCenter_variable);  # Stay centered
   $dw->configure(-justifyVal=>'center');               # Set object variable
}

# Center the text for a fixed width font
sub justifyCenter_fixed{
   my $jlb = shift;
   my @textArray = $jlb->get(0,'end');
   my $width = $jlb->width;
   $jlb->delete(0,'end');
   
   foreach my $word(@textArray){
      $word =~ s/^\s+//;
      $word =~ s/\s+$//;
      my $spaces = ($width - (length($word))) / 2;
      $word =~ s/$word/$spaces$word/;
      
      $jlb->insert('end',$word);
   }
   $jlb->bind("<Configure>", \&justifyCenter_fixed);
   $dw->configure(-justifyVal=>'center');               # Set object variable
}

# Right justify the text for a variable width font
sub justifyRight_variable{
   my $dw = shift;
   my $fontref = $dw->cget(-font);                     # Get the font name
   my @textArray = $dw->get(0, 'end');                 # Get the text
   my $blank = ' ';                                    # Set a blank
   my $blanksize = $dw->fontMeasure($$fontref,$blank); # Measure a blank space
   my $pixelwidth = $dw->width;                        # Get width of Listbox
   $dw->delete(0,'end');                               # Delete text
   
   foreach my $word(@textArray){
      $word =~ s/^\s+//;
      $word =~ s/\s+$//;
      my $textsize = $dw->fontMeasure($$fontref,$word); # Measure the text
      my $pixelsleft = $pixelwidth - $textsize;         # Total pixels left
      my $spaceequiv = int($pixelsleft/$blanksize);     # Fixed space equiv.
      $spaceequiv = ($spaceequiv - $blanksize);         # Drop one char back
      my $spaces = ' ' x $spaceequiv;                   # Build whitespace
      
      $word =~ s/$word/$spaces$word/;                   # Prepend spaces
      $dw->insert('end',$word);                         # Finally re-insert
   }
   $dw->bind("<Configure>", \&justifyRight_variable);   # Stay right justified
   $dw->configure(-justifyVal=>'right');                # Set object variable
} 

# Right justify the text for a fixed width font
sub justifyRight_fixed{
   my $dw = shift;
   my @textArray = $dw->get(0,'end');
   my $width = $dw->width;
   $dw->delete(0,'end');
   
   foreach my $word(@textArray){
      $word =~ s/^\s+//;
      $word =~ s/\s+$//;
      my $spaces = $width - (length($word));
      $word =~ s/$word/$spaces$word/;
      
      $dw->insert('end',$word);
   }
   $dw->bind("<Configure>", \&justifyRight_fixed);
   $dw->configure(-justifyVal=>'right');                # Set object variable
}

sub JraisePopup{
   my($dw, $toplevel) = @_;
     
   my $menuref = $dw->cget(-menuitems);
   my $popupmenu = $dw->cget(-popupmenu);
   
   my $state = $popupmenu->state;
   if($state ne 'withdrawn'){ return }
   
   $popupmenu->overrideredirect(1);
   
   foreach my $item(@$menuref){
      $string   = $item->[0];
      $callback = $item->[1];
      $binding  = $item->[2];
      $index    = $item->[3];

      #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      # Use auto-vivification here to create a key for each button based on
      # the name of the button, preceded by an 'm_'.
      #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      if(!defined($dw->{"m_$string"})){
         $dw->{"m_$string"} = $popupmenu->Button(
               -text       => "$string\t$binding",
               -underline  => $index,
               -command    => [$callback, $dw],
         );
      }
      
      $dw->bind($binding, \$callback);
      
      my $button = $dw->{"m_$string"};
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
   
   $dw->JsetState;
   
   $popupmenu->geometry(sprintf("+%d+%d", $dw->rootx, $dw->rooty));
   $popupmenu->deiconify;
   $dw->grab;
}

# Withdraw the popup menu if it is raised.
sub lowerPopup{
   my $dw = shift;

   my $popup = $dw->cget(-popupmenu); 
   my $state = $popup->state;
   
   if($state ne 'withdrawn'){ $popup->withdraw }
   else{ return }
   
   $dw->grabRelease;
}

# Set the bindings for the popup menu.
sub setBindings{
   my $dw = shift;
   
   $dw->bind('<Button-3>', sub{ $dw->JraisePopup });
   $dw->bind('<Button-1>', sub{ $dw->lowerPopup });
}

# Copy the selected elements to the clipboard;
sub Jcopy{
   my $dw = shift;
   my $popup = $dw->cget(-popupmenu);
   my @selection = $dw->curselection;
   
   if(@selection ne ""){
      $dw->clipboardClear;
      
      foreach my $index(@selection){ 
         my $string = $dw->get($index);
         
         # Remove any leading or trailing whitespace
         $string =~ s/^\s*//;
         $string =~ s/\s*$//;
         $dw->clipboardAppend('--', $string); 
      }
   }
   
   $popup->withdraw;
   $dw->grabRelease;   
}

# Cut the selection and copy it to the clipboard
sub Jcut{
   my $dw = shift;
   my $popup = $dw->cget(-popupmenu);
   
   my @selection = $dw->curselection;
   
   if(@selection ne ""){
      $dw->clipboardClear;
      
      foreach my $index(@selection){ 
         my $string = $dw->get($index);
         
         # Remove any leading or trailing whitespace
         $string =~ s/^\s*//;
         $string =~ s/\s*$//;
         $dw->clipboardAppend('--', $string);
         
         # Remove the item
         $dw->delete($index); 
      }
   }
   
   $popup->withdraw;
   $dw->grabRelease;
}

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Paste a string into the Listbox.  Prompt the user to see if they want to
# paste above or below the current selection.
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
sub Jpaste{
   my $dw = shift;
   my $popup = $dw->cget(-popupmenu);
   
   $popup->withdraw;
   
   Tk::catch { $string = $dw->SelectionGet(-selection=>'CLIPBOARD') };
   
   my $dialog = $dw->DialogBox(
      -title   => "Paste location...", 
      -buttons => ["OK", "Cancel"]
   );
   
   my $r_selection;
   
   # Some spaces hardcoded for alignment purposes
   foreach("  Above selection", "  Below Selection",
           "  Left of Selection", "Right of Selection"){
      $dialog->add(
         'Radiobutton', 
         -text     => $_,
         -value    => $_,
         -variable => \$r_selection,
      )->pack;
   }
   
   my $ans = $dialog->Show;
   
   if($ans eq "OK"){
      my $index = $dw->curselection;
      $dw->Jinsert($index, $r_selection)
   }
      
   $dw->grabRelease;
}
  
sub Jinsert{
   my($dw, $index, $side) = @_;
  
   $side =~ s/.*?(\w+).*/$1/;
   
   my $string = $dw->get($index);
   my $flag = $dw->cget(-justifyVal);
   
   # Clear whitespace
   $string =~ s/^\s*//;
   $string =~ s/\s*$//;
   
   my $selection;
   
   eval{ $selection = $dw->SelectionGet(-selection=>'CLIPBOARD') };
   if($EVAL_ERROR){ return }
   
   # Automatically insert 1 whitespace character
   if($side eq "Right"){ 
      $string .= " $selection";
      $dw->delete($index);
      $dw->insert($index, $string);
   }
   if($side eq "Left"){
      $string = $selection . " $string";
      $dw->delete($index);
      $dw->insert($index, $string);
   }
   
   Tk::catch{ $string = $dw->SelectionGet(-selection=>'CLIPBOARD') };
   
   #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   # Pasting above or below requires storing the contents of the listbox
   # in an array and then re-inserting them at the proper index.
   #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   if($side eq "Below"){
      my @items = $dw->get($index+1, 'end');
                 
      $dw->delete($index+1,'end');
      $dw->insert($index+2,$string, @items);        
   }
   if($side eq "Above"){
      my @items = $dw->get($index, 'end');
      $dw->delete($index, 'end');
      $dw->insert($index, $string, @items);
   }
   
   # Keep current justification
   $dw->justify($flag);   
}

# Determine the various menu items should be 'normal' or 'disabled'
sub JsetState{
   my $dw = shift;

   my($selection, $clipboard);
   
   eval { $selection = $dw->curselection };
   Tk::catch{ $clipboard = $dw->SelectionGet(-selection=>'CLIPBOARD') };

   my $menuref = $dw->cget(-menuitems);

   # Set the default menu items to 'disabled', enabling them if appropriate
   foreach my $item (@$menuref){
      if($item->[0] =~ /Cut|Copy|Paste/){
         $dw->{"m_$item->[0]"}->configure(-state=>'disabled');
      }
   }
   
   #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   # Only set state to 'normal' for default items if clipboard is
   # not empty or selection is present.
   #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   if( (defined($selection)) && ($clipboard) && ($dw->{m_Paste})){
      $dw->{m_Paste}->configure(-state=>'normal');
   }
   if( (defined($selection)) && ($dw->{m_Cut})){
      $dw->{m_Cut}->configure(-state=>'normal');
   }
   if( (defined($selection)) && ($dw->{m_Copy})){
      $dw->{m_Copy}->configure(-state=>'normal');
   }

} #END setState()    

1;
__END__

=head1 JListbox

JListbox - justify text within a Listbox

=head1 SYNOPSIS

  use JListbox;
  $dw = $parent->JListbox(-justify=>'center', -popupmenu=>1);
  $dw->pack;

=head1 DESCRIPTION

JListbox is identical to a Listbox, but has two addtional options: -justify
and -popupmenu.

=head3 -justify

Possible values for '-justify' are 'left', 'center' and 'right'.  The default 
is 'left'.  All text within the Listbox will be justified according to the 
option you set.

The widget automatically checks for variable or fixed width fonts 
and adjusts accordingly.

You cannot justify individual entries separately (as of version .02).

Your text will remain justified appropriately, even if you 
set the '-expand' and '-fill' options.

The justification ability is provided via plain old pixel and 
character counting (depending on whether you are using a variable or 
fixed width font).  There have been no underlying changes in the C code
to the Tcl Listbox.

=head3 -popupmenu

If the -popupmenu option is used, a "Cut, Copy, Paste" menu will appear when
the user right-clicks anywhere on the JListbox.

The "Cut" option will remove the item from the JListbox, copy it to the
clipboard and the remaining items will shift up automatically.

The "Copy" option simply copies the selected value to the clipboard.

The "Paste" option, if selected, will bring up a Dialog window that gives the
user the option to paste (insert) above or below the selected item, as well as
on the same line, either to the left or right of the selected item.  

One whitespace character is automatically separates the pasted value if the
'left' or 'right' option is chosen.

If you wish to modify the popup menu itself, you can retrieve it using the
Subwidget method with 'popupmenu' as the widget name.

$menu = $dw->Subwidget('popupmenu');

=head1 KNOWN BUGS

If using a variable width font, you may encounter a problem with the last 
character disappearing off the right side of the listbox when you use
right justify.  I think I fixed this, so let me know if you have any problems.

If the text you insert into the listbox includes characters that have 
special meaning in regular expressions (e.g. '*', '?'), you will need to 
escape them using the '\' character or your app may crash.

e.g. $dw->insert('end', "What did you say\?");

=head1 PLANNED CHANGES

Fix the regular expression issue mentioned above.

Allow individual entries to be justified.

Add the 'addMenuItem' and 'deleteMenuItem' methods to allow greater
configurability of the right-click menu.

=head1 AUTHOR

Daniel J. Berger
djberg96@hotmail.com

Thanks goes to Damion K. Wilson for his help with creating widgets.

=head1 SEE ALSO

Listbox

=cut


