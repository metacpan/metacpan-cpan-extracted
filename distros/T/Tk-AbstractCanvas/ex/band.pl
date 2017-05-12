#!/usr/bin/perl -w
# band.pl - example of binding callbacks to make a rubberBand to delete fully enclosed contents
use strict;
use Tk;
use Tk::AbstractCanvas;
my $mwin = Tk::MainWindow->new();
my $acnv = $mwin->AbstractCanvas()->pack(-expand => 1, -fill  => 'both');
$acnv->controlNav(1); # advanced CtrlKey+MouseDrag Navigation
$acnv->rectToPoly(1);
$acnv->ovalToPoly(1);
my $rect   = $acnv->createRectangle( 7,  8, 24, 23, -fill  =>   'red');
my $oval   = $acnv->createOval(     23, 24, 32, 27, -fill  => 'green');
my $line   = $acnv->createLine(      0,  1, 31, 32, -fill  =>  'blue',
                                                    -arrow =>  'last');
my $labl   = $mwin->Label(-text => 'Hello AbstractCanvas! =)');
my $wind   = $acnv->createWindow(15, 16, -window => $labl);
$acnv->configure(-bandColor => 'purple');
$acnv->CanvasBind('<3>'               => sub {$acnv->CanvasFocus();
                                              $acnv->rubberBand(0)});
$acnv->CanvasBind('<B3-Motion>'       => sub {$acnv->rubberBand(1)}); # B3-Motion
# Note: Using '<B3-ButtonRelease>' below would cause callbacks for any ButtonRelease!
#   Use '<ButtonRelease-3>' instead, to limit calls to the single desired button.
$acnv->CanvasBind('<ButtonRelease-3>' => sub {
                               my      @box = $acnv->rubberBand(2);
                               my      @ids = $acnv->find('enclosed', @box);
                           for my $id (@ids) {$acnv->delete($id)} });
# If you want the rubber band to look smooth during key-driven panning && zooming,
#   add rubberBand(1) update calls to the appropriate key-bindings:
$acnv->CanvasBind(   '<Up>' => sub {                   $acnv->rubberBand(1)});
$acnv->CanvasBind( '<Down>' => sub {                   $acnv->rubberBand(1)});
$acnv->CanvasBind( '<Left>' => sub {                   $acnv->rubberBand(1)});
$acnv->CanvasBind('<Right>' => sub {                   $acnv->rubberBand(1)});
$acnv->CanvasBind(    '<i>' => sub {$acnv->zoom(1.1 ); $acnv->rubberBand(1)});
$acnv->CanvasBind(    '<o>' => sub {$acnv->zoom(0.91); $acnv->rubberBand(1)});
$acnv->CanvasBind(    '<b>' => sub {                   $acnv->rubberBand(0)});
$acnv->CanvasBind(    '<e>' => sub {                   $acnv->rubberBand(2)});
$acnv->CanvasBind(    '<x>' => \&exit);
$acnv->CanvasFocus();
$acnv->viewAll();
MainLoop();
