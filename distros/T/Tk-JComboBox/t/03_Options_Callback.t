#! /usr/bin/perl

#################################################################
## Name: 03_Options_Callback.t
## 
## Purpose: Tests all options that take Callbacks as their values
##
## Tested Options: (also tests -mode)
##  -buttoncommand
##  -keycommand
##  -popupcreate
##  -popupmodify
##  -selectcommand
##  -validate
##  -validatecommand
################################################################

use diagnostics;
use strict;

use Tk;
use Tk::JComboBox;
use Test::More tests => 71;

my $mw = MainWindow->new;

#####################
## -buttoncommand
#####################
diag "\n\ntesting buttoncommand:\n";
TestButtonCommand('readonly', [1, 2, 3]);
TestButtonCommand('editable', [1, 2, 2]);

#####################
## -keycommand 
      my $unexpectedOption = 0;
#####################
diag "\ntesting keycommand: \n";
TestKeyCommand("readonly");
TestKeyCommand("editable");

#####################
## -popupcreate
## -popupmodify
#####################
diag "\ntesting popupcreate/modify:\n";
TestPopup('create', 'readonly');
TestPopup('create', 'editable');

TestPopup('modify', 'readonly');
TestPopup('modify', 'editable');

TestCreateModifyPopup('readonly');
TestCreateModifyPopup('editable');

#####################
## -selectcommand
#####################
diag "\ntesting selectcommand:\n";
TestSelectCommand('editable');
TestSelectCommand('readonly');

###################################
## Validation Testing
###################################
diag "\ntesting validation:\n";
TestValidation();

## Cleanup
$mw->destroy;

############################################################
## Test Subroutines
############################################################

sub TestButtonCommand
{
   my ($mode, $resultsAR) = @_;

   eval {
      my $cmdCalled = 0; 
      my $jcb = Setup(qw/pack -mode/, $mode);
      $jcb->pack;

      $jcb->configure(-buttoncommand => sub {
         my ($jcb, $selection) = @_;
	 is(ref($jcb), "Tk::JComboBox");
	 is($selection, -1);
	 $cmdCalled++;
      });
      $jcb->update;

      ## Directly invoke Event Handlers
      $jcb->ButtonDown;
      $jcb->ButtonUp;
      is($cmdCalled, $resultsAR->[0]);

      ## Simulate events
      my $b = $jcb->Subwidget('Button');
      my $e = $jcb->Subwidget('Entry');

      $b->eventGenerate('<ButtonPress-1>');
      $b->eventGenerate('<ButtonRelease-1>');
      $jcb->update;
      is($cmdCalled, $resultsAR->[1]);

      $e->eventGenerate('<ButtonPress-1>');
      $e->eventGenerate('<ButtonRelease-1>');
      $jcb->update;
      is($cmdCalled, $resultsAR->[2]);
      $jcb->destroy;
   };
   fail "\nFail - TestButtonCommand($mode): $@" if $@;
}

sub TestCreateModifyPopup
{
   my $mode = shift;
   eval {
      my $jcb = Setup('pack',
         -mode => $mode,
         -choices => [qw/one/]);
      $mw->update;

      my $cb = 0;
      $jcb->configure(
         -popupcreate => sub {$cb++},
         -popupmodify => sub {$cb++});

      my $button = $jcb->Subwidget('Button');
      $button->eventGenerate('<ButtonPress-1>');
      $jcb->hidePopup;
      $mw->update;
      is($cb, 2);
      $cb = 0;
      $jcb->destroy;
   };
   fail "\nFail - TestCreateModifyPopup($mode): $@" if $@;
}
  
sub TestKeyCommand
{
   my $mode = shift;
   eval {
      my $uChar;
      my $key;
      my $cb = 0;

      my $jcb = Setup('pack',
         -mode => $mode,
         -keycommand => sub {
	    $uChar = $_[1];
	    $key = $_[2];
	    $cb++;
	 }
      );
      my $e = $jcb->Subwidget('Entry');
      $e->focusForce;
      $e->eventGenerate('<KeyPress>', -keysym => 'a');

      is($cb, 1, 'KeyCommand called');
      is($uChar, 'a', 'uChar correctly passed');
      is($key, 'a', 'key correctly passed');
      $jcb->destroy;
   };
   fail "\nFail - TestKeyCommand($mode): $@" if $@;
}

