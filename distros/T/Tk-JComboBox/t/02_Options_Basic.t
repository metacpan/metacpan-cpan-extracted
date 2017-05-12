#! /usr/local/bin/perl

#################################################################
## Name: 02_Options_Basic.t
## 
## Purpose: Tests all Basic operations - those that implement
##  "standard" Tk options, or redefine them. There are a few 
##  additional ones that configure the appearance of the combobox.
##
## Tested Options: (also tests -mode)
##  -arrowbitmap
##  -arrowimage
##  -background
##  -borderwidth 
##  -cursor
##  -entrybackground
##  -entrywidth
##  -font
##  -foreground
##  -gap
##  -highlightcolor
##  -highlightbackground
##  -listwidth
##  -pady
##  -selectbackground
##  -selectforeground
##  -selectborderwidth
##  -takefocus
##  -textvariable
##
## NOTE: When creating new tests, be careful not to create a new 
## MainWindow for each Test. I find that it tends to interfere 
## with event generation (if you generate events for tests). 
## Creating a Test subroutine for each test tends to make it 
## easier to comment out tests or move them between modules. Also 
## it makes it easier to police variable use, so that a variable 
## used in one test does not inadvertantly affect another.
################################################################
use Carp;
use strict;

use Tk;
use Tk::Font;
use Tk::JComboBox;
use Test::More tests => 205;

my $mw = MainWindow->new();

my $fontName = "Fixed";
$fontName = "Arial" if $Tk::platform =~ /Win32/;

####################################################
## Appearance-related Options
####################################################

#####################
## -arrowbitmap (2)
#####################
diag "\n\nTest arrowbitmap:\n";
TestArrowbitmap('editable');
TestArrowbitmap('readonly');

#####################
## -arrowimage (3)
#####################
diag "\nTest arrowimage\n";
TestArrowimage('editable');
TestArrowimage('readonly');

#####################
## -background 
#####################
diag "\nTest background\n";
checkDescendantsTest("editable", -background => 'gray');
checkDescendantsTest("readonly", -background => 'gray');

#####################
## -borderwidth
#####################
diag "\nTest borderwidth:\n";
checkDefaultValue(-borderwidth => 2);
checkCreateGetSet("editable", -borderwidth => 5, ['Frame']);
checkCreateGetSet("readonly", -borderwidth => 5, ['Frame']);

#####################
## -cursor
#####################
diag "\nTest cursor:\n";
checkDescendantsTest("editable", -cursor => 'left_ptr');
checkDescendantsTest("readonly", -cursor => 'left_ptr');

#####################
## -entrybackground
#####################
diag "\nTest entrybackground:\n";
checkCreateGetSet('editable',
   -entrybackground => 'blue', 
   [[Entry => '-background'],
    [Listbox => '-background']]);

checkCreateGetSet('readonly',
   -entrybackground => 'blue',
   [[Entry => '-background'],
    [Button => '-background'],
    [Listbox => '-background']]);

#####################
## -entrywidth
#####################
diag "\nTest entrywidth:\n";
checkDefaultValue(-entrywidth => -1);
checkCreateGetSet('editable', -entrywidth => 5, [[Entry => '-width']]);
checkCreateGetSet('readonly', -entrywidth => 5, [[Entry => '-width']]);

#####################
## -font
#####################

## Commented out for the time being -- this is simply too big a pain
## to use for different Operating systems. I need to rethink how I 
## test this before I start using it again.

#diag "\nTest font:\n";
#TestFont('editable');
#TestFont('readonly');

#####################
## -foreground
#####################
diag "\nTest foreground:\n";
checkCreateGetSet("editable",
   -foreground => 'red', [qw/Entry Listbox/]);
checkCreateGetSet("readonly",
   -foreground => 'red', [qw/Entry Listbox/]);

#####################
## -gap
#####################
diag "\nTest gap:\n";
checkDefaultValue(-gap => 0);
checkCreateGetSet("editable", -gap => 2);
checkCreateGetSet("readonly", -gap => 2);

#####################
## -highlightthickness
#####################
diag "\nTest highlightthickness:\n";
checkDefaultValue(-highlightthickness => 0);
checkCreateGetSet("editable", -highlightthickness => 2, ['Frame']);
checkCreateGetSet("readonly", -highlightthickness => 2, ['Frame']);

