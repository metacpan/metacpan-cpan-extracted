#!/usr/bin/perl

use Tk::SplitFrame;
use Tk;

my $l_Main = MainWindow->new();

my $l_MainWindow = $l_Main->Frame();

$l_MainWindow->pack
   (
    '-fill' => 'both',
    '-expand' => 'true',
    '-padx' => 4,
    '-pady' => 4
   );

my $l_SplitFrame = $l_MainWindow->SplitFrame
   (
    '-padbefore' => 22,
    '-padafter' => 62,
    '-orientation' => 'vertical',
    '-sliderposition' => 120,
   );

$l_SplitFrame->Label
   (
    '-borderwidth' => 2,
    '-background' => 'blue',
    '-foreground' => 'yellow',
    '-text' => 'Left',
   );

my $l_SplitFrame2 = $l_SplitFrame->SplitFrame
   (
    '-orientation' => 'horizontal',
   );

$l_SplitFrame2->Label
   (
    '-borderwidth' => 2,
    '-background' => 'white',
    '-foreground' => 'purple',
    '-text' => 'Top'
   );

$l_SplitFrame2->Label
   (
    '-borderwidth' => 2,
    '-background' => 'white',
    '-text' => 'Bottom'
   );

$l_SplitFrame->pack
   (
    '-expand' => 'true',
    '-fill' => 'both',
   );

Tk::MainLoop;