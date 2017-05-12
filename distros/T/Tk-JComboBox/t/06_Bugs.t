#! /usr/local/bin/perl 
## 05_Bugs -- Test Cases for reported bugs

use diagnostics;
use strict;

use Tk;
use Tk::JComboBox;
use Test::More tests => 28;

my $mw = MainWindow->new;

###########################################################
## ID: CPAN #11707 - Reported By Ken Prows
## BUG: AutoFind sub does not scroll down to "see" the new
## selection 
## --------------------------------------------------------
## When there are a lot of choices is the combo box, it is 
## convenient to press a letter/number on the keyboard to 
## scroll down to the choices that begin with that letter. 
## The AutoFind sub seems to do this. However, the AutoFind 
## sub only highlights the choice that begins with the 
## letter. It does not scroll down/up so that it is viewable. 
###########################################################
diag "\n\nTest Item Visible After AutoFind\n";
TestItemVisibleAfterAutoFind("readonly");
TestItemVisibleAfterAutoFind("editable");

###########################################################
## ID: CPAN #12372 - Reported By Ken Prows
## BUG: grab function in JComboBox makes it unusable in 
## dialog boxes.
## --------------------------------------------------------
## grabGlobal/grabRelease in showPopup/hidePopup methods
## interfere with grab used by Dialogs. If a JCombobox was
## used within any widget that did a grab or grabGlobal, then
## when the JComboBox's popup was displayed, it would steal the
## grab from the original widget. When the popup was hidden,
## the grab would be released AND NOT RETURNED to the original 
## widget as expected. Ken submitted a patch which I reformatted
## slightly and included. Thanks!
###########################################################
diag "\nTest that stolen grab (local) was returned\n";
TestThatStolenGrabWasReturned('local');
diag "\nTest that stolen grab (global) was returned\n";
TestThatStolenGrabWasReturned('global');

############################################################
## Test Subroutines
############################################################
sub TestItemVisibleAfterAutoFind
{
   my $mode = shift;
   eval {
      my @list = 
         (qw/alpha bravo charlie delta echo foxtrot golf hotel india/);
   
      my $jcb = $mw->JComboBox(
         -choices => \@list,
         -maxrows => 4,
         -mode => $mode
      )->pack;
      $mw->update;

      checkItemVisibility($jcb, "a", 0);
      checkItemVisibility($jcb, "i", 8);
      checkItemVisibility($jcb, "e", 4);
      checkItemVisibility($jcb, "a", 0);
      $jcb->destroy;
   };
   fail "\nFail - TestItemVisibleAfterAutoFind($mode): $@" if $@;
}

sub TestThatStolenGrabWasReturned
{
   my $grabType = shift;
   my $jcb = $mw->JComboBox(-choices => [qw/one two three/])->pack;
   $mw->update;

   $mw->grab       if $grabType eq 'local';
   $mw->grabGlobal if $grabType eq 'global';

   is(ref($mw->grabCurrent), "MainWindow");
   is($mw->grabStatus, $grabType);

   $jcb->showPopup;

   my $widget = $mw->grabCurrent;
   is(ref($widget), "Tk::JComboBox");
   is($widget->grabStatus, "global");

   $jcb->hidePopup;
   is(ref($mw->grabCurrent), "MainWindow");
   is($mw->grabStatus, $grabType);

   $mw->grabRelease;
   $jcb->destroy;
}

sub checkItemVisibility 
{
   my ($jcb, $key, $expectedIndex) = @_;

   $jcb->clearSelection;
   my $entry = $jcb->Subwidget('Entry');
   my $listbox = $jcb->Subwidget('Listbox');

   $entry->focusForce;
   $entry->insert(0, $key) if $jcb->mode() eq "editable";
   $jcb->AutoFind($key, $key);
   my ($index) = $listbox->curselection;

   ## Was the expected Index selected?
   is($index, $expectedIndex); 
   
   my $result = "visible";
   if (!defined($index) || $listbox->bbox($index) eq "") {
      $result = "not visible";
   }
   is($result, "visible");
}


