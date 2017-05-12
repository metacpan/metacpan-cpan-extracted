#!perl

package Foo;

use latest;
use like qw( if::this );

package Bar;

use latest;
use like qw( if::this if::that );

package main;

use latest;

use Test::More tests => 5;

isa_ok 'Foo', 'if::this';
isa_ok 'Bar', 'if::that';
isa_ok 'Bar', 'if::this';

ok !Foo->isa( 'if::that' ),      "Foo ain't all that";
ok !Bar->isa( 'if::imaginary' ), "Bar ain't deluded";

# vim:ts=2:sw=2:et:ft=perl

