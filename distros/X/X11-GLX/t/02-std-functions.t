#! /usr/bin/env perl
use strict;
use warnings;
use Test::More;
use X11::GLX;

plan skip_all => "No X11 Server available"
	unless defined $ENV{DISPLAY};

ok( my $dpy= X11::Xlib->new, 'X11 connection' );
ok( X11::GLX::glXQueryVersion($dpy, my ($major, $minor)), 'glXQueryVersion' );
ok( $major > 0 && $minor >= 0, 'returned version' );
note "GLX Version $major.$minor";

ok( my $ext= X11::GLX::glXQueryExtensionsString($dpy), 'glxQueryExtensionsString' );
note "GLX Extensions: $ext";

done_testing;
