#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 10;

use_ok('X11::Xlib::XRectangle') or die;
sub err(&) { my $code= shift; my $ret; { local $@= ''; eval { $code->() }; $ret= $@; } $ret }

# Create a new XEvent
my $struct= new_ok( 'X11::Xlib::XRectangle', [], 'blank' );
ok( defined $struct->buffer, 'buffer is defined' );
ok( length($struct->buffer) > 0, 'and has non-zero length' );

my $struct2= bless \("x"x X11::Xlib::XVisualInfo->_sizeof), 'X11::Xlib::XRectangle';

$struct->x(-2);
$struct->y(55);
$struct->width(64000);
$struct->height(0);

# Clone an event via its fields:
my $clone= new_ok( 'X11::Xlib::XRectangle', [$struct->unpack], 'clone event with pack(unpack)' )
    or diag explain $struct->unpack;
is( $clone->buffer, $struct->buffer, 'clone contains identical bytes' );

is( $clone->x, -2, 'x value preserved' );
is( $clone->y, 55, 'y value preserved' );
is( $clone->width, 64000, 'w value preserved' );
is( $clone->height, 0, 'h value preserved' );

#my $conn= X11::Xlib->new();
#my @visuals= map { $_->unpack } $conn->XGetVisualInfo(0, my $foo);
#use DDP;
#p @visuals;