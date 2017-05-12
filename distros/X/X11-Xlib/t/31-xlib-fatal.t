#!/usr/bin/env perl

use strict;
use warnings;
use Scalar::Util 'isweak';
use IO::Handle;
use Test::More;

plan skip_all => "No X11 Server available"
    unless $ENV{DISPLAY};
plan tests => 20;

sub err(&) { my $code= shift; my $ret; { local $@= ''; eval { $code->() }; $ret= $@; } $ret }

use X11::Xlib qw( XOpenDisplay ConnectionNumber );

my $conn;
is( err{ $conn= XOpenDisplay(); }, '', 'connected' );
isa_ok( $conn, 'X11::Xlib', 'display connection' );

my $conn2= XOpenDisplay();
my $conn3= XOpenDisplay();

is( scalar keys %X11::Xlib::_connections, 3, 'three registered connections' );

ok( !$X11::Xlib::_error_fatal_installed,    'fatal handler not installed' );
ok( !$X11::Xlib::_error_fatal_trapped,      'no fatal error' );

X11::Xlib->on_error(sub {
    my ($dpy, $event)= @_;
    unless ($event) {
        note("begin global Fatal error handler");
        
        is( $dpy, $conn, 'received same connection object' );
        
        like( err{ $conn->XSync }, qr/fatal/, 'can\'t use dead connection' );
        ok( defined $conn->_pointer_value, 'dead connection still has pointer value' );
        
        is( err{ $conn2->XSync }, '', 'can still use other connections, right now' );

        note("end fatal error handler");
    }
});
$conn->on_error(sub {
    my ($dpy, $event)= @_;
    unless ($event) {
        note("begin connection Fatal error handler");
        is( $dpy, $conn, 'received same connection object' );
    }
});

ok( $X11::Xlib::_error_fatal_installed,     'fatal handler installed' );

ok( $conn->DisplayWidth > 0, 'can call X11 functions' );
ok( !$X11::Xlib::_error_fatal_trapped,      'no fatal error' );

# shutdown the X11 socket to trigger a fatal error
note("Interrupting X11 connection to simulate lost server");
my $x= IO::Handle->new_from_fd(ConnectionNumber($conn), 'w+')
    or die;
shutdown($x, 2);

ok( !$X11::Xlib::_error_fatal_trapped,      'no fatal error' );

# Now trigger the error
like( err{ $conn->XNextEvent(my $event) }, qr/fatal/i, 'X activity triggers fatal error' );

ok( $X11::Xlib::_error_fatal_trapped,       'fatal error flagged' );

# Now every connection should be dead
like( err{ $conn->XSync  }, qr/fatal/i, 'conn1 dead' );
like( err{ $conn2->XSync }, qr/fatal/i, 'conn2 dead' );
like( err{ $conn3->XSync }, qr/fatal/i, 'conn3 dead' );
like( err{ XOpenDisplay  }, qr/fatal/i, 'XOpenDisplay disabled' );
