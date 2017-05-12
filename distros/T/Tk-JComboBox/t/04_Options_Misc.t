#! /usr/bin/perl

#################################################################
## Name: 04_Options_Misc.t
##
## Purpose: Tests Specialized options that may have complex 
##  effects on the JComboBox. This is basically an excuse to
##  partition some of the option tests into a separate test file.
##
## Tested Options: (also tests -mode)
##  -autofind
##  -choices/-options
##  -listhighlight
##  -maxrows
##  -state
##  -updownselect
################################################################ 
use Carp;
use diagnostics;
use strict;

use Tk;
use Tk::JComboBox;
use Test::More tests => 254;

my $mw = MainWindow->new;

#####################
## -autofind
#####################
diag "\n\ntesting autofind:\n";
TestAutoFind('readonly');
TestAutoFind('editable');

#####################
## -choices/options
#####################
diag "\ntesting choices:\n";
TestChoices("-choices");
TestChoices("-options");

####################################
diag "\nTest Choices - FETCHSIZE\n";
####################################
my @list = (qw/one two three/);
my @list2 = (qw/four five six/);
my $jcb = setup("pack", -choices => \@list);

is(scalar(@list), 3);
$jcb->removeItemAt(0);
is(scalar(@list), 2);

###################################
diag "\nTest Choices - CLEAR\n";
###################################
@list = ();
is($jcb->getItemCount, 0);

###################################
diag "\nTest Choices - PUSH\n";
###################################
push(@list, @list2);
is($jcb->getItemCount, 3);
is($jcb->getItemNameAt(0), "four");
is($jcb->getItemNameAt(1), "five");
is($jcb->getItemNameAt(2), "six");
push(@list, @list2);
is($jcb->getItemCount, 6);

###################################
diag "\nTest Choices - POP\n";
###################################
my $item = pop @list;
is($item, "six");
is($jcb->getItemCount, 5);

###################################
diag "\nTest Choices - SHIFT\n";
###################################
$item = shift @list;
is($item, "four");
is($jcb->getItemCount, 4);
is($jcb->getItemNameAt(0), "five");

###################################
diag "\nTest Choices - STORE\n";
###################################
@list = (qw/one two three/);
is($jcb->getItemCount, 3);
is($jcb->getItemNameAt(0), "one");
is($jcb->getItemNameAt(1), "two");
is($jcb->getItemNameAt(2), "three");

$list[2] = "four";
is($jcb->getItemNameAt(2), "four");
$jcb->removeAllItems;

###################################
diag "\n\nTest Choices - FETCH\n";
###################################
$jcb->addItem("five");
$jcb->addItem("four");
$jcb->addItem("three");

is($list[0], "five");
is($list[1], "four");
is($list[2], "three");

###################################
diag "\nTest Choices - UNSHIFT\n";
###################################
unshift @list, (1, 2, 3);
is($jcb->getItemCount, 6);
is($list[0], 1);
is($list[1], 2);
is($list[2], 3);

###################################
diag "\nTest Choices - DELETE\n";
###################################
delete $list[0];
is($jcb->getItemCount, 5);
is($list[0], 2);
$jcb->destroy;


#####################
## -listhighlight
#####################
diag "\ntesting listhighlight:\n";
TestListhighlight('editable');
TestListhighlight('readonly');

#####################
## -maxrows
#####################
diag "\ntesting maxrows:\n";
TestMaxRows('editable');
TestMaxRows('readonly');

#####################
## -state
#####################
diag "\ntesting state:\n";
TestState('editable');
TestState('readonly');

#####################
## -updownselect
#####################
diag "\ntesting updownselect:\n";
TestUpDownSelect('readonly');
TestUpDownSelect('editable');

############################################################
## Test Subroutines
############################################################
sub checkAutoFindSelection
{
   my ($jcb, $letter, $expectedIndex, $expectedValue) = @_;
   my $index = $expectedIndex;
   $index = undef if $expectedIndex == -1;
   checkListboxSelection($jcb, $letter, $index);
   is($jcb->getSelectedIndex, $expectedIndex);
   is($jcb->getSelectedValue, $expectedValue);
}

