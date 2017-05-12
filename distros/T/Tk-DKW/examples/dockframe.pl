#! /usr/bin/perl

package Main;

use Tk::DockFrame;
use Tk;

my $l_MainWindow = Tk::MainWindow->new();
my $l_Text = $l_MainWindow->Text ('-background' => 'white');
my $l_Counter = 0;
my @l_DockPort;

for (my $l_Index = 0; $l_Index < 3; ++$l_Index)
   {
    push (@l_DockPort, $l_MainWindow->DockPort());
    $l_Text->pack (-expand => 'true', -fill => 'both', '-side' => 'top') if ($l_Index == 2);
    $l_DockPort [$#l_DockPort]->pack (-expand => 'false', '-fill' => 'x');
   }

foreach my $l_Text ('This is a very long test string', 'This is a test', 'This is really nothing', 'Drag me')
   {
    my $l_Dockable = $l_MainWindow->DockFrame ($l_Counter <= $#l_DockPort ? ('-dock' => $l_DockPort [$l_Counter++]) : ());

    my $l_Label = $l_Dockable->Label ('-text' => $l_Text);

    $l_Label->pack
       (
        '-expand' => 'true',
        '-fill' => 'both',
        '-side' => 'right',
        '-anchor' => 'nw',
       );
   }

Tk::MainLoop();