#####################
## -highlightcolor and
## -highlightbackground
#####################
diag "\nTest highlight:\n";
TestHighlight('editable');
TestHighlight('readonly');

#####################
## -listwidth
#####################
diag "\nTest listwidth:\n";
checkDefaultValue(-listwidth => -1);
TestListwidth('editable');
TestListwidth('readonly');

#####################
## -pady
#####################
diag "\nTest pady:\n";
TestPadY('editable');
TestPadY('readonly');

#####################
## -relief
#####################
diag "\nTest relief:\n";
TestRelief("editable", "sunken");
TestRelief("readonly", "groove");

#####################
## -selectbackground
#####################
diag "\nTest selectbackground:\n";
checkCreateGetSet('editable', 
   -selectbackground => 'gray', 
   [qw/Entry Listbox/]);

checkCreateGetSet('readonly',
   -selectbackground => 'blue',
   ['Listbox']);

#####################
## -selectforeground
#####################
diag "\nTest selectforeground:\n";
checkCreateGetSet('editable', 
   -selectforeground => 'gray', 
   [qw/Entry Listbox/]);

checkCreateGetSet('readonly',
   -selectforeground => 'blue',
  ['Listbox']);

#####################
## -selectborderwidth
#####################
diag "\nTest selectborderwidth:\n";
checkCreateGetSet('editable', 
   -selectborderwidth => 4, 
   [qw/Entry Listbox/]);

checkCreateGetSet('readonly',
   -selectborderwidth => 4,
   ['Listbox']);

#####################
## -takefocus
#####################   
diag "\nTest takefocus:\n";
TestTakeFocus('readonly');
TestTakeFocus('editable');

#####################
## -textvariable
#####################
diag "\nTest TextVariable:\n";
TestTextVar("editable");
TestTextVar("readonly");










#TestTextVariable('readonly');
#TestTextVariable('editable');

## CleanUp
$mw->destroy;

############################################################
## Test Subroutines
############################################################

sub checkCreateGetSet 
{
   my ($mode, $name, $value, $swAR) = @_;
   eval {
      my $w = Setup(-mode => $mode, $name, $value);
      is($w->cget($name), $value);
      checkSubwidgetOption($w, $name, $value, $swAR);	
      $w->destroy;

      $w = Setup(-mode => $mode);
      $w->configure($name, $value);
      is($w->cget($name), $value);
      checkSubwidgetOption($w, $name, $value, $swAR);
      $w->destroy;
   };
   diag "\nFail - checkCreateGetSet($mode,$name,$value): $@" if $@;
}

sub checkDescendantsForOption
{
   my ($jcb, $name, $value) = @_;
   my $unexpectedOption = 0;
   eval {
      foreach my $w ($jcb->Descendants) {
	 $unexpectedOption++ if ($w->cget($name) ne $value);
      }
   };
   diag "\nFail - checkDescendantsForOption($name,$value): $@" if $@;
   return $unexpectedOption;
}

sub checkDescendantsTest
{
   my ($mode, $name, $value) = @_;
   eval {
      ## create
      my $jcb = Setup(-mode => $mode, $name, $value);
      is(checkDescendantsForOption($jcb, $name, $value), 0);

      ## configure method
      $jcb = $mw->JComboBox(-mode => $mode);
      $jcb->configure($name, $value);
      is(checkDescendantsForOption($jcb, $name, $value), 0);
      $jcb->destroy;
      checkCreateGetSet($mode, $name => $value);
   };
   diag "\nFail - checkDescendantsTest($name,$value): $@" if $@;
}

sub checkDefaultValue
{
   my ($option, $value, $mode) = @_;
   eval {
      my $jcb;
      if ($mode) { $jcb = Setup(-mode => $mode); }
      else       { $jcb = Setup(); }
      is($jcb->cget($option), $value);
      $jcb->destroy;
   };
   diag "\nFail - checkDefaultValue($option,$value,$mode): $@" if $@;
   
}

