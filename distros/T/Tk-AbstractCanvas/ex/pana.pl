#!/usr/bin/perl -w
# pana.pl - example of binding arrow keys to pan on abstract coordinates instead of default widget coords
use strict;
use Tk;
use Tk::AbstractCanvas;
my $mwin = Tk::MainWindow->new();
my $acnv = $mwin->AbstractCanvas()->pack(-expand => 1, -fill => 'both');
$acnv->controlNav(1); # advanced CtrlKey+MouseDrag Navigation
$acnv->rectToPoly(1);
$acnv->ovalToPoly(1);
my $rect   = $acnv->createRectangle( 7,  8, 24, 23, -fill  =>   'red');
my $oval   = $acnv->createOval(     23, 24, 32, 27, -fill  => 'green');
my $line   = $acnv->createLine(      0,  1, 31, 32, -fill  =>  'blue',
                                                    -arrow =>  'last');
my $labl   = $mwin->Label(-text => 'Hello AbstractCanvas! =)');
my $wind   = $acnv->createWindow(15, 16, -window => $labl);
# the following two lines seem to be different ways of accomplishing the same thing (if they were uncommented):
#$mwin->      bind($acnv, '<Right>' => sub {$acnv->panAbstract(-15, 0)});
#$acnv->CanvasBind(       '<Right>' => sub {$acnv->panAbstract(-15, 0)});
my @sect   = ( split //, '000000' );
if($sect[0]){
$mwin->      bind(   '<Up>' =>                               '');
$mwin->      bind( '<Down>' =>                               '');
$mwin->      bind( '<Left>' =>                               '');
$mwin->      bind('<Right>' =>                               '');
}
if($sect[1]){
$acnv->CanvasBind(   '<Up>' =>                               '');
$acnv->CanvasBind( '<Down>' =>                               '');
$acnv->CanvasBind( '<Left>' =>                               '');
$acnv->CanvasBind('<Right>' =>                               '');
}
if($sect[2]){
$mwin->      bind(   '<Up>' => sub {$acnv->panAbstract(0,  5 )});
$mwin->      bind( '<Down>' => sub {$acnv->panAbstract(0, -5 )});
$mwin->      bind( '<Left>' => sub {$acnv->panAbstract( 5 , 0)});
$mwin->      bind('<Right>' => sub {$acnv->panAbstract(-5 , 0)});
}
if($sect[3]){
$acnv->CanvasBind(   '<Up>' => sub {$acnv->panAbstract(0, -30)});
$acnv->CanvasBind( '<Down>' => sub {$acnv->panAbstract(0,  30)});
$acnv->CanvasBind( '<Left>' => sub {$acnv->panAbstract(-30, 0)});
$acnv->CanvasBind('<Right>' => sub {$acnv->panAbstract( 30, 0)});
}
if($sect[4]){
$mwin->      bind(   '<Up>' =>                               '');
$mwin->      bind( '<Down>' =>                               '');
$mwin->      bind( '<Left>' =>                               '');
$mwin->      bind('<Right>' =>                               '');
}
if($sect[5]){
$acnv->CanvasBind(   '<Up>' =>                               '');
$acnv->CanvasBind( '<Down>' =>                               '');
$acnv->CanvasBind( '<Left>' =>                               '');
$acnv->CanvasBind('<Right>' =>                               '');
}
$acnv->CanvasBind(  '<x>' => \&exit);
$acnv->CanvasFocus();
$mwin->bind('<Control-x>' => \&exit);
$acnv->viewAll();
MainLoop();
