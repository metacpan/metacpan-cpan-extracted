#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use X11::Xlib qw( :fn_win :const_win :const_winattr :const_sizehint :const_event_mask RootWindow XSync None Success );

plan skip_all => "No X11 Server available"
    unless $ENV{DISPLAY};

my $dpy= new_ok( 'X11::Xlib', [], 'connect to X11' );

sub err(&) { my $code= shift; my $ret; { local $@= ''; eval { $code->() }; XSync($dpy); $ret= $@; } $ret }

my @args= ($dpy, RootWindow($dpy), 0, 0, 50, 50, 0,
    $dpy->DefaultDepth, InputOutput, $dpy->DefaultVisual,
    0, {});
my $win_id;
is( err{ $win_id= XCreateWindow(@args) }, '', 'CreateWindow' )
    or diag explain \@args;
ok( $win_id > 0, 'got window id' );

my ($netwmname, $type_utf8, $wm_proto, $wm_dest_win)
    = @{ $dpy->XInternAtoms([qw( _NET_WM_NAME UTF8_STRING WM_PROTOCOLS WM_DESTROY_WINDOW )], 0) };

# Window managers (or something) can auto-assign properties, according to CPAN testers
my @initial_properties= XListProperties($dpy, $win_id);
note "unexpected initial window properties: ".join(', ', @initial_properties)
    if @initial_properties;
#is_deeply( [ XListProperties($dpy, $win_id) ], [], 'no window properties yet' );
XChangeProperty($dpy, $win_id, $netwmname, $type_utf8, 8, PropModeReplace, "Hello World", 11);
is( scalar(grep { $_ eq $netwmname } XListProperties($dpy, $win_id)), 1, 'window has title property' );
ok( Success == XGetWindowProperty($dpy, $win_id, $netwmname, 0, 32, 0, $type_utf8,
    my $actual_type, my $actual_format, my $n, my $remaining, my $data), 'XGetWindowProperty' );
is( $actual_type, $type_utf8, 'correct type' );
is( $actual_format, 8, 'correct format' );
is( $n, 11, '11 bytes' );
is( $remaining, 0, 'no missing bytes' );
is( $data, 'Hello World', 'correct string' );
XDeleteProperty($dpy, $win_id, $netwmname);
is( scalar(grep { $_ == $netwmname } XListProperties($dpy, $win_id)), 0, 'deleted title property' );

# Now check OO interface
my $win= $dpy->get_cached_window($win_id);
$win->set_property($netwmname, $type_utf8, "HelloAgain");
is( scalar(grep { $_ eq $netwmname } $win->get_property_list), 1, 'new window title' );
is_deeply( $win->get_property($netwmname)->{data}, "HelloAgain", 'correct title text' );
$win->set_property($netwmname, undef);
is( scalar(grep { $_ eq $netwmname } $win->get_property_list), 0, 'unset window title' );

ok( XSetWMProtocols($dpy, $win_id, [ $wm_dest_win ]), 'XSetWMProtocols' );
is( scalar(grep { $_ eq $wm_proto } $win->get_property_list), 1, 'protocols set' );
is_deeply( [ XGetWMProtocols($dpy, $win_id) ], [ $wm_dest_win ], 'with expected values' );

is( err{ XMapWindow($dpy, $win_id); }, '', 'XMapWindow' );
$dpy->XSync;

my ($root, $x, $y, $w, $h, $b, $d);
is( err{ ($root, $x, $y, $w, $h, $b, $d)= XGetGeometry($dpy, $win_id) }, '', 'XGetGeometry' );
is( $root, RootWindow($dpy), 'correct root window' );
ok( defined $x, 'got x' );
ok( defined $y, 'got y' );
ok( defined $w, 'got w' );
ok( defined $h, 'got h' );
ok( defined $b, 'got border' );
ok( defined $d, 'got depth' );

my ($size_hints_in, $size_hints_out, $supplied);
$size_hints_in= { min_width => 100, min_height => 50, max_width => 200, max_height => 100, flags => PMinSize | PMaxSize };
is( err{ XSetWMNormalHints($dpy, $win_id, $size_hints_in) }, '', 'Set WM hints' );

is( err{ XGetWMNormalHints($dpy, $win_id, $size_hints_out, $supplied) }, '', 'Get WM hints' );
ok( $supplied & PMinSize, 'received min_size set' );
ok( $supplied & PMaxSize, 'received max_size set' );
is( $size_hints_out->min_width, 100, 'min_width matches' );
is( $size_hints_out->max_width, 200, 'max_width matches' );
is( $size_hints_out->min_height, 50, 'min_height matches' );
is( $size_hints_out->max_height, 100, 'max_height matches' );

