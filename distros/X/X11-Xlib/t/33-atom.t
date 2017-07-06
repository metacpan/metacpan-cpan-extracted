#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use X11::Xlib qw( KeyPress );
sub err(&) { my $code= shift; my $ret; { local $@= ''; eval { $code->() }; $ret= $@; } $ret }

plan skip_all => "No X11 Server available"
    unless $ENV{DISPLAY};
plan tests => 14;

my $dpy= new_ok( 'X11::Xlib', [], 'connect to X11' );
$dpy->on_error(sub { my ($dpy, $err)= @_; note $err->summarize; }); # ignore non-fatal errors

ok( (my $a_utf8= $dpy->XInternAtom('UTF8_STRING', 0) ), 'get atom UTF8_STRING' );
is( $dpy->XGetAtomName($a_utf8), 'UTF8_STRING', 'get name UTF8_STRING' );
ok( !$dpy->XInternAtom("SomeTokenThatProbablyDoesn'tExist", 1), 'nonexistent name returns false' );
ok( !$dpy->XGetAtomName(0x12345678), 'nonexistent atom returns false' );

ok( (my $a_netwmname= $dpy->XInternAtom('_NET_WM_NAME', 0) ), 'get atom _NET_WM_NAME' );

# now test multiple at once
ok( (my $atoms= $dpy->XInternAtoms([ 'UTF8_STRING', '_NET_WM_NAME' ], 0)), 'XInternAtoms (known)' );
is_deeply( $atoms, [ $a_utf8, $a_netwmname ], 'got both atoms' );

ok( (my $names= $dpy->XGetAtomNames([ $a_utf8, $a_netwmname ])), 'XGetAtomNames (known)' );
is_deeply( $names, [ 'UTF8_STRING', '_NET_WM_NAME' ], 'got both names' );

# now test what happens when half don't exist
ok( ($atoms= $dpy->XInternAtoms([ 'UTF8_STRING', "SomeTokenThatProbablyDoesn'tExist" ], 1)), 'XInternAtoms (half known)' );
is_deeply( $atoms, [ $a_utf8, 0 ], 'got one atom' );

ok( ($names= $dpy->XGetAtomNames([ 0x12345678, $a_netwmname ])), 'XGetAtomNames (half known)' );
is_deeply( $names, [ undef, '_NET_WM_NAME' ], 'got one name' );