sub checkCreateGetSet 
{
   my ($mode, $name, $value, $swAR) = @_;
   my $jcb = setup(-mode => $mode, $name, $value);
   is($jcb->cget($name), $value);
   checkSubwidgetOption($jcb, $name, $value, $swAR);	
   $jcb->destroy;

   $jcb = setup(-mode => $mode);
   $jcb->configure($name, $value);
   is($jcb->cget($name), $value);
   checkSubwidgetOption($jcb, $name, $value, $swAR);
   $jcb->destroy;
}

sub checkListboxSelection
{
   my ($jcb, $key, $expectedIndex) = @_;
   $jcb->Subwidget('Entry')->eventGenerate('<KeyPress>', -keysym => $key);
   my ($index) = $jcb->Subwidget('Listbox')->curselection;
   is($index, $expectedIndex);
}

sub checkMotionOnIndex
{
   my ($lb, $index, $expected) = @_;
   my ($x, $y) = getCoordFromIndex($lb, $index);
   $lb->eventGenerate('<Enter>');
   $lb->eventGenerate('<Motion>', -x => $x, -y => $y);
   $mw->update;
   my ($i) = $lb->curselection;
   is($i, $expected);   
}

sub checkSubwidgetOption 
{
   my ($cw, $name, $value, $swAR) = @_;
   if ($swAR && ref($swAR) eq "ARRAY") {
      foreach my $sw (@{$swAR}) {
         if (ref($sw) eq "ARRAY") {
            is($cw->Subwidget($sw->[0])->cget($sw->[1]),
              $value);
         }
         else {
            is($cw->Subwidget($sw)->cget($name), $value);
         }
      }
   }
}

sub checkUpDownSelection
{
   my ($jcb, $event, $index, $value) = @_;

   my $adjust = 0;
   $adjust = 1 if $event eq '<Down>';
   $adjust = -1 if $event eq '<Up>';
   $jcb->UpDown($adjust);
   is( $jcb->getSelectedIndex, $index);
   is( $jcb->getSelectedValue, $value);
}

sub getCoordFromIndex
{
   my ($listbox, $index) = @_;
   my ($x, $y, $w, $h) = $listbox->bbox($index);
   return ($x+1, $y+1);
}

sub setup
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

sub TestAutoFind
{
   my $mode = shift;
   TestAutoFindDefaults($mode);
   TestAutoFindShowPopup($mode);
   
   if ($mode eq 'editable') {
      TestAutoFindEditableSearch();
      TestAutoFindEditableSelect();
      TestAutoFindComplete(); 
   }
   elsif ($mode eq 'readonly') {
      TestAutoFindReadonlySearch();
      TestAutoFindReadonlySelect();
   }
}



sub TestAutoFindComplete
{
   eval {
      my $jcb = setup('pack',
         -autofind => {-complete => 1},
	 -choices => [qw/one two three/],
         -mode => 'editable');
      my $entry = $jcb->Subwidget('Entry');
      $entry->focusForce;

      checkListboxSelection($jcb, 'o', 0);
      is($jcb->getSelectedIndex, -1);
      is($jcb->getSelectedValue, 'o');
      is($entry->get, 'one');
      is($entry->index('sel.first'), 1);
      is($entry->index('sel.last'), 3);

      checkListboxSelection($jcb, 'n', 0);
      is($jcb->getSelectedIndex, -1);
      is($jcb->getSelectedValue, 'on');
      is($entry->get, 'one');
      is($entry->index('sel.first'), 2);
      is($entry->index('sel.last'), 3);

      $jcb->clearSelection;
      checkListboxSelection($jcb, 't', 1);
      is($jcb->getSelectedValue, 't');
      is($entry->get, 'two');
      is($entry->index('sel.first'), 1);
      is($entry->index('sel.last'), 3);

      checkListboxSelection($jcb, 'h', 2);
      is($jcb->getSelectedValue, 'th');
      is($entry->get, 'three');
      is($entry->index('sel.first'), 2);
      is($entry->index('sel.last'), 5);
      $jcb->destroy;
   };
   fail "\nFail - AutoFindComplete: " . $@ if $@;
}

