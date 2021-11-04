#!/usr/bin/env perl

use strict;
use warnings;
use Scalar::Util 'isweak';
use IO::Handle;
use Test::More;

plan skip_all => "No X11 Server available"
    unless $ENV{DISPLAY};
plan tests => 17;

sub err(&) { my $code= shift; my $ret; { local $@= ''; eval { $code->() }; $ret= $@; } $ret }

use_ok('X11::Xlib') or BAIL_OUT;

my $conn= X11::Xlib::XOpenDisplay();
isa_ok( $conn, 'X11::Xlib', 'new connection' );
note 'connected to '.X11::Xlib::XDisplayName();

my $pointer1= $conn->_pointer_value;
ok( defined $pointer1,     'pointer defined' );
is( ref $pointer1, '',     'is a plain scalar' );
ok( length $pointer1 > 3,  'valid length' );
ok( exists $X11::Xlib::_obj_cache{$pointer1}, 'registered' );
is( $X11::Xlib::_obj_cache{$pointer1}, $conn, 'as the right object' );
ok( isweak($X11::Xlib::_obj_cache{$pointer1}), 'and is weakref' );

my $conn2= X11::Xlib::XOpenDisplay();
isa_ok( $conn, 'X11::Xlib', 'new connection' );
my $pointer2= $conn2->_pointer_value;
ok( $pointer2 ne $pointer1, 'distinct pointer' );
is( scalar X11::Xlib->_all_connections, 2, 'two registered connections' );

X11::Xlib::XCloseDisplay($conn2);
# Display* has been freed, so address could get re-used, so it must become un-registered.
ok( $conn2, 'conn2 still defined' );
is( $conn2->_pointer_value, undef, 'conn2 internal pointer is NULL' );
is( scalar X11::Xlib->_all_connections, 1, 'one registered connection' );

my $fd= $conn->ConnectionNumber;
$conn->_mark_dead;
is( scalar X11::Xlib->_all_connections, 1, 'dead, but still registered' );
like( err{ X11::Xlib::XCloseDisplay($conn) }, qr/connection/i, 'accessing dead connection throws error' );
undef $conn;
is( scalar X11::Xlib->_all_connections, 0, 'all unregistered' );
# clean up
IO::Handle->new_from_fd($fd, 'r+')->close;
