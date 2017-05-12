#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use X11::Xlib qw( :all );
sub err(&) { my $code= shift; my $ret; { local $@= ''; eval { $code->() }; $ret= $@; } $ret }

plan skip_all => "No X11 Server available"
    unless $ENV{DISPLAY};
plan tests => 7;

my $dpy= new_ok( 'X11::Xlib', [], 'connect to X11' );

my $s= $dpy->screen;
ok( (my $pmap= $dpy->new_pixmap($s->root_window, 128, 128, $s->visual_info->depth)), 'XCreatePixmap' );
is( $pmap->width, 128, 'width' );
is( $pmap->height, 128, 'height' );
is( $pmap->depth, $s->visual_info->depth, 'depth' );
is_deeply( [$pmap->get_w_h], [128,128], 'get_w_h' );
$dpy->XSync;
is(err{ $dpy->XFreePixmap($pmap) }, '', 'XFreePixmap' );
# prevent double destruction
$pmap->autofree(0);
