#!/usr/bin/perl -w
# chvw.pl - example of binding callbacks to changeView events to update a secondary canvas
use strict;
use Tk;
use Tk::AbstractCanvas;
my $mwin = Tk::MainWindow->new();
my $acnv = $mwin->AbstractCanvas()->pack(-expand => 1, -fill => 'both');
my $acn2 = $mwin->AbstractCanvas()->pack(-expand => 1, -fill => 'both');
$acnv->controlNav(1); # advanced CtrlKey+MouseDrag Navigation
$acnv->rectToPoly(1);
$acnv->ovalToPoly(1);
my $rect   = $acnv->createRectangle( 7,  8, 24, 23, -fill  =>   'red');
my $oval   = $acnv->createOval(     23, 24, 32, 27, -fill  => 'green');
my $line   = $acnv->createLine(      0,  1, 31, 32, -fill  =>  'blue',
                                                    -arrow =>  'last');
my $labl   = $mwin->Label(-text => 'Hello AbstractCanvas! =)');
my $wind   = $acnv->createWindow(15, 16, -window => $labl);
$acnv->configure(-changeView => [\&changeView, $acn2]);
# viewAll if 2nd AbstractCanvas widget is resized.
$acn2->CanvasBind('<Configure>' => sub {$acn2->viewAll});
{
  my $viewBox;
  sub changeView {
    my($canvas2, @coords) = @_;
    $canvas2->delete($viewBox) if $viewBox;
    $viewBox = $canvas2->createRectangle(@coords, -outline => 'orange');
  }
}
$acnv->CanvasBind('<x>' => \&exit);
$acnv->CanvasFocus();
$acnv->viewAll();
MainLoop();
