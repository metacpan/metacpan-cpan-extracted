#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use X11::Xlib qw( KeyPress );
sub err(&) { my $code= shift; my $ret; { local $@= ''; eval { $code->() }; $ret= $@; } $ret }

plan skip_all => "No X11 Server available"
    unless $ENV{DISPLAY};
plan tests => 9;

my $dpy= new_ok( 'X11::Xlib', [], 'connect to X11' );

# This test does a lot of blocking things, so set up an alarm to use as a watchdog
$SIG{ALRM}= sub { fail("Timeout"); exit; };
alarm 5;

my ($send, $recv);
$send= X11::Xlib::XEvent->new();
is( err{ $dpy->XPutBackEvent($send); }, '', 'push null event' );
is( err{ $dpy->XNextEvent($recv); }, '', 'read event' );
is( $$send, $$recv, 'inflated events are identical' );

is( err{ $dpy->XPutBackEvent({ type => KeyPress, window => 2 }); }, '', 'push event' );
is( err{ $dpy->XNextEvent($recv); }, '', 'read event' );
is( $recv->type, KeyPress, 'correct type' );
isa_ok( $recv, 'X11::Xlib::XKeyEvent', 'correct class' );
is( $recv->window, 2, 'correct window' );

