#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use X11::Xlib ':fn_screen';
sub err(&) { my $code= shift; my $ret; { local $@= ''; eval { $code->() }; $ret= $@; } $ret }

plan skip_all => "No X11 Server available"
    unless $ENV{DISPLAY};
plan tests => 10;

my $dpy= new_ok( 'X11::Xlib', [], 'connect to X11' );

ok( ScreenCount($dpy)     > 0, 'screen count' );
ok( RootWindow($dpy)      > 0, 'root window'  );
ok( DefaultColormap($dpy) > 0, 'default colormap' );
ok( DefaultDepth($dpy)    > 0, 'default depth' );
ok( DefaultVisual($dpy)   > 0, 'default visual' );
ok( DisplayWidth($dpy)    > 0, 'display width' );
ok( DisplayHeight($dpy)   > 0, 'display height' );
ok( DisplayWidthMM($dpy)  > 0, 'display width MM' );
ok( DisplayHeightMM($dpy) > 0, 'display height MM' );
