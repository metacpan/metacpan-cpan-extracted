#!/usr/bin/perl -w
# scrl.pl - example of binding callbacks on a Scrolled AbstractCanvas
use strict;
use Tk;
use Tk::AbstractCanvas;
my $mwin = Tk::MainWindow->new();
# If you are using the 'Scrolled' constructor as in:
my $acnv = $mwin->Scrolled('AbstractCanvas', -scrollbars => 'ose')->pack(-expand => 1, -fill  =>  'both');
#   you want to bind the key-presses to the 'AbstractCanvas' Subwidget of Scrolled.
my $scrolled_canvas = $acnv->Subwidget('abstractcanvas'); # note the lowercase
$acnv->controlNav(1); # advanced CtrlKey+MouseDrag Navigation
$acnv->rectToPoly(1);
$acnv->ovalToPoly(1);
my $rect   = $acnv->createRectangle( 7,  8, 24, 23, -fill  =>   'red');
my $oval   = $acnv->createOval(     23, 24, 32, 27, -fill  => 'green');
my $line   = $acnv->createLine(      0,  1, 31, 32, -fill  =>  'blue',
                                                    -arrow =>  'last');
my $labl   = $mwin->Label(-text => 'Hello AbstractCanvas! =)');
my $wind   = $acnv->createWindow(15, 16, -window => $labl);
$scrolled_canvas->CanvasBind('<i>' => sub {$scrolled_canvas->zoom(1.1 )});
$scrolled_canvas->CanvasBind('<o>' => sub {$scrolled_canvas->zoom(0.91)});
# if you don't like the scrollbars taking the focus when you <ctrl>-tab through the windows, you can:
$acnv->Subwidget('xscrollbar')->configure(-takefocus => 0);
$acnv->Subwidget('yscrollbar')->configure(-takefocus => 0);
# Centers the display around abstract coordinates x, y.  Example:
$acnv->CanvasBind('<2>' => sub {
  $acnv->CanvasFocus();
  $acnv->center($acnv->eventLocation());
});
$acnv->CanvasBind('<x>' => \&exit);
$acnv->CanvasFocus();
$acnv->viewAll();
MainLoop();