sub TestAutoFindDefaults 
{
   my $mode = shift;
   eval {

      my $jcb = setup('pack',
         -mode => $mode,
         -choices => [qw/one two three/]);
      my $entry = $jcb->Subwidget('Entry');
      my $lb = $jcb->Subwidget('Listbox');
      $entry->focusForce;

      checkListboxSelection($jcb, 'o', 0);
      is($jcb->getSelectedIndex, -1, '-select is off by default'); 
      is($jcb->popupIsVisible, 1, '-showpopup is on by default');

      checkListboxSelection($jcb, 'z', undef);
      is($jcb->popupIsVisible, 0, 'popup should be withdrawn when no match');
      $jcb->destroy;
   };
   fail "\nFail - AutoFindDefaults ($mode): $@" if $@;
}
   
sub TestAutoFindEditableSearch
{
   eval {
      my $choices = [qw/tWo Four SiX eiGhT twElvE tweNtY/];
      my $jcb = setup('pack', 
         -mode => 'editable',
         -choices => $choices);
      $jcb->Subwidget('Entry')->focusForce;
      
      checkListboxSelection($jcb, 't', 0);
      checkListboxSelection($jcb, 'w', 0);
      checkListboxSelection($jcb, 'e', 4);
      checkListboxSelection($jcb, 'n', 5);

      checkListboxSelection($jcb, 'BackSpace', 4);
      checkListboxSelection($jcb, 'BackSpace', 0);
      checkListboxSelection($jcb, 'BackSpace', 0);
      checkListboxSelection($jcb, 'BackSpace', undef);  
      is($jcb->popupIsVisible, 0);
      is($jcb->getSelectedIndex, -1);
   
      $jcb->configure(-autofind => {-casesensitive => 1});
      checkListboxSelection($jcb, 't', 0);
      checkListboxSelection($jcb, 'w', 4);
      checkListboxSelection($jcb, 'e', 5);
      checkListboxSelection($jcb, 'n', undef);
      is($jcb->popupIsVisible, 0);
      $jcb->destroy;
   };
   fail "\nFail - TestAutoFindEditableSearch: $@" if $@;
}

sub TestAutoFindEditableSelect
{
   eval {
      my $jcb = setup('pack',
         -autofind => {-select => 1},
         -choices => [qw/one two three/],
         -mode => 'editable');
      $jcb->Subwidget('Entry')->focusForce;
      
      checkAutoFindSelection($jcb, 't', 1, 'two');
      checkAutoFindSelection($jcb, 'h', 2, 'three');
      checkAutoFindSelection($jcb, 'o', -1, 'tho');
      checkAutoFindSelection($jcb, 'BackSpace', 2, 'three');
      checkAutoFindSelection($jcb, 'BackSpace', 1, 'two');
      $jcb->destroy;
   };
   fail "\nFail - TestAutoFindEditableSelect: $@" if $@;
}

sub TestAutoFindReadonlySearch()
{
   eval {

      my $choices = [qw/tWo Four SiX eiGhT TeN twElvE/];
      
      ## First try it with default autofind settings
      ## which is not case senstive.
      my $jcb = setup('pack', -choices => $choices);
      $jcb->Subwidget('Entry')->focusForce;

      checkListboxSelection($jcb, 't', 0);
      checkListboxSelection($jcb, 't', 4);
      checkListboxSelection($jcb, 't', 5);
      checkListboxSelection($jcb, 't', 0); 
      $jcb->destroy;

      $jcb = setup('pack', 
         -choices => $choices,
         -autofind => { -casesensitive => 1 });
      $jcb->Subwidget('Entry')->focusForce;

      checkListboxSelection($jcb, 't', 0);
      checkListboxSelection($jcb, 't', 5);
      checkListboxSelection($jcb, 't', 0);
      checkListboxSelection($jcb, 'T', 4); 
      $jcb->destroy;
   };
   fail "\nFail - TestAutoFindReadonlySearch: $@" if $@;
}   

sub TestAutoFindReadonlySelect
{
   eval {
      my $jcb = setup('pack',
         -autofind => {-select => 1},
         -choices => [qw/one two three four/]);
      $jcb->Subwidget('Entry')->focusForce;
      
      checkAutoFindSelection($jcb, 'f', 3, 'four');
      checkAutoFindSelection($jcb, 't', 1, 'two');
      checkAutoFindSelection($jcb, 't', 2, 'three');
      checkAutoFindSelection($jcb, 't', 1, 'two');
      checkAutoFindSelection($jcb, 'o', 0, 'one');
      $jcb->destroy;
   };
   fail "\nFail - TestAutoFindReadonlySelect: $@" if $@;
}

