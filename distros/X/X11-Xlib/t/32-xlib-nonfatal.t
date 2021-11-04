#!/usr/bin/env perl

use strict;
use warnings;
use Scalar::Util 'isweak';
use IO::Handle;
use Test::More;

plan skip_all => "No X11 Server available"
    unless $ENV{DISPLAY};
plan tests => 12;

use X11::Xlib qw( XOpenDisplay ConnectionNumber RootWindow );

my $conn;
sub err(&) { my $code= shift; my $ret; { local $@= ''; eval { $code->() }; $conn->XSync(); $ret= $@; } $ret }
is( err{ $conn= XOpenDisplay(); }, '', 'connected' );
isa_ok( $conn, 'X11::Xlib', 'display connection' );
my $root= RootWindow($conn);

my $conn2= XOpenDisplay();
is( scalar X11::Xlib->_all_connections, 2, 'two registered connections' );

ok( !$X11::Xlib::_error_nonfatal_installed,    'handler not installed' );

X11::Xlib->on_error(sub {
    my ($dpy, $event)= @_;
    if ($event) {
        note("begin global error handler");
        
        is( $dpy, $conn, 'received same connection object' );

        note("end fatal error handler");
    }
});
$conn->on_error(sub {
    my ($dpy, $event)= @_;
    if ($event) {
        note("begin connection error handler");
        is( $dpy, $conn, 'received same connection object' );
        is( $event->type, 0, 'event is type 0' );
        is( $event->resourceid, 0x1234567, 'mentions non-existent window ID' );
        like( $conn->XGetErrorText($event->error_code), qr/Bad/, 'error_code name' );
        like( $conn->XGetErrorDatabaseText("XProtoError", $event->error_code), qr/Bad/, 'error_code string' );
        like( $conn->XGetErrorDatabaseText('XRequest', $event->request_code), qr/QueryTree/, 'major code string' );
        note explain $event->summarize;
    }
});

ok( $X11::Xlib::_error_nonfatal_installed,  'nonfatal handler installed' );

# Cause a nonfatal error by un-mapping the root
$conn->XQueryTree(0x1234567);
$conn->XSync;

