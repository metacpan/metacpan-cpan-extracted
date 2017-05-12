#! /bin/perl
######################################################################
## This is a simple example of a JComboBox in editable mode. This
## was taken from the tutorial that comes packaged with the module.
######################################################################

use strict;
use Tk;
use Tk::JComboBox;

my $mw = MainWindow->new;
my $jcb = $mw->JComboBox(
   -entrybackground => 'white',
   -mode => 'editable',
   -relief => 'sunken',
   -choices => [qw/Black Blue Green Purple Red Yellow/],
)->pack;

MainLoop;