sub checkFont
{
   my ($w, $font) = @_;
   eval {
      my $wFont = $w->cget('-font');
      is($wFont->configure('-family'), $font->configure('-family'));
      is($wFont->configure('-size'),   $font->configure('-size'));
   };
   diag "Fail - checkFont: $@" if $@;      
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

sub FocusTraverse
{
   my ($main, $currentFocus) = @_;
   if (!defined($currentFocus)) {
      $main->eventGenerate('<Tab>');
      $currentFocus = $main->focusCurrent;
   }
   else {
      $currentFocus->eventGenerate('<Tab>');
      $currentFocus = $main->focusCurrent;
   }
   return $currentFocus;
}

sub Setup
{
   my $pack = 0;
   if (@_ && $_[0] eq "pack") {
      shift @_;
      $pack = 1;
    }
   my $jcb = $mw->JComboBox(@_);
   if ($pack)
   {
      $jcb->pack;
      $mw->update;
   }
   return $jcb;
}

sub TestArrowbitmap
{
   my $mode = shift;
   eval {
      my $bitmap = "test-$mode";
      my $bits = pack("b9"x4,
         "....1....",
         "...111...",
         "..11111..",
         ".1111111.");
      $mw->DefineBitmap($bitmap,9,4,$bits);
 
      my $jcb = Setup(-mode => $mode, -arrowbitmap => $bitmap);
      is( $jcb->Subwidget('Button')->cget('-bitmap'), $bitmap);
      $jcb->destroy;

      $jcb = Setup(-mode => $mode);
      $jcb->configure(-arrowbitmap => $bitmap);
      is( $jcb->Subwidget('Button')->cget('-bitmap'), $bitmap);
      $jcb->destroy;
   };
   diag "\nFail - TestArrowBitmap($mode): $@" if $@;
}

sub TestArrowimage
{
   my $mode = shift;
   eval {
      my $image = $mw->Photo("button",
         -format => "gif", 
         -file => "t/button.gif"
      );
      
      my $jcb = $mw->JComboBox(-mode => $mode, -arrowimage => $image);
      is( $jcb->Subwidget('Button')->cget('-image'),
	  $jcb->cget('-arrowimage'));
      $jcb->destroy;

      $jcb = $mw->JComboBox(-mode => $mode);
      is( $jcb->cget('-arrowimage'), undef); 
      $jcb->configure(-arrowimage => $image);
      is( $jcb->Subwidget('Button')->cget('-image'),
	  $jcb->cget('-arrowimage'));

      $image->delete;
      $jcb->destroy;
   };
   diag "\nFail - TestArrowImage($mode): $@" if $@;
}

sub TestFont
{
   my $mode = shift;
   eval {
      my $main = MainWindow->new;

      my $font = $main->Font(
        -family => $fontName,
        -size => 20
      );
      my $jcb = $main->JComboBox(
         -mode => $mode,
         -font => $font
      );
      checkFont($jcb, $font);
      checkFont($jcb->Subwidget('Listbox'), $font);
      checkFont($jcb->Subwidget('Entry'), $font);
      $jcb->destroy;

      $jcb = $main->JComboBox(-mode => $mode);
      $jcb->configure(-font => $font);
      checkFont($jcb, $font);
      checkFont($jcb->Subwidget('Entry'), $font);
      checkFont($jcb->Subwidget('Listbox'), $font);
      $main->destroy;
   };
   diag "\nFail - TestFont($mode): $@" if $@;
}

sub TestHighlight
{
   my $mode = shift;
   eval {
      checkCreateGetSet($mode, -highlightcolor => 'red', ['Frame']);
      checkCreateGetSet($mode, -highlightbackground => 'blue', ['Frame']);

      my $jcb = Setup("pack",
         -mode => $mode,
         -highlightthickness => 5,
         -highlightcolor => 'red',
         -highlightbackground => 'blue'
      );
      my $frame = $jcb->Subwidget('Frame');

      $jcb->Focus("In");
      $mw->update;
      is( $frame->cget('-highlightcolor'), 'blue');
      is( $frame->cget('-highlightbackground'), 'red');
      $jcb->destroy;
   };
   diag "\nFail - TestHighlight($mode): $@" if $@;
}

sub TestListwidth
{
   my $mode = shift;
   my $choices = [qw/one two three four five/];
   
   eval {
      ## -listwidth (-1)
      my $jcb = Setup("pack",
         -mode => $mode,
         -choices => $choices,
         -listwidth => -1
      );
      my $popup = $jcb->Subwidget('Popup');
      my $listbox = $jcb->Subwidget('Listbox');
   
      $jcb->showPopup;
      $mw->update;
      is($jcb->width, $popup->width);
      $jcb->hidePopup;

      ## -listwidth (0)
      $jcb->configure(-listwidth => 0);
      $jcb->showPopup;
      $mw->update;
      my $expectedWidth = $listbox->width + $popup->cget('-bd') * 2;
      is($popup->width, $expectedWidth);
      $jcb->hidePopup;

      ## -listwidth (4)
      $jcb->configure(-listwidth => 4);
      $jcb->showPopup;
      $mw->update;
      $expectedWidth = $listbox->width + $popup->cget('-bd') * 2;
      is($popup->width, $expectedWidth);
      $jcb->hidePopup;
      $jcb->destroy;
   };
   diag "\nFail - TestListWidth($mode): $@" if $@;
}

sub TestPadY
{
   my $mode = shift;
   eval {
      checkCreateGetSet($mode, -pady => 2);

      my $jcb = Setup(qw/pack -mode/, $mode);
      $jcb->configure(-pady => 5);
      my %gridInfo = $jcb->Subwidget('Button')->gridInfo;
      is( $gridInfo{'-ipady'}, 5);
      $jcb->destroy;
   };
   diag "\nFail - TestPadY($mode): $@" if $@;
}

sub TestRelief 
{
   my ($mode, $relief) = @_;
   eval {
      checkDefaultValue(-relief => $relief, $mode);
      checkCreateGetSet($mode, -relief => $relief, ['Frame']);
   };
   diag "\nFail - TestRelief($mode): $@" if $@;
}

sub TestTakeFocus
{
   my $mode = shift;
   my $result;

   eval {
      checkCreateGetSet($mode, -takefocus => 0, ['Entry']);
   
      ## With takefocus set to 1, focus should go to the (ext) Button,
      ## The Entry subwidget, and then to the next (ext) Button.
      my $b1 = $mw->Button(-text => "one")->pack;
      my $jcb = Setup("pack", -mode => $mode, -takefocus => 1);
      my $b2 = $mw->Button(-text => 'two')->pack;
      $mw->focus;
      $mw->update;

      ## Verify initial focus
      $b1->focusForce;
      my $currentFocus = $mw->focusCurrent;

      is(ref($currentFocus), 'Tk::Button');
      is($currentFocus->cget('-text'), 'one');

      ## Verify that subwidget gets focus
      $result = 'Tk::Label' if $mode eq 'readonly';
      $result = 'Tk::Entry' if $mode eq 'editable';
      $currentFocus = FocusTraverse($mw, $currentFocus);
      is(ref($currentFocus), $result);

      $currentFocus = FocusTraverse($mw, $currentFocus);
      is(ref($currentFocus), 'Tk::Button');
      is($currentFocus->cget('-text'), 'two');

      ## Now with takefocus set to 0, focus should skip the
      ## the Entry subwidget, and go from one ext Button to the
      ## other.
      $jcb->configure(-takefocus => 0);
      $currentFocus = FocusTraverse($mw, $currentFocus);
      is(ref($currentFocus), 'Tk::Button');
      is($currentFocus->cget('-text'), 'one');

      $currentFocus = FocusTraverse($mw, $currentFocus);
      is(ref($currentFocus), 'Tk::Button');
      is($currentFocus->cget('-text'), 'two');
      foreach my $w ($jcb, $b1, $b2) { $w->destroy; }
   };
   diag "\nFail - TestTakeFocus($mode): $@" if $@;
}

sub TestTextVar
{
   my $mode = shift;

   my $test;
   my $jcb = Setup(
      -mode => $mode,
      -choices => [qw/one two three/, {-name => 'four', -value => 4}],
      -textvariable => \$test
   );
   is($test, "");
   $jcb->setSelectedIndex(0);
   is($test, 'one');
   $jcb->setSelectedIndex(1);
   is($test, 'two');
   $jcb->setSelectedIndex(2);
   is($test, 'three');
   $jcb->setSelectedIndex(3);
   is($test, 4);

   $test = "one";
   is(0, $jcb->getSelectedIndex());
   $test = "two";
   is(1, $jcb->getSelectedIndex());
   $test = "three";
   is(2, $jcb->getSelectedIndex());
   $test = 4;
   is(3, $jcb->getSelectedIndex());
   is("four", $jcb->DisplayedName());
   $jcb->clearSelection;
   
   $test = "five";
   if ($mode eq "editable") {
      is("five", $jcb->DisplayedName());
   }
   else {
      is("", $jcb->DisplayedName());
   }
   $jcb->destroy;
}
	







