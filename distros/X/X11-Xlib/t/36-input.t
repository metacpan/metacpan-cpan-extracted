#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use X11::Xlib ':all';
sub err(&) { my $code= shift; my $ret; { local $@= ''; eval { $code->() }; $ret= $@; } $ret }

plan skip_all => "No X11 Server available"
    unless $ENV{DISPLAY};
plan tests => 2;

my $dpy= new_ok( 'X11::Xlib', [], 'connect to X11' );

subtest XQueryPointer => sub {
    my @ret= XQueryPointer($dpy, RootWindow($dpy));
    is( scalar @ret, 7, 'Return as list' );
    @ret= XQueryPointer($dpy, RootWindow($dpy), my $root, my $child, my $rx, my $ry, my $wx, my $wy, my $mask);
    is( scalar @ret, 1, 'Return boolean when passed out-params' );
    ok( $ret[0], 'is true' );
    ok( defined $root, 'root defined' );
    ok( defined $rx, 'root_x defined' );
    ok( defined $ry, 'root_y defined' );
    ok( defined $mask, 'mask defined' );
};
