#!/usr/local/bin/perl -w
use Tk;
use lib './blib/lib'; use Tk::LCD;
use Tk::widgets qw//;
use strict;

my $mw = MainWindow->new;

my $l = $mw->Label->pack;

my $frog;
my $lcd = $mw->LCD(-elements => 11, -variable => \$frog)->pack;

$l->configure(-text => 'Large Numbers');
$lcd->set(-1234567890);
$mw->update; $mw->after(5000);

$lcd->configure(qw/
    -elements   15
    -background white 
    -onoutline  blue
    -onfill     blue
    -offoutline white
    -offfill    white
    -size       small
/);
$l->configure(-text => 'Small Numbers, Commified');
$frog = 1_234_567_890.31415;
$mw->update; $mw->after(5000);

$lcd->configure(-elements => 4, -commify => 0);
$l->configure(-text => 'Small Numbers, Not Commified');
$frog = 2003;

MainLoop;
