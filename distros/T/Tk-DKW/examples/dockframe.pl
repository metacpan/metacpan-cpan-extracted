#! /usr/bin/perl

package Main;

use Tk::DockFrame;
use Tk;

my $l_MainWindow = Tk::MainWindow->new();
my $l_Counter = 0;

my @l_DockPort =
  (
   $l_MainWindow->DockPort()->pack ('-fill' => 'x', '-side' => 'top', '-anchor' => 'nw'),
   $l_MainWindow->DockPort()->pack ('-fill' => 'x', '-side' => 'top', '-anchor' => 'nw'),
   $l_MainWindow->DockPort()->pack ('-fill' => 'x', '-side' => 'top', '-anchor' => 'nw'),
   $l_MainWindow->DockPort()->pack ('-fill' => 'x', '-side' => 'bottom', '-anchor' => 'sw'),
  );

my $l_Text = $l_MainWindow->Text ('-background' => 'white')->pack ('-fill' => 'both', '-side' => 'top');

foreach my $l_Caption ('Dock Frame 1', 'Dock Frame 2', 'Dock Frame 3', 'Dock Frame 4')
   {
    my $l_Dockable = $l_MainWindow->DockFrame ($l_Counter <= $#l_DockPort ? ('-dock' => $l_DockPort [$l_Counter++]) : ());

    my $l_Label = $l_Dockable->Label ('-text' => $l_Caption);

    $l_Label->pack
       (
        '-expand' => 'true',
        '-fill' => 'both',
        '-side' => 'right',
        '-anchor' => 'nw',
       );
   }

Tk::MainLoop();
