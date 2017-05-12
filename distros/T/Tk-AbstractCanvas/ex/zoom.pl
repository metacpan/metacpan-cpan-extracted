#!/usr/bin/perl -w
# zoom.pl - example of binding several simple zoom In && Out callbacks
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
$acnv->CanvasBind(        '<i>' => sub {$acnv->zoom(1.03)});
$acnv->CanvasBind(        '<I>' => sub {$acnv->zoom(1.1 )});
$acnv->CanvasBind('<Control-i>' => sub {$acnv->zoom(1.25); print "c0^i\n"});
$acnv->CanvasBind('<Control-I>' => sub {$acnv->zoom(1.9 )});
$acnv->CanvasBind(        '<o>' => sub {$acnv->zoom(0.97)});
$acnv->CanvasBind(        '<O>' => sub {$acnv->zoom(0.91)});
$acnv->CanvasBind('<Control-o>' => sub {$acnv->zoom(0.8 )});
$acnv->CanvasBind('<Control-O>' => sub {$acnv->zoom(0.53)});
$acnv->CanvasBind(        '<x>' => \&exit);
$acnv->CanvasFocus(); # when Canvas has focus, it responds to events 1st, then MainWindow 2nd
$mwin->bind(      '<Control-i>' => sub {                   print "m1^i\n"});
$mwin->bind(      '<Control-x>' => \&exit);
$acnv->viewAll();
MainLoop();
