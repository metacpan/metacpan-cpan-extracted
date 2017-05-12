#! /usr/bin/perl 
## 05_Methods -- Test JComboBox Methods

use diagnostics;
use strict;

use Tk;
use Tk::JComboBox;
use Test::More tests => 130;

my $mw = MainWindow->new;
my $jcb = $mw->JComboBox;

####################################################
## Test for existance of documented methods 
####################################################
diag "\n\nTest existance of public methods\n";
can_ok($jcb,
   'addItem',
   'clearSelection',
   'getItemCount', 
   'getItemIndex',
   'getItemNameAt',
   'getItemValueAt',
   'getSelectedIndex',
   'getSelectedValue',
   'hidePopup',
   'index',
   'insertItemAt',
   'popupIsVisible',
   'removeAllItems',
   'removeItemAt',
   'see',
   'setSelected',
   'setSelectedIndex',
   'showPopup',
);

############################################################
## Adding New Items
############################################################  
diag "\nTesting Add Functionality:\n";

$jcb = setupTest();
is( $jcb->getItemCount, 0);
checkSelection($jcb, -1, "", "");

$jcb->addItem('Alaska', -value=> 'AK', -selected => 'true');
is( $jcb->getItemCount, 1);
checkNameValue($jcb, 0, "Alaska", "AK");
checkSelection($jcb, 0, "Alaska", "AK");

$jcb->addItem('Maryland', -value => 'MD');
is( $jcb->getItemCount, 2);
checkNameValue($jcb, 1, "Maryland", "MD" );
checkSelection($jcb, 0, "Alaska", "AK" );  

$jcb->addItem('DC', -selected => 1);
is( $jcb->getItemCount, 3);
checkNameValue($jcb, 2, "DC", "DC");
checkSelection($jcb, 2, "DC", "DC");

$jcb->insertItemAt(2, "Virginia", -value => "VA");
is( $jcb->getItemCount, 4);
checkNameValue($jcb, 2, "Virginia", "VA");
checkNameValue($jcb, 3, "DC", "DC");
checkSelection($jcb, 3, "DC", "DC");

############################################################
## Removing Items
############################################################
diag "\nTesting Remove Functionality:\n";

is( $jcb->getItemCount, 4);
$jcb->removeItemAt(0);
is( $jcb->getItemCount, 3);
checkNameValue($jcb, 0, "Maryland", "MD");
checkSelection($jcb, 2, "DC", "DC");


$jcb->removeItemAt('last');
is( $jcb->getItemCount, 2);
checkNameValue($jcb, 'last', "Virginia", "VA");
checkSelection($jcb, -1, "", "");

$jcb->removeAllItems();
is( $jcb->getItemCount, 0);
checkSelection($jcb, -1, "", "");
$jcb->destroy;

############################################################
## Popup-related
############################################################
diag "\nTest Popup-related methods:\n";

$jcb = $mw->JComboBox(-choices => [qw/one/])->pack;
$mw->update;

is( $jcb->popupIsVisible, "0");

$jcb->showPopup;
$mw->update;
is( $jcb->popupIsVisible, "1");
   
$jcb->hidePopup;
is( $jcb->popupIsVisible, "0");
$jcb->destroy;

############################################################
## Selection-related
############################################################
diag "\nTest Selection-related methods:\n";
my $value = "Rob";

$jcb = setupTest("readonly");
checkSelection($jcb, -1, "", "");
$jcb->Subwidget('Entry')->configure(-text => $value);
checkSelection($jcb, -1, $value, $value);
$jcb->clearSelection;
checkSelection($jcb, -1, "", "");

$jcb = setupTest("editable");
checkSelection($jcb, -1, "", "");
$jcb->Subwidget('Entry')->insert(0, $value);
checkSelection($jcb, -1, $value, $value);
$jcb->clearSelection;
checkSelection($jcb, -1, "", "");

$jcb->addItem("Entry1", -value => "value1");
checkSelection($jcb, -1, "", "");
$jcb->setSelectedIndex(0);
checkSelection($jcb, 0, "Entry1", "value1");

$jcb->addItem("Entry2", -selected => 1);
$jcb->addItem("entry3", -value=> "value3");

checkSelection($jcb, 1, "Entry2", "Entry2");

$jcb->setSelected("Entry1");
is( $jcb->getSelectedIndex, 0);

$jcb->setSelected("value3", -type => "value");
is( $jcb->getSelectedIndex, 2);

############################################################
## Index-related methods
############################################################
diag "\nTest Index-related methods:\n";
$jcb = $mw->JComboBox(
  -choices => [qw/one two three four five six seven eight/]
);
$jcb->setSelectedIndex(1);

is( $jcb->index('end'),     $jcb->getItemCount );
is( $jcb->index('last'),    $jcb->getItemCount - 1 );
is( $jcb->index('selected'),$jcb->getSelectedIndex );
is( $jcb->index(3), 3);
is( $jcb->getItemIndex("t", -type => 'name', -mode => 'usecase'), 1);
is( $jcb->getItemIndex("T", -type => 'name', -mode => 'ignorecase'), 1);
is( $jcb->getItemIndex("fi", -mode => 'usecase'), 4);
is( $jcb->getItemIndex("seven"), 6);

$jcb->addItem("nine", -value => 9);
is( $jcb->getItemIndex("9", -type => 'value'), 8);


############################################################
## Test Subroutines
############################################################


sub setupTest 
{
   my $mode = shift || "readonly";
   my $jcb = $mw->JComboBox(-mode => $mode);
   return $jcb;
}

sub checkNameValue 
{
   my ($jcb, $index, $name, $value) = @_;
   is( $jcb->Subwidget('Listbox')->get($jcb->index($index)), $name);
   is( $jcb->getItemNameAt($index), $name, 'checkNameValue/getItemNameAt' );
   is( $jcb->getItemValueAt($index), $value, 'checkNameValue/getItemValueAt' );
}  


sub checkSelection 
{
   my ($jcb, $index, $name, $value) = @_;
   is( $jcb->getSelectedIndex, $index ,          "getSelectedIndex");
   is( $jcb->getItemNameAt('selected'), $name,   "getItemNameAt");
   is( $jcb->getItemValueAt('selected'), $value, "getItemValueAt");
   is( $jcb->getSelectedValue(), $value,         "getSelectedValue" );

   $index = undef if $index < 0;
   my ($selection) = $jcb->Subwidget('Listbox')->curselection;
   is( $selection, $index);
}
