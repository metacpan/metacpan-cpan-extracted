#!/usr/bin/perl -w
# demo.pl - example demonstrating the basic functionality of an AbstractCanvas
use strict;
use Tk;
use Tk::AbstractCanvas;
my $mwin = Tk::MainWindow->new();
my $acnv = $mwin->AbstractCanvas()->pack(-expand => 1, -fill  =>  'both');
$acnv->controlNav(1); # advanced CtrlKey+MouseDrag Navigation
$acnv->rectToPoly(1);
my $rect   = $acnv->createRectangle( 7,  8, 24, 23, -fill  =>   'red');
my $oval   = $acnv->createOval(     23, 24, 32, 27, -fill  => 'green');
my $line   = $acnv->createLine(      0,  1, 31, 32, -fill  =>  'blue',
                                                    -arrow =>  'last');
my $labl   = $mwin->Label(-text => 'Hello AbstractCanvas! =)');
my $wind   = $acnv->createWindow(15, 16, -window => $labl);
$acnv->CanvasBind('<Button-1>' => sub { $acnv->zoom(1.1 ); } );
$acnv->CanvasBind('<Button-2>' => sub {
  $acnv->rotate($rect,  5);
  $acnv->rotate($wind,  5); # this rot should do nothing because
  $acnv->rotate($oval, -5); #      can't rotate about own center
  $acnv->rotate($line, -5);
});
$acnv->CanvasBind('<Button-3>' => sub { $acnv->zoom(0.91); });
$acnv->CanvasBind(       '<x>' => \&exit);
$acnv->CanvasFocus();
$acnv->viewAll();
MainLoop();
