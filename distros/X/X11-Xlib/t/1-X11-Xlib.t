#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 10;

BEGIN { use_ok('X11::Xlib') };

is(XKeysymToString(0x61), 'a', "Can get string from keysym");
is(XStringToKeysym('a'), 0x61, "Can get keysym from string");

SKIP: {
    skip "No X11 Server", 7 unless $ENV{DISPLAY};
    
    ok(my $display = X11::Xlib->new, "Can get display");
    ok($display->DisplayWidth(0), "Can get display width");
    ok($display->DisplayHeight(0), "Can get display height");

    # We can't really test here because of keyboard
    # data changes
    my @keysym = $display->XGetKeyboardMapping(54);
    ok(@keysym, "can get the keyboard mapping");

    ok(my $rootwindow = $display->RootWindow(0), "Can get root window");
    isa_ok($rootwindow, 'X11::Xlib::Window');
    ok($rootwindow->id, "Can get window id");
}