sub TestAutoFindShowPopup
{
   my $mode = shift;

   eval {
      my $jcb = setup('pack',
         -mode => $mode,
         -autofind => { -showpopup => 1 }, 
         -choices => ['one']);
      $mw->update;
      $jcb->Subwidget('Entry')->focusForce;

      checkListboxSelection($jcb, 'o', 0);
      is($jcb->popupIsVisible, 1);
      $jcb->destroy;

      $jcb = setup('pack',
         -mode => $mode,
	 -autofind => {-showpopup => 0},
	 -choices => ['one']);
      $mw->update;
      $jcb->Subwidget('Entry')->focusForce;
  
      checkListboxSelection($jcb, 'o', 0);
      is($jcb->popupIsVisible, 0);
      $jcb->destroy;
   };
   fail "\nFail - TestAutoFindShowPopup($mode): $@" if $@;
}

###############################################
## Group of Unit Tests for -choices option
###############################################
sub TestChoices
{
   my $option = shift;
   TestConfigureChoices($option);
   TestCgetChoices($option);
}


sub TestCgetChoices
{
   eval {
      my $option = shift;
      my $jcb = setup($option, [qw/one two/]);
      my $list = $jcb->cget($option);

      is($list->[0], $jcb->getItemNameAt(0));
      is($list->[0], $jcb->getItemValueAt(0));
      is($list->[1], $jcb->getItemNameAt(1));
      is($list->[1], $jcb->getItemValueAt(1));

      $jcb->configure($option,
         [{qw/-name one -value 1/},
	  {qw/-name two -value 2 -selected 1/}]);
      $list = $jcb->cget($option);
 
      is($list->[0]->{'-name'}, $jcb->getItemNameAt(0));
      is($list->[0]->{'-value'}, $jcb->getItemValueAt(0));
      is($list->[1]->{'-name'}, $jcb->getItemNameAt(1));
      is($list->[1]->{'-value'}, $jcb->getItemValueAt(1));
   };
   fail "\nFail - TestCgetChoices: $@" if $@;
}

sub TestConfigureChoices{
   eval {
      my $option = shift;
      my $jcb = setup($option, [qw/one two/]);
      is($jcb->getItemNameAt(0), "one");
      is($jcb->getItemNameAt(1), "two");
      is($jcb->getItemValueAt(0), "one");
      is($jcb->getItemValueAt(1), "two");
      is($jcb->getSelectedIndex(), -1);

      $jcb->configure($option,
         [{-name => "three", -value => 3, -selected => 1},
	  {-name => "four",  -value => 4, -selected => 1}]);
   
      is($jcb->getItemCount, 2);
      is($jcb->getItemNameAt(0), "three");
      is($jcb->getItemNameAt(1), "four");
      is($jcb->getItemValueAt(0), 3);
      is($jcb->getItemValueAt(1), 4);
      is($jcb->getSelectedIndex(), 1);

      $jcb->configure($option,
         ["five", {-name => "six", -value => 6}]);
      $jcb->setSelectedIndex(0);

      is($jcb->getItemCount, 2);
      is($jcb->getItemNameAt(0), "five");
      is($jcb->getItemNameAt(1), "six");
      is($jcb->getItemValueAt(0), "five");
      is($jcb->getItemValueAt(1), 6);
      is($jcb->getSelectedIndex(), 0); 
      $jcb->destroy;
   };
   fail "\nFail - TestConfigureChoices: $@" if $@;
}
  
######################################################################
## Group of Unit Tests for -listhighlight option
######################################################################
sub TestListhighlight
{
   my $mode = shift;
   checkCreateGetSet($mode, -listhighlight => 0);
   TestListhighlightMotion($mode);

   ## TODO: Create additional tests to test <Enter> and <Leave>
}

