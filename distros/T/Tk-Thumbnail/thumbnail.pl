#!/usr/local/bin/perl -w
use Tk;
use lib './blib/lib'; use Tk::Thumbnail;
use strict;

my $mw = MainWindow->new;

my $thumb = $mw->Thumbnail( -images => [ <images/*> ] );

$thumb->pack( qw/ -fill both -expand 1 / );
$thumb->update;
$thumb->after(2000);

my $pot = $mw->Photo( -file => Tk->findINC( 'demos/images/teapot.ppm' ) );
$thumb->configure(
    -images => [ 'images/Apple_guy.gif', $pot, 'images/Astronaut1.gif' ],
    -bd     => 2, 
    -relief => 'solid',
);
$mw->Label( -text => 'Press an Apple or an Astronaut, please.' ) ->pack;

MainLoop;
