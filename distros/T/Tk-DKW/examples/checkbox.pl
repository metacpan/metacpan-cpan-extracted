#! /usr/bin/perl

use Tk::CheckBox;
use Tk;

my $l_MainWindow = MainWindow->new();

my $l_CheckBox = $l_MainWindow->CheckBox
   (
    '-bg' => 'white',
    '-fg' => 'blue',
   );

$l_CheckBox->pack();

Tk::MainLoop();
