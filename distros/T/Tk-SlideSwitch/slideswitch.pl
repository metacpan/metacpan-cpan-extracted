#!/usr/local/bin/perl -w
use Tk;
use lib './blib/lib'; use Tk::SlideSwitch;
use Tk::widgets qw//;
use strict;

my $mw = MainWindow->new;

my $sl = $mw->SlideSwitch(
    -bg          => 'gray',
    -orient      => 'horizontal',
    -command     => sub {print "args=@_\n"},
    -llabel      => [-text => 'OFF', -foreground => 'blue'],
    -rlabel      => [-text => 'ON',  -foreground => 'blue'],
    -troughcolor => 'tan',
)->pack(qw/-side left -expand 1/);

MainLoop;
