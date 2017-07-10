#!/usr/bin/perl
use strict;use warnings;
use        Tk;
use        Tk::AbstractCanvas;
my $mwin = Tk::MainWindow->new();
my $acnv = $mwin->AbstractCanvas()->pack('-expand' => 1,
                                                    '-fill'  =>  'both');
#$acnv->invertY(   1); # uncomment for inverted Y-axis
 $acnv->controlNav(1); # advanced CtrlKey+MouseDrag Navigation
 $acnv->rectToPoly(1);
#$acnv->ovalToPoly(1); # uncomment for oval to rot8 with canvas
my $rect   = $acnv->createRectangle( 7,  8, 24, 23, '-fill'  =>   'red');
my $oval   = $acnv->createOval(     23, 24, 32, 27, '-fill'  => 'green');
my $line   = $acnv->createLine(      0,  1, 31, 32, '-fill'  =>  'blue',
                                                    '-arrow' =>  'last');
my $labl   = $mwin->Label('-text'  => 'Hello AbstractCanvas! =)');
my $wind   = $acnv->createWindow(15, 16, '-window' => $labl     );
$acnv->CanvasBind('<Button-1>' => sub { $acnv->zoom(1.04); });
$acnv->CanvasBind('<Button-3>' => sub { $acnv->zoom(0.97); });
$acnv->CanvasBind('<Button-2>' => sub {
  $acnv->rotate($rect,  5);
  $acnv->rotate($wind,  5); # this rot8 should do nothing because
  $acnv->rotate($oval, -5); #   window can't go around own center
  $acnv->rotate($line, -5);                                });
$acnv->viewAll();
MainLoop();                 # ... then click the 3 mouse buttons
