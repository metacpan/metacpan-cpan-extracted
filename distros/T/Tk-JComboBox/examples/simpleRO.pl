#! /bin/perl
######################################################################
## This is a simple example of a JComboBox in readonly (the default) 
## mode. This was taken from the tutorial that comes packaged with the 
## module.
######################################################################

use strict;
use Tk;
use Tk::JComboBox;

my $mw = MainWindow->new;
my $jcb = $mw->JComboBox(
   -choices => [qw/Black Blue Green Purple Red Yellow/],
)->pack;

MainLoop;