my $attrs;
is( err{ XGetWindowAttributes($dpy, $win_id, $attrs) }, '', 'XGetWindowAttributes' );
is( $attrs->root, $root, 'wndattr->root' );

# Create 3 child windows to play with
my @cwnd= map { XCreateSimpleWindow($dpy, $win_id, 0, 0, 50, 50) } 0..2;
XMapWindow($dpy, $_) for @cwnd;

is( err{ XRestackWindows($dpy, [ reverse @cwnd ]) }, '', 'XRestackWindows' ); # back-to-front

my ($root2, $parent, @children)= XQueryTree($dpy, $win_id);
is( $root2,  $root, 'XQueryTree - root' );
# is( $parent, $root, 'XQueryTree - parent' ); can't verify
is_deeply( \@children, \@cwnd, 'XQueryTree - children' );

# Call a bunch of functions to see if any throw an error.
# TODO: actually verify the behavior of these calls
is( err{ XGetGeometry($dpy, $cwnd[0]) }, '', 'XGetGeometry' );
is( err{ XChangeWindowAttributes($dpy, $cwnd[0], CWSaveUnder, { save_under => 1 }) }, '', 'XChangeWindowAttributes' );
is( err{ XSetWindowBackground($dpy, $cwnd[0], 1) }, '', 'XSetWindowBackground' );
is( err{ XSetWindowBackgroundPixmap($dpy, $cwnd[0], None) }, '', 'XSetWindowBackgroundPixmap' );
is( err{ XSetWindowBorder($dpy, $cwnd[0], 1) }, '', 'XSetWindowBorder' );
is( err{ XSetWindowBorderPixmap($dpy, $cwnd[0], None) }, '', 'XSetWindowBorderPixmap' );
is( err{ XSetWindowColormap($dpy, $cwnd[0], None) }, '', 'XSetWindowColormap' );
is( err{ XDefineCursor($dpy, $cwnd[0], None) }, '', 'XDefineCursor' );
is( err{ XUndefineCursor($dpy, $cwnd[0]) }, '', 'XUndefineCursor' );
is( err{ XConfigureWindow($dpy, $cwnd[0], CWHeight, { height => 49 }) }, '', 'XConfigureWindow' );
is( err{ XMoveWindow($dpy, $cwnd[0], 1, 1) }, '', 'XMoveWindow' );
is( err{ XResizeWindow($dpy, $cwnd[0], 48, 48) }, '', 'XResizeWindow' );
is( err{ XMoveResizeWindow($dpy, $cwnd[0], 0, 0, 50, 50) }, '', 'XMoveResizeWindow' );
is( err{ XSetWindowBorderWidth($dpy, $cwnd[0], 1) }, '', 'XSetWindowBorderWidth' );
is( err{ XRaiseWindow($dpy, $cwnd[0]) }, '', 'XRaiseWindow' );
is( err{ XLowerWindow($dpy, $cwnd[1]) }, '', 'XLowerWindow' );
is( err{ XCirculateSubwindows($dpy, $cwnd[0], RaiseLowest) }, '', 'XCirculateSubwindows' );
is( err{ XCirculateSubwindows($dpy, $cwnd[2], LowerHighest) }, '', 'XCirculateSubwindows' );
is( err{ XRestackWindows($dpy, \@cwnd) }, '', 'XRestackWindows' );

XUnmapWindow($dpy, $_) for @cwnd;
XDestroyWindow($dpy, $_) for @cwnd;

($w, $h)= $dpy->root_window->get_w_h;
ok( $w > 0, '$wnd->get_w_h; w > 0' );
ok( $h > 0, '$wnd->get_w_h; h > 0' );

ok( ($attrs= $dpy->root_window->attributes), '$wnd->attributes' );
is( $dpy->root_window->event_mask, $attrs->your_event_mask, '$wnd->event_mask' );
$dpy->root_window->event_mask(ExposureMask);
$dpy->root_window->clear_all;
is( $dpy->root_window->event_mask, ExposureMask, 'event_mask set to ExposureMask' );
$dpy->root_window->event_mask_include(KeyPressMask);
$dpy->root_window->clear_all;
is( $dpy->root_window->event_mask, (ExposureMask|KeyPressMask), 'event_mask set to ExposureMask|KeyPressMask' );
$dpy->root_window->event_mask_exclude(ExposureMask);
$dpy->root_window->clear_all;
is( $dpy->root_window->event_mask, KeyPressMask, 'event_mask set to KeyPressMask' );

is( err{ XUnmapWindow($dpy, $win_id); }, '', 'XUnmapWindow' );

is( err{ XDestroyWindow($dpy, $win_id); }, '', 'XDestroyWindow' );

done_testing;
