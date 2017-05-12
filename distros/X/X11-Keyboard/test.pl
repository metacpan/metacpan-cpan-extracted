#!/usr/bin/perl

#	test suite

use Test::Simple tests => 8;

use X11::Protocol;
$x = X11::Protocol->new();
ok(defined $x && $x->isa('X11::Protocol'), "connection established");

use X11::Keyboard;
ok(1, 'use X11::Keyboard');

$k = X11::Keyboard->new($x);
ok(defined $k && $k->isa('X11::Keyboard'), "component instantiated");

$keysym = $k->StringToKeysym("plus");
ok($keysym, "string converted");
$keycode = $k->KeysymToKeycode($keysym);
ok($keycode, "keycode generated");
@keycode = $k->KeysymToKeycode($keysym);
ok($keycode[1], "state generated");

# or, more simply
$keycode2 = $k->KeysymToKeycode("plus");

ok($keycode == $keycode2 && $keycode == $keycode[0], "keycode translation");
ok(1, "done");