sub TestPopup
{
   my ($type, $mode) = @_;
   eval {
      my $cb = 0;

      my $jcb = Setup('pack',
         -mode => $mode,
        "-popup$type", sub { $cb++; }
      );
      $jcb->showPopup;
      $jcb->hidePopup;
      is($cb, 1, "-popup$type called, even when there are no items");
      $cb = 0;

      my $button = $jcb->Subwidget('Button');
      $button->eventGenerate('<ButtonPress-1>');
      $jcb->hidePopup;
      $mw->update;
      is($cb, 1, "-popup$type called, even when there are no items");
      $cb = 0;

      ## Add one item to the combobox 
      $jcb->addItem("one");
      $jcb->showPopup;
      is($cb, 1, "-popup$type - configured, items, popup invisible");
      $cb = 0;
   
      $jcb->showPopup;
      $jcb->hidePopup;
      is($cb, 1, "-popup$type not called when popup is visible");
      $cb = 0;

      $button->eventGenerate('<ButtonPress-1>');
      $mw->update;
      is($cb, 1, "-popup$type called from <ButtonPress-1>");
      $cb = 0;

      $button->eventGenerate('<ButtonPress-1>');
      $jcb->hidePopup;
      $mw->update;
      is($cb, 1, "-popup$type not called when popup is visible");
      $cb = 0;
      $jcb->destroy;
   };
   fail "\nFail - TestPopup($mode): $@" if $@;
}

sub TestSelectCommand 
{
   my $mode = shift;
   eval {
      my ($w, $selIndex, $selName, $selValue);
      my $cb = 0;
      my $jcb = Setup('pack',
         -mode => $mode,
         -choices => [qw/one two three/],
         -selectcommand => sub {
            ($w, $selIndex, $selName, $selValue) = @_;
            $cb++;
	 });
      $jcb->addItem('four', -value => 4);
      $mw->update;

      ## 1) Test that selectcommand is triggered by setSelectedIndex
      ##    method call.
      $jcb->setSelectedIndex(0);
      is($cb, 1, 'Verify that -selectcommand callback was called');
      is($selIndex, 0, 'verify that index 0 was passed to callback');
      is($selName, 'one', 'verify that "one" (name) was selected');
      is($selValue, 'one', 'verify that "one"(value) was selected');
      $cb = 0;

      ## 2) Test that selectcommand is not triggered when selection is set 
      ## that matches existing selection.
      $jcb->setSelectedIndex(0);
      is($cb, 0, '-selectcommand triggered by duplicate selection');
   
      ## 3) Test that selectcommand is triggered when setSelected method is
      ## is called.
      $jcb->setSelected('four');
      is($cb, 1, 'verify that -selectcommand callback was called');
      is($selIndex, 3, 'verify that index 3 was passed');
      is($selName, 'four');
      is($selValue, '4');
      $jcb->clearSelection;
      $cb = 0;

      $jcb->destroy;

      ## TODO: This test routine should probably be expanded to include
      ## event handling.
   };
   fail "\nFail - TestSelectCommand($mode): $@" if $@;
   
}

sub TestValidation
{
   my $cb = 0;
   my $letter;
   eval {

      my $jcb = Setup('pack',
         -mode => 'editable',
         -validate => 'key',
         -validatecommand => sub {
            $letter = $_[1]; 
            $cb++;
            return 1;
         }
      );


      my $entry = $jcb->Subwidget('Entry');
      $entry->focusForce;
      $mw->update;

      $entry->eventGenerate('<KeyPress>', -keysym => 'a');
      is($cb, 1, 'validatecommand should have been called');
      is($letter, 'a', 'validatecommand was called because of "a"');
      $jcb->destroy;

      $jcb = Setup('pack',
         -mode => 'editable',
         -choices => [qw/oNe tWo tHree/],
         -validate => 'match'
      );
      $entry = $jcb->Subwidget('Entry');
      $entry->focusForce;

      $entry->eventGenerate('<KeyPress>', -keysym => 'o');
      $entry->eventGenerate('<KeyPress>', -keysym => 'n');
      $entry->eventGenerate('<KeyPress>', -keysym => 'e');
      $mw->update;
      is($jcb->getSelectedValue, 'one');
  
      $entry->eventGenerate('<KeyPress>', -keysym => 't');
      $mw->update;
      is($jcb->getSelectedValue, 'one');
      
      $jcb->clearSelection;
      $jcb->configure(-validate => 'cs-match');
 
      $entry->eventGenerate('<KeyPress>', -keysym => 'o');
      $entry->eventGenerate('<KeyPress>', -keysym => 'n');
      $entry->eventGenerate('<KeyPress>', -keysym => 'e');
      $mw->update;

      is($jcb->getSelectedValue, 'o');
      $jcb->destroy;
   };
   fail "\nFail - TestValidation: $@" if $@;
}


sub Setup
{
   my $pack = 0;
   if ($_[0] eq "pack") {
      shift @_;
      $pack = 1;
    }
   my $jcb = $mw->JComboBox(@_);
   if ($pack) {
      $jcb->pack;
      $mw->update;
   }
   return $jcb;
}


sub GetCoordFromIndex
{
   my ($listbox, $index) = @_;
   my ($x, $y, $w, $h) = $listbox->bbox($index);
   return "\@$x,$y";
}







