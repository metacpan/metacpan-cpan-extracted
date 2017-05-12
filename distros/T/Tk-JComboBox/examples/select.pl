#######################################################################
## select.pl
## This example is intended to demonstrate different ways in which 
## someone might Get information on the selected JComboBox item. 
## It was posted in response to bdz (bdalzell [at] qis.net) in a 
## question posted to c.l.p.tk on 5 Oct 06:
## http://groups.google.com/group/comp.lang.perl.tk/msg/8740780bb62f1bba?hl=en&
########################################################################
use strict;
use Tk; 
use Tk::JComboBox; 

my $mw = MainWindow->new; 
my $variable; 
my $done; 
my $jcb = $mw->JComboBox( 
   -choices => [qw/Black Blue Green Purple Red Yellow/], 
   -textvariable => \$variable, 
   -selectcommand => \&SelectCommand 
)->pack; 
my $button = $mw->Button( 
   -text => "Submit", 
   -command => \&Submit 
)->pack; 

$mw->waitVariable(\$done); 
print "change choices\n"; 

$button->configure(-bg => 'blue', -fg => 'white'); 
$mw->update; 
$jcb->configure(-choices => [ 
   { -name => 'Black',  -value => '#000000' }, 
   { -name => 'Blue',   -value => '#0000ff' }, 
   { -name => 'Green',  -value => '#008000' }, 
   { -name => 'Purple', -value => '#8000ff' }, 
   { -name => 'Red',    -value => '#ff0000' }, 
   { -name => 'Yellow', -value => '#ffff00' } 
]); 

$mw->waitVariable(\$done); 
print "Bye!\n"; 

sub Submit { 
   print "\nSubmit Called\n"; 
   my $index = $jcb->getSelectedIndex(); 
   print "Index: $index \n"; 
   print "value: " . $jcb->getSelectedValue() . "\n"; 
   print "name:  " . $jcb->getItemNameAt($index) . "\n"; 
   print "textvariable: $variable \n"; 
   $done = "done"; 
} 

sub SelectCommand { 
   my ($jcb, $selIndex, $selValue, $selName) = @_; 
   print "\nSelectCommand called\n"; 
   print "Index: $selIndex\n"; 
   print "Value: $selValue\n"; 
   print "Name: $selName\n"; 
} 
