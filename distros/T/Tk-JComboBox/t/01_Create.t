#! /usr/bin/perl

use diagnostics;
use strict;
use Carp;

use Tk;
use Tk::JComboBox;
use Test::More tests => 31;

BEGIN {   use_ok('Tk::JComboBox') };

#########################

my $mw = MainWindow->new;
my $jcb;

## Check to ensure that an instance can be created
eval { $jcb = $mw->JComboBox->pack; };
is( ref($jcb), "Tk::JComboBox",    "Created new Object");

## Check Inheritance Structure
isa_ok($jcb, 'Tk::JComboBox', "Test object identity");
isa_ok($jcb, 'Tk::CWidget',   "Test inheritance from CWidget");
isa_ok($jcb, 'Tk::Frame',     "Test inheritance from Tk::Frame");
isa_ok($jcb, 'Tk::Derived',   "Test inheritance from Tk::Derived");
isa_ok($jcb, 'Tk::Widget',    "Test inheritance from Tk::Widget");


############################################################
## Mode Checks
############################################################

## Check the default mode
is( $jcb->cget(-mode), "readonly", "Check Default Mode" );
$jcb->destroy;

## Check that invalid mode fails
$jcb = checkMode("bad", 0, 'Test Expected to fail for invalid -mode value');

###############################
## Readonly Mode
###############################

## Check that valid readonly mode is accepted
$jcb = checkMode("readonly", 1, 'Test for setting readonly mode');
is ($jcb->cget('-mode'), 'readonly', 'Test that readonly mode was configured');

## Check that default relief for readonly is correct
is ($jcb->Subwidget('Frame')->cget(-relief), 'groove', 
	"Test default relief for readonly mode");

## Ensure that the mode can not be reconfigured
$jcb->configure(-mode => 'editable');
is ($jcb->cget('-mode'), 'readonly', 'Test that readonly mode was unchanged');

## Ensure that all subwidgets are present
checkSubwidgets($jcb, "Tk::Label");

ok ($jcb->Subwidget('RO_Entry') == $jcb->Subwidget('Entry'), 
   "Check that Entry is the same as RO_Entry");
ok ($jcb->Subwidget('RO_Button') == $jcb->Subwidget('Button'),
   "Check that RO_Button is the same as Button");

###############################
## Editable Mode
###############################

## Check that valid editable mode is accepted
$jcb = checkMode("editable", 1, 'Test for setting editable mode');
is ($jcb->cget('-mode'), 'editable', 'test that editable mode was configured');

## Check that default relief for editable mode is correct
is ($jcb->Subwidget('Frame')->cget('-relief'), 'sunken', 
      	"Test default relief for editable mode");

## Ensure that the mode can not be reconfigured
$jcb->configure(-mode => 'readonly');
is ($jcb->cget(-mode), 'editable', 'Test that editable mode unchanged');

checkSubwidgets($jcb, "Tk::Entry");

ok ($jcb->Subwidget('ED_Entry') == $jcb->Subwidget('Entry'), 
   "Check that Entry is the same as ED_Entry");
ok ($jcb->Subwidget('ED_Button') == $jcb->Subwidget('Button'),
   "Check that Button is the same as ED_Button");

############################################################
## Test Subroutines
############################################################

sub checkMode 
{
   my ($mode, $successExpected, $testName) = @_;
   my $jcb;
   my $invalidMode = 0;
   eval    { $jcb = $mw->JComboBox(-mode => $mode); };
   if ($@) { $invalidMode = 1; }
   if (($successExpected && $invalidMode == 1) ||
       (!$successExpected && $invalidMode == 0))
   {
      fail($testName);
   }
   else
   {
      pass($testName);
   }
   return $jcb;
}

sub checkSubwidgets 
{
   my ($jcb, $boxWidget) = @_;
   is (ref($jcb->Subwidget('Entry')), $boxWidget, 
	"Entry is a $boxWidget");
   is (ref($jcb->Subwidget('Frame')), "Tk::Frame", 
	"Frame is a Tk::Frame");
   is (ref($jcb->Subwidget('Button')), "Tk::Label", 
	"Button is a Tk::Label");
   is (ref($jcb->Subwidget('Popup')), "Tk::Toplevel", 
	"Popup isa Tk::Toplevel");
   is (ref($jcb->Subwidget('Listbox')), "Tk::Listbox");
}
   





 





 



