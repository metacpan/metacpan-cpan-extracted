#! /usr/bin/perl

use Tk::CornerBox;
use Tk;

my $l_MainWindow = MainWindow->new();

my $l_Corner = $l_MainWindow->CornerBox()->place
   (
    '-width' => 20,
    '-height' => 20,
    '-relx' => 1,
    '-rely' => 1,
    '-anchor' => 'se',
    '-x' => -3,
    '-y' => -3,
   );

Tk::MainLoop();