######################################################################
## Tests that the Motion event has the desired effect depening on 
## what mode -listhighlight is set to.
######################################################################
sub TestListhighlightMotion
{
   my $mode = shift;
   eval {
      my $jcb = setup('pack',
         -mode => $mode,
         -choices => [qw/one two three/],
         -listhighlight => 0
      );

      my $b = $jcb->Subwidget('Button');
      my $lb = $jcb->Subwidget('Listbox');

      $b->eventGenerate('<ButtonPress-1>');
      $b->eventGenerate('<ButtonRelease-1>');
      $mw->update;

      checkMotionOnIndex($lb, 0, undef);
      checkMotionOnIndex($lb, 1, undef);
      checkMotionOnIndex($lb, 2, undef);

      $jcb->configure(-listhighlight => 1);
      checkMotionOnIndex($lb, 0, 0);
      checkMotionOnIndex($lb, 1, 1);
      checkMotionOnIndex($lb, 2, 2);
      $jcb->destroy;
   };
   fail "\nFail - TestListhighlightMotion($mode): $@" if $@;
} 

######################################################################
## Group of Unit Tests for -maxrows option
######################################################################
sub TestMaxRows
{
   eval {
      checkCreateGetSet("readonly", -maxrows => 4);
      checkCreateGetSet("editable", -maxrows => 4);

      my $jcb = setup('pack',
         -choices => [qw/one two three four five six seven eight/]);
      my $lb = $jcb->Subwidget('Listbox');
      $jcb->showPopup;
      $jcb->hidePopup;

      is($jcb->cget('-maxrows'), 10);
      is($lb->cget('-height'), 8);

      $jcb->configure(-maxrows => 2);
      is($lb->cget('-height'), 2);

      $jcb->configure(-maxrows => 9);
      is($lb->cget('-height'), 8);
      $jcb->destroy;
   };
   fail "\nFail - TestMaxRows: $@" if $@;
}

sub TestState
{
   my $mode = shift;
   my $w;

   eval {
      my $b1 = $mw->Button(-text => 'one')->pack;
      my $jcb = $mw->JComboBox(
         -entrywidth => 10,
         -mode => $mode,
	 -state => 'normal'
      )->pack;
      my $b2 = $mw->Button(-text => 'two')->pack;
      $mw->update;
      $b1->focusForce;

      $b1->focusNext;
      $w = $mw->focusCurrent;
      is(ref($w), 'Tk::Entry') if $mode eq 'editable';
      is(ref($w), 'Tk::Label') if $mode eq 'readonly';

      $w->focusNext;
      $w = $mw->focusCurrent;
      is(ref($w), 'Tk::Button');
      is($w->cget('-text'), 'two');

      $jcb->configure(-state => 'disabled');

      $b1->focusForce;
      $b1->focusNext;
      $w = $mw->focusCurrent;
      is(ref($w), 'Tk::Button');
      is($w->cget('-text'), 'two');
      foreach ($b1, $jcb, $b2) { $_->destroy; }
   };
   fail "\nFail - TestState($mode): $@" if $@;
}


sub TestUpDownSelect
{
   my $mode = shift;
   eval {
      checkCreateGetSet($mode, -updownselect => 0);

      my $jcb = setup('pack',
         -choices => [qw/one two three/],
         -mode => $mode,
         -updownselect => 1
      );
      $jcb->Subwidget('Entry')->focusForce;
      $mw->update;

      checkUpDownSelection($jcb, '<Down>', 0, 'one');
      checkUpDownSelection($jcb, '<Down>', 1, 'two');
      checkUpDownSelection($jcb, '<Down>', 2, 'three');
      checkUpDownSelection($jcb, '<Down>', 2, 'three'); 
      checkUpDownSelection($jcb, '<Up>', 1, 'two');
      checkUpDownSelection($jcb, '<Up>', 0, 'one');
      checkUpDownSelection($jcb, '<Up>', 0, 'one');  

      $jcb->configure(-updownselect => 0);
      $jcb->setSelectedIndex(1);
      is( $jcb->getSelectedIndex(), 1);
      checkUpDownSelection($jcb, '<Down>', 1, 'two'); 
      checkUpDownSelection($jcb, '<Up>', 1, 'two');   
      $jcb->destroy;
   };
   fail "\nFail - TestUpDownSelect($mode): $@" if $@;
}




__END__


















