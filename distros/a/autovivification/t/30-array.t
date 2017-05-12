#!perl -T

use strict;
use warnings;

use lib 't/lib';
use Test::Leaner tests => 9 * 3 * 302;

use autovivification::TestCases;

while (<DATA>) {
 1 while chomp;
 next unless /#/;
 testcase_ok($_, '@');
}

__DATA__

--- fetch ---

$x # $x->[$N[0]] # '', undef, [ ]
$x # $x->[$N[0]] # '', undef, undef #
$x # $x->[$N[0]] # '', undef, undef # +fetch
$x # $x->[$N[0]] # '', undef, [ ] # +exists
$x # $x->[$N[0]] # '', undef, [ ] # +delete
$x # $x->[$N[0]] # '', undef, [ ] # +store

$x # $x->[$N[0]] # '', undef, [ ] # -fetch
$x # $x->[$N[0]] # '', undef, [ ] # +fetch -fetch
$x # $x->[$N[0]] # '', undef, undef # -fetch +fetch
$x # $x->[$N[0]] # '', undef, undef # +fetch -exists

$x # $x->[$N[0]] # qr/^Reference vivification forbidden/, undef, undef # +strict +fetch
$x # $x->[$N[0]] # '', undef, [ ] # +strict +exists
$x # $x->[$N[0]] # '', undef, [ ] # +strict +delete
$x # $x->[$N[0]] # '', undef, [ ] # +strict +store

$x # $x->[$N[0]]->[$N[1]] # '', undef, [ [ ] ]
$x # $x->[$N[0]]->[$N[1]] # '', undef, undef #
$x # $x->[$N[0]]->[$N[1]] # '', undef, undef # +fetch
$x # $x->[$N[0]]->[$N[1]] # '', undef, [ [ ] ] # +exists
$x # $x->[$N[0]]->[$N[1]] # '', undef, [ [ ] ] # +delete
$x # $x->[$N[0]]->[$N[1]] # '', undef, [ [ ] ] # +store

$x # $x->[$N[0]]->[$N[1]] # qr/^Reference vivification forbidden/, undef, undef # +strict +fetch
$x # $x->[$N[0]]->[$N[1]] # '', undef, [ [ ] ] # +strict +exists
$x # $x->[$N[0]]->[$N[1]] # '', undef, [ [ ] ] # +strict +delete
$x # $x->[$N[0]]->[$N[1]] # '', undef, [ [ ] ] # +strict +store

$x->[$N[0]] = 1 # $x->[$N[0]] # '', 1, [ 1 ] # +fetch
$x->[$N[0]] = 1 # $x->[$N[1]] # '', undef, [ 1 ] # +fetch
$x->[$N[0]] = 1 # $x->[$N[0]] # '', 1, [ 1 ] # +exists
$x->[$N[0]] = 1 # $x->[$N[1]] # '', undef, [ 1 ] # +exists
$x->[$N[0]] = 1 # $x->[$N[0]] # '', 1, [ 1 ] # +delete
$x->[$N[0]] = 1 # $x->[$N[1]] # '', undef, [ 1 ] # +delete
$x->[$N[0]] = 1 # $x->[$N[0]] # '', 1, [ 1 ] # +store
$x->[$N[0]] = 1 # $x->[$N[1]] # '', undef, [ 1 ] # +store

$x->[$N[0]] = 1 # $x->[$N[0]] # '', 1, [ 1 ] # +strict +fetch
$x->[$N[0]] = 1 # $x->[$N[1]] # '', undef, [ 1 ] # +strict +fetch
$x->[$N[0]] = 1 # $x->[$N[0]] # '', 1, [ 1 ] # +strict +exists
$x->[$N[0]] = 1 # $x->[$N[1]] # '', undef, [ 1 ] # +strict +exists
$x->[$N[0]] = 1 # $x->[$N[0]] # '', 1, [ 1 ] # +strict +delete
$x->[$N[0]] = 1 # $x->[$N[1]] # '', undef, [ 1 ] # +strict +delete
$x->[$N[0]] = 1 # $x->[$N[0]] # '', 1, [ 1 ] # +strict +store
$x->[$N[0]] = 1 # $x->[$N[1]] # '', undef, [ 1 ] # +strict +store

$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[0]]->[$N[1]] # '', 1, [ [ undef, 1 ] ] # +fetch
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[0]]->[$N[3]] # '', undef, [ [ undef, 1 ] ] # +fetch
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[2]]->[$N[3]] # '', undef, [ [ undef, 1 ] ] # +fetch
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[0]]->[$N[1]] # '', 1, [ [ undef, 1 ] ] # +exists
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[0]]->[$N[3]] # '', undef, [ [ undef, 1 ] ] # +exists
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[2]]->[$N[3]] # '', undef, [ [ undef, 1 ], undef, [ ] ] # +exists
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[0]]->[$N[1]] # '', 1, [ [ undef, 1 ] ] # +delete
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[0]]->[$N[3]] # '', undef, [ [ undef, 1 ] ] # +delete
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[2]]->[$N[3]] # '', undef, [ [ undef, 1 ], undef, [ ] ] # +delete
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[0]]->[$N[1]] # '', 1, [ [ undef, 1 ] ] # +store
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[0]]->[$N[3]] # '', undef, [ [ undef, 1 ] ] # +store
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[2]]->[$N[3]] # '', undef, [ [ undef, 1 ], undef, [ ] ] # +store

$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[0]]->[$N[1]] # '', 1, [ [ undef, 1 ] ] # +strict +fetch
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[0]]->[$N[3]] # '', undef, [ [ undef, 1 ] ] # +strict +fetch
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[2]]->[$N[3]] # qr/^Reference vivification forbidden/, undef, [ [ undef, 1 ] ] # +strict +fetch
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[0]]->[$N[1]] # '', 1, [ [ undef, 1 ] ] # +strict +exists
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[0]]->[$N[3]] # '', undef, [ [ undef, 1 ] ] # +strict +exists
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[2]]->[$N[3]] # '', undef, [ [ undef, 1 ], undef, [ ] ] # +strict +exists
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[0]]->[$N[1]] # '', 1, [ [ undef, 1 ] ] # +strict +delete
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[0]]->[$N[3]] # '', undef, [ [ undef, 1 ] ] # +strict +delete
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[2]]->[$N[3]] # '', undef, [ [ undef, 1 ], undef, [ ] ] # +strict +delete
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[0]]->[$N[1]] # '', 1, [ [ undef, 1 ] ] # +strict +store
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[0]]->[$N[3]] # '', undef, [ [ undef, 1 ] ] # +strict +store
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[2]]->[$N[3]] # '', undef, [ [ undef, 1 ], undef, [ ] ] # +strict +store

--- aliasing ---

$x # 1 for $x->[$N[0]]; () # '', undef, [ undef ]
$x # 1 for $x->[$N[0]]; () # '', undef, [ undef ] #
$x # 1 for $x->[$N[0]]; () # '', undef, [ undef ] # +fetch
$x # 1 for $x->[$N[0]]; () # '', undef, [ undef ] # +exists
$x # 1 for $x->[$N[0]]; () # '', undef, [ undef ] # +delete
$x # 1 for $x->[$N[0]]; () # qr/^Can't vivify reference/, undef, undef # +store

$x # $_ = 1 for $x->[$N[0]]; () # '', undef, [ 1 ]
$x # $_ = 1 for $x->[$N[0]]; () # '', undef, [ 1 ] #
$x # $_ = 1 for $x->[$N[0]]; () # '', undef, [ 1 ] # +fetch
$x # $_ = 1 for $x->[$N[0]]; () # '', undef, [ 1 ] # +exists
$x # $_ = 1 for $x->[$N[0]]; () # '', undef, [ 1 ] # +delete
$x # $_ = 1 for $x->[$N[0]]; () # qr/^Can't vivify reference/, undef, undef # +store

$x->[$N[0]] = 1 # 1 for $x->[$N[0]]; () # '', undef, [ 1 ] # +fetch
$x->[$N[0]] = 1 # 1 for $x->[$N[1]]; () # '', undef, [ 1, undef ] # +fetch
$x->[$N[0]] = 1 # 1 for $x->[$N[0]]; () # '', undef, [ 1 ] # +exists
$x->[$N[0]] = 1 # 1 for $x->[$N[1]]; () # '', undef, [ 1, undef ] # +exists
$x->[$N[0]] = 1 # 1 for $x->[$N[0]]; () # '', undef, [ 1 ] # +delete
$x->[$N[0]] = 1 # 1 for $x->[$N[1]]; () # '', undef, [ 1, undef ] # +delete
$x->[$N[0]] = 1 # 1 for $x->[$N[0]]; () # '', undef, [ 1 ] # +store
$x->[$N[0]] = 1 # 1 for $x->[$N[1]]; () # '', undef, [ 1, undef ] # +store

$x # do_nothing($x->[$N[0]]); () # '', undef, [ ]
$x # do_nothing($x->[$N[0]]); () # '', undef, [ ] #
$x # do_nothing($x->[$N[0]]); () # '', undef, [ ] # +fetch
$x # do_nothing($x->[$N[0]]); () # '', undef, [ ] # +exists
$x # do_nothing($x->[$N[0]]); () # '', undef, [ ] # +delete
$x # do_nothing($x->[$N[0]]); () # qr/^Can't vivify reference/, undef, undef # +store

$x # set_arg($x->[$N[0]]); () # '', undef, [ 1 ]
$x # set_arg($x->[$N[0]]); () # '', undef, [ 1 ] #
$x # set_arg($x->[$N[0]]); () # '', undef, [ 1 ] # +fetch
$x # set_arg($x->[$N[0]]); () # '', undef, [ 1 ] # +exists
$x # set_arg($x->[$N[0]]); () # '', undef, [ 1 ] # +delete
$x # set_arg($x->[$N[0]]); () # qr/^Can't vivify reference/, undef, undef # +store

--- dereferencing ---

$x # no warnings 'uninitialized'; my @a = @$x; () # ($strict ? qr/^Can't use an undefined value as an ARRAY reference/ : ''), undef, undef
$x # no warnings 'uninitialized'; my @a = @$x; () # ($strict ? qr/^Can't use an undefined value as an ARRAY reference/ : ''), undef, undef #
$x # no warnings 'uninitialized'; my @a = @$x; () # ($strict ? qr/^Can't use an undefined value as an ARRAY reference/ : ''), undef, undef # +fetch
$x # no warnings 'uninitialized'; my @a = @$x; () # ($strict ? qr/^Can't use an undefined value as an ARRAY reference/ : ''), undef, undef # +exists
$x # no warnings 'uninitialized'; my @a = @$x; () # ($strict ? qr/^Can't use an undefined value as an ARRAY reference/ : ''), undef, undef # +delete
$x # no warnings 'uninitialized'; my @a = @$x; () # ($strict ? qr/^Can't use an undefined value as an ARRAY reference/ : ''), undef, undef # +store

$x->[$N[0]] = 1 # my @a = @$x; () # '', undef, [ 1 ] # +fetch
$x->[$N[0]] = 1 # my @a = @$x; () # '', undef, [ 1 ] # +exists
$x->[$N[0]] = 1 # my @a = @$x; () # '', undef, [ 1 ] # +delete
$x->[$N[0]] = 1 # my @a = @$x; () # '', undef, [ 1 ] # +store

--- slice ---

$x # my @a = @$x[$N[0], $N[1]]; \@a # '', [ undef, undef ], [ ]
$x # my @a = @$x[$N[0], $N[1]]; \@a # '', [ undef, undef ], undef #
$x # my @a = @$x[$N[0], $N[1]]; \@a # '', [ undef, undef ], undef # +fetch
$x # my @a = @$x[$N[0], $N[1]]; \@a # '', [ undef, undef ], [ ] # +exists
$x # my @a = @$x[$N[0], $N[1]]; \@a # '', [ undef, undef ], [ ] # +delete
$x # my @a = @$x[$N[0], $N[1]]; \@a # '', [ undef, undef ], [ ] # +store

$x->[$N[1]] = 0 # my @a = @$x[$N[0], $N[1]]; \@a # '', [ undef, 0 ], [ undef, 0 ] # +fetch

$x # @$x[$N[0], $N[1]] = (1, 2); () # '', undef, [ 1, 2 ]
$x # @$x[$N[0], $N[1]] = (1, 2); () # '', undef, [ 1, 2 ] #
$x # @$x[$N[0], $N[1]] = (1, 2); () # '', undef, [ 1, 2 ] # +fetch
$x # @$x[$N[0], $N[1]] = (1, 2); () # '', undef, [ 1, 2 ] # +exists
$x # @$x[$N[0], $N[1]] = (1, 2); () # '', undef, [ 1, 2 ] # +delete
$x # @$x[$N[0], $N[1]] = (1, 2); () # qr/^Can't vivify reference/, undef, undef # +store

$x->[$N[0]] = 0 # @$x[$N[0], $N[1]] = (1, 2); () # '', undef, [ 1, 2 ] # +store
$x->[$N[2]] = 0 # @$x[$N[0], $N[1]] = (1, 2); () # '', undef, [ 1, 2, 0 ] # +store
$x->[$N[0]] = 0, $x->[$N[1]] = 0 # @$x[$N[0], $N[1]] = (1, 2); () # '', undef, [ 1, 2 ] # +store

--- exists ---

$x # exists $x->[$N[0]] # '', '', [ ]
$x # exists $x->[$N[0]] # '', '', undef #
$x # exists $x->[$N[0]] # '', '', [ ] # +fetch
$x # exists $x->[$N[0]] # '', '', undef # +exists
$x # exists $x->[$N[0]] # '', '', [ ] # +delete
$x # exists $x->[$N[0]] # '', '', [ ] # +store

$x # exists $x->[$N[0]] # '', '', [ ] # +strict +fetch
$x # exists $x->[$N[0]] # qr/^Reference vivification forbidden/, undef, undef # +strict +exists
$x # exists $x->[$N[0]] # '', '', [ ] # +strict +delete
$x # exists $x->[$N[0]] # '', '', [ ] # +strict +store

$x # exists $x->[$N[0]]->[$N[1]] # '', '', [ [ ] ]
$x # exists $x->[$N[0]]->[$N[1]] # '', '', undef #
$x # exists $x->[$N[0]]->[$N[1]] # '', '', [ [ ] ] # +fetch
$x # exists $x->[$N[0]]->[$N[1]] # '', '', undef # +exists
$x # exists $x->[$N[0]]->[$N[1]] # '', '', [ [ ] ] # +delete
$x # exists $x->[$N[0]]->[$N[1]] # '', '', [ [ ] ] # +store

$x # exists $x->[$N[0]]->[$N[1]] # '', '', [ [ ] ] # +strict +fetch
$x # exists $x->[$N[0]]->[$N[1]] # qr/^Reference vivification forbidden/, undef, undef # +strict +exists
$x # exists $x->[$N[0]]->[$N[1]] # '', '', [ [ ] ] # +strict +delete
$x # exists $x->[$N[0]]->[$N[1]] # '', '', [ [ ] ] # +strict +store

$x->[$N[0]] = 1 # exists $x->[$N[0]] # '', 1, [ 1 ] # +fetch
$x->[$N[0]] = 1 # exists $x->[$N[1]] # '', '', [ 1 ] # +fetch
$x->[$N[0]] = 1 # exists $x->[$N[0]] # '', 1, [ 1 ] # +exists
$x->[$N[0]] = 1 # exists $x->[$N[1]] # '', '', [ 1 ] # +exists
$x->[$N[0]] = 1 # exists $x->[$N[0]] # '', 1, [ 1 ] # +delete
$x->[$N[0]] = 1 # exists $x->[$N[1]] # '', '', [ 1 ] # +delete
$x->[$N[0]] = 1 # exists $x->[$N[0]] # '', 1, [ 1 ] # +store
$x->[$N[0]] = 1 # exists $x->[$N[1]] # '', '', [ 1 ] # +store

$x->[$N[0]] = 1 # exists $x->[$N[0]] # '', 1, [ 1 ] # +strict +fetch
$x->[$N[0]] = 1 # exists $x->[$N[1]] # '', '', [ 1 ] # +strict +fetch
$x->[$N[0]] = 1 # exists $x->[$N[0]] # '', 1, [ 1 ] # +strict +exists
$x->[$N[0]] = 1 # exists $x->[$N[1]] # '', '', [ 1 ] # +strict +exists
$x->[$N[0]] = 1 # exists $x->[$N[0]] # '', 1, [ 1 ] # +strict +delete
$x->[$N[0]] = 1 # exists $x->[$N[1]] # '', '', [ 1 ] # +strict +delete
$x->[$N[0]] = 1 # exists $x->[$N[0]] # '', 1, [ 1 ] # +strict +store
$x->[$N[0]] = 1 # exists $x->[$N[1]] # '', '', [ 1 ] # +strict +store

$x->[$N[0]]->[$N[1]] = 1 # exists $x->[$N[0]]->[$N[1]] # '', 1, [ [ undef, 1 ] ] # +fetch
$x->[$N[0]]->[$N[1]] = 1 # exists $x->[$N[0]]->[$N[3]] # '', '', [ [ undef, 1 ] ] # +fetch
$x->[$N[0]]->[$N[1]] = 1 # exists $x->[$N[2]]->[$N[3]] # '', '', [ [ undef, 1 ], undef, [ ] ] # +fetch
$x->[$N[0]]->[$N[1]] = 1 # exists $x->[$N[0]]->[$N[1]] # '', 1, [ [ undef, 1 ] ] # +exists
$x->[$N[0]]->[$N[1]] = 1 # exists $x->[$N[0]]->[$N[3]] # '', '', [ [ undef, 1 ] ] # +exists
$x->[$N[0]]->[$N[1]] = 1 # exists $x->[$N[2]]->[$N[3]] # '', '', [ [ undef, 1 ] ] # +exists
$x->[$N[0]]->[$N[1]] = 1 # exists $x->[$N[0]]->[$N[1]] # '', 1, [ [ undef, 1 ] ] # +delete
$x->[$N[0]]->[$N[1]] = 1 # exists $x->[$N[0]]->[$N[3]] # '', '', [ [ undef, 1 ] ] # +delete
$x->[$N[0]]->[$N[1]] = 1 # exists $x->[$N[2]]->[$N[3]] # '', '', [ [ undef, 1 ], undef, [ ] ] # +delete
$x->[$N[0]]->[$N[1]] = 1 # exists $x->[$N[0]]->[$N[1]] # '', 1, [ [ undef, 1 ] ] # +store
$x->[$N[0]]->[$N[1]] = 1 # exists $x->[$N[0]]->[$N[3]] # '', '', [ [ undef, 1 ] ] # +store
$x->[$N[0]]->[$N[1]] = 1 # exists $x->[$N[2]]->[$N[3]] # '', '', [ [ undef, 1 ], undef, [ ] ] # +store

$x->[$N[0]]->[$N[1]] = 1 # exists $x->[$N[0]]->[$N[1]] # '', 1, [ [ undef, 1 ] ] # +strict +fetch
$x->[$N[0]]->[$N[1]] = 1 # exists $x->[$N[0]]->[$N[3]] # '', '', [ [ undef, 1 ] ] # +strict +fetch
$x->[$N[0]]->[$N[1]] = 1 # exists $x->[$N[2]]->[$N[3]] # '', '', [ [ undef, 1 ], undef, [ ] ] # +strict +fetch
$x->[$N[0]]->[$N[1]] = 1 # exists $x->[$N[0]]->[$N[1]] # '', 1, [ [ undef, 1 ] ] # +strict +exists
$x->[$N[0]]->[$N[1]] = 1 # exists $x->[$N[0]]->[$N[3]] # '', '', [ [ undef, 1 ] ] # +strict +exists
$x->[$N[0]]->[$N[1]] = 1 # exists $x->[$N[2]]->[$N[3]] # qr/^Reference vivification forbidden/, undef, [ [ undef, 1 ] ] # +strict +exists
$x->[$N[0]]->[$N[1]] = 1 # exists $x->[$N[0]]->[$N[1]] # '', 1, [ [ undef, 1 ] ] # +strict +delete
$x->[$N[0]]->[$N[1]] = 1 # exists $x->[$N[0]]->[$N[3]] # '', '', [ [ undef, 1 ] ] # +strict +delete
$x->[$N[0]]->[$N[1]] = 1 # exists $x->[$N[2]]->[$N[3]] # '', '', [ [ undef, 1 ], undef, [ ] ] # +strict +delete
$x->[$N[0]]->[$N[1]] = 1 # exists $x->[$N[0]]->[$N[1]] # '', 1, [ [ undef, 1 ] ] # +strict +store
$x->[$N[0]]->[$N[1]] = 1 # exists $x->[$N[0]]->[$N[3]] # '', '', [ [ undef, 1 ] ] # +strict +store
$x->[$N[0]]->[$N[1]] = 1 # exists $x->[$N[2]]->[$N[3]] # '', '', [ [ undef, 1 ], undef, [ ] ] # +strict +store

--- delete ---

$x # delete $x->[$N[0]] # '', undef, [ ]
$x # delete $x->[$N[0]] # '', undef, undef #
$x # delete $x->[$N[0]] # '', undef, [ ] # +fetch
$x # delete $x->[$N[0]] # '', undef, [ ] # +exists
$x # delete $x->[$N[0]] # '', undef, undef # +delete
$x # delete $x->[$N[0]] # '', undef, [ ] # +store

$x # delete $x->[$N[0]] # '', undef, [ ] # +strict +fetch
$x # delete $x->[$N[0]] # '', undef, [ ] # +strict +exists
$x # delete $x->[$N[0]] # qr/^Reference vivification forbidden/, undef, undef # +strict +delete
$x # delete $x->[$N[0]] # '', undef, [ ] # +strict +store

$x # delete $x->[$N[0]]->[$N[1]] # '', undef, [ [ ] ]
$x # delete $x->[$N[0]]->[$N[1]] # '', undef, undef #
$x # delete $x->[$N[0]]->[$N[1]] # '', undef, [ [ ] ] # +fetch
$x # delete $x->[$N[0]]->[$N[1]] # '', undef, [ [ ] ] # +exists
$x # delete $x->[$N[0]]->[$N[1]] # '', undef, undef # +delete
$x # delete $x->[$N[0]]->[$N[1]] # '', undef, [ [ ] ] # +store

$x # delete $x->[$N[0]]->[$N[1]] # '', undef, [ [ ] ] # +strict +fetch
$x # delete $x->[$N[0]]->[$N[1]] # '', undef, [ [ ] ] # +strict +exists
$x # delete $x->[$N[0]]->[$N[1]] # qr/^Reference vivification forbidden/, undef, undef # +strict +delete
$x # delete $x->[$N[0]]->[$N[1]] # '', undef, [ [ ] ] # +strict +store

$x->[$N[0]] = 1 # delete $x->[$N[0]] # '', 1, [ ] # +fetch
$x->[$N[0]] = 1 # delete $x->[$N[1]] # '', undef, [ 1 ] # +fetch
$x->[$N[0]] = 1 # delete $x->[$N[0]] # '', 1, [ ] # +exists
$x->[$N[0]] = 1 # delete $x->[$N[1]] # '', undef, [ 1 ] # +exists
$x->[$N[0]] = 1 # delete $x->[$N[0]] # '', 1, [ ] # +delete
$x->[$N[0]] = 1 # delete $x->[$N[1]] # '', undef, [ 1 ] # +delete
$x->[$N[0]] = 1 # delete $x->[$N[0]] # '', 1, [ ] # +store
$x->[$N[0]] = 1 # delete $x->[$N[1]] # '', undef, [ 1 ] # +store

$x->[$N[0]] = 1 # delete $x->[$N[0]] # '', 1, [ ] # +strict +fetch
$x->[$N[0]] = 1 # delete $x->[$N[1]] # '', undef, [ 1 ] # +strict +fetch
$x->[$N[0]] = 1 # delete $x->[$N[0]] # '', 1, [ ] # +strict +exists
$x->[$N[0]] = 1 # delete $x->[$N[1]] # '', undef, [ 1 ] # +strict +exists
$x->[$N[0]] = 1 # delete $x->[$N[0]] # '', 1, [ ] # +strict +delete
$x->[$N[0]] = 1 # delete $x->[$N[1]] # '', undef, [ 1 ] # +strict +delete
$x->[$N[0]] = 1 # delete $x->[$N[0]] # '', 1, [ ] # +strict +store
$x->[$N[0]] = 1 # delete $x->[$N[1]] # '', undef, [ 1 ] # +strict +store

$x->[$N[0]]->[$N[1]] = 1 # delete $x->[$N[0]]->[$N[1]] # '', 1, [ [ ] ] # +fetch
$x->[$N[0]]->[$N[1]] = 1 # delete $x->[$N[0]]->[$N[3]] # '', undef, [ [ undef, 1 ] ]# +fetch
$x->[$N[0]]->[$N[1]] = 1 # delete $x->[$N[2]]->[$N[3]] # '', undef, [ [ undef, 1 ], undef, [ ] ] # +fetch
$x->[$N[0]]->[$N[1]] = 1 # delete $x->[$N[0]]->[$N[1]] # '', 1, [ [ ] ] # +exists
$x->[$N[0]]->[$N[1]] = 1 # delete $x->[$N[0]]->[$N[3]] # '', undef, [ [ undef, 1 ] ]# +exists
$x->[$N[0]]->[$N[1]] = 1 # delete $x->[$N[2]]->[$N[3]] # '', undef, [ [ undef, 1 ], undef, [ ] ] # +exists
$x->[$N[0]]->[$N[1]] = 1 # delete $x->[$N[0]]->[$N[1]] # '', 1, [ [ ] ] # +delete
$x->[$N[0]]->[$N[1]] = 1 # delete $x->[$N[0]]->[$N[3]] # '', undef, [ [ undef, 1 ] ]# +delete
$x->[$N[0]]->[$N[1]] = 1 # delete $x->[$N[2]]->[$N[3]] # '', undef, [ [ undef, 1 ] ]# +delete
$x->[$N[0]]->[$N[1]] = 1 # delete $x->[$N[0]]->[$N[1]] # '', 1, [ [ ] ] # +store
$x->[$N[0]]->[$N[1]] = 1 # delete $x->[$N[0]]->[$N[3]] # '', undef, [ [ undef, 1 ] ]# +store
$x->[$N[0]]->[$N[1]] = 1 # delete $x->[$N[2]]->[$N[3]] # '', undef, [ [ undef, 1 ], undef, [ ] ] # +store

$x->[$N[0]]->[$N[1]] = 1 # delete $x->[$N[0]]->[$N[1]] # '', 1, [ [ ] ] # +strict +fetch
$x->[$N[0]]->[$N[1]] = 1 # delete $x->[$N[0]]->[$N[3]] # '', undef, [ [ undef, 1 ] ] # +strict +fetch
$x->[$N[0]]->[$N[1]] = 1 # delete $x->[$N[2]]->[$N[3]] # '', undef, [ [ undef, 1 ], undef, [ ] ]# +strict +fetch
$x->[$N[0]]->[$N[1]] = 1 # delete $x->[$N[0]]->[$N[1]] # '', 1, [ [ ] ] # +strict +exists
$x->[$N[0]]->[$N[1]] = 1 # delete $x->[$N[0]]->[$N[3]] # '', undef, [ [ undef, 1 ] ] # +strict +exists
$x->[$N[0]]->[$N[1]] = 1 # delete $x->[$N[2]]->[$N[3]] # '', undef, [ [ undef, 1 ], undef, [ ] ]# +strict +exists
$x->[$N[0]]->[$N[1]] = 1 # delete $x->[$N[0]]->[$N[1]] # '', 1, [ [ ] ] # +strict +delete
$x->[$N[0]]->[$N[1]] = 1 # delete $x->[$N[0]]->[$N[3]] # '', undef, [ [ undef, 1 ] ] # +strict +delete
$x->[$N[0]]->[$N[1]] = 1 # delete $x->[$N[2]]->[$N[3]] # qr/^Reference vivification forbidden/, undef, [ [ undef, 1 ] ] # +strict +delete
$x->[$N[0]]->[$N[1]] = 1 # delete $x->[$N[0]]->[$N[1]] # '', 1, [ [ ] ] # +strict +store
$x->[$N[0]]->[$N[1]] = 1 # delete $x->[$N[0]]->[$N[3]] # '', undef, [ [ undef, 1 ] ] # +strict +store
$x->[$N[0]]->[$N[1]] = 1 # delete $x->[$N[2]]->[$N[3]] # '', undef, [ [ undef, 1 ], undef, [ ] ]# +strict +store

--- store ---

$x # $x->[$N[0]] = 1 # '', 1, [ 1 ]
$x # $x->[$N[0]] = 1 # '', 1, [ 1 ] #
$x # $x->[$N[0]] = 1 # '', 1, [ 1 ] # +fetch
$x # $x->[$N[0]] = 1 # '', 1, [ 1 ] # +exists
$x # $x->[$N[0]] = 1 # '', 1, [ 1 ] # +delete
$x # $x->[$N[0]] = 1 # qr/^Can't vivify reference/, undef, undef # +store

$x # $x->[$N[0]] = 1 # '', 1, [ 1 ] # +strict +fetch
$x # $x->[$N[0]] = 1 # '', 1, [ 1 ] # +strict +exists
$x # $x->[$N[0]] = 1 # '', 1, [ 1 ] # +strict +delete
$x # $x->[$N[0]] = 1 # qr/^Reference vivification forbidden/, undef, undef # +strict +store

$x # $x->[$N[0]]->[$N[1]] = 1 # '', 1, [ [ undef, 1 ] ]
$x # $x->[$N[0]]->[$N[1]] = 1 # '', 1, [ [ undef, 1 ] ] #
$x # $x->[$N[0]]->[$N[1]] = 1 # '', 1, [ [ undef, 1 ] ] # +fetch
$x # $x->[$N[0]]->[$N[1]] = 1 # '', 1, [ [ undef, 1 ] ] # +exists
$x # $x->[$N[0]]->[$N[1]] = 1 # '', 1, [ [ undef, 1 ] ] # +delete
$x # $x->[$N[0]]->[$N[1]] = 1 # qr/^Can't vivify reference/, undef, undef # +store

$x # $x->[$N[0]]->[$N[1]] = 1 # '', 1, [ [ undef, 1 ] ] # +strict +fetch
$x # $x->[$N[0]]->[$N[1]] = 1 # '', 1, [ [ undef, 1 ] ] # +strict +exists
$x # $x->[$N[0]]->[$N[1]] = 1 # '', 1, [ [ undef, 1 ] ] # +strict +delete
$x # $x->[$N[0]]->[$N[1]] = 1 # qr/^Reference vivification forbidden/, undef, undef # +strict +store

$x->[$N[0]] = 1 # $x->[$N[0]] = 2 # '', 2, [ 2 ] # +fetch
$x->[$N[0]] = 1 # $x->[$N[1]] = 2 # '', 2, [ 1, 2 ] # +fetch
$x->[$N[0]] = 1 # $x->[$N[0]] = 2 # '', 2, [ 2 ] # +exists
$x->[$N[0]] = 1 # $x->[$N[1]] = 2 # '', 2, [ 1, 2 ] # +exists
$x->[$N[0]] = 1 # $x->[$N[0]] = 2 # '', 2, [ 2 ] # +delete
$x->[$N[0]] = 1 # $x->[$N[1]] = 2 # '', 2, [ 1, 2 ] # +delete
$x->[$N[0]] = 1 # $x->[$N[0]] = 2 # '', 2, [ 2 ] # +store
$x->[$N[0]] = 1 # $x->[$N[1]] = 2 # '', 2, [ 1, 2 ] # +store

$x->[$N[0]] = 1 # $x->[$N[0]] = 2 # '', 2, [ 2 ] # +strict +fetch
$x->[$N[0]] = 1 # $x->[$N[1]] = 2 # '', 2, [ 1, 2 ] # +strict +fetch
$x->[$N[0]] = 1 # $x->[$N[0]] = 2 # '', 2, [ 2 ] # +strict +exists
$x->[$N[0]] = 1 # $x->[$N[1]] = 2 # '', 2, [ 1, 2 ] # +strict +exists
$x->[$N[0]] = 1 # $x->[$N[0]] = 2 # '', 2, [ 2 ] # +strict +delete
$x->[$N[0]] = 1 # $x->[$N[1]] = 2 # '', 2, [ 1, 2 ] # +strict +delete
$x->[$N[0]] = 1 # $x->[$N[0]] = 2 # '', 2, [ 2 ] # +strict +store
$x->[$N[0]] = 1 # $x->[$N[1]] = 2 # '', 2, [ 1, 2 ] # +strict +store

$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[0]]->[$N[1]] = 2 # '', 2, [ [ undef, 2 ] ] # +fetch
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[0]]->[$N[3]] = 2 # '', 2, [ [ undef, 1, undef, 2 ] ] # +fetch
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[2]]->[$N[3]] = 2 # '', 2, [ [ undef, 1 ], undef, [ undef, undef, undef, 2 ] ] # +fetch
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[0]]->[$N[1]] = 2 # '', 2, [ [ undef, 2 ] ] # +exists
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[0]]->[$N[3]] = 2 # '', 2, [ [ undef, 1, undef, 2 ] ] # +exists
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[2]]->[$N[3]] = 2 # '', 2, [ [ undef, 1 ], undef, [ undef, undef, undef, 2 ] ] # +exists
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[0]]->[$N[1]] = 2 # '', 2, [ [ undef, 2 ] ] # +delete
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[0]]->[$N[3]] = 2 # '', 2, [ [ undef, 1, undef, 2 ] ] # +delete
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[2]]->[$N[3]] = 2 # '', 2, [ [ undef, 1 ], undef, [ undef, undef, undef, 2 ] ] # +delete
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[0]]->[$N[1]] = 2 # '', 2, [ [ undef, 2 ] ] # +store
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[0]]->[$N[3]] = 2 # '', 2, [ [ undef, 1, undef, 2 ] ] # +store
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[2]]->[$N[3]] = 2 # qr/^Can't vivify reference/, undef, [ [ undef, 1 ] ] # +store

$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[0]]->[$N[1]] = 2 # '', 2, [ [ undef, 2 ] ] # +strict +fetch
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[0]]->[$N[3]] = 2 # '', 2, [ [ undef, 1, undef, 2 ] ] # +strict +fetch
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[2]]->[$N[3]] = 2 # '', 2, [ [ undef, 1 ], undef, [ undef, undef, undef, 2 ] ] # +strict +fetch
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[0]]->[$N[1]] = 2 # '', 2, [ [ undef, 2 ] ] # +strict +exists
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[0]]->[$N[3]] = 2 # '', 2, [ [ undef, 1, undef, 2 ] ] # +strict +exists
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[2]]->[$N[3]] = 2 # '', 2, [ [ undef, 1 ], undef, [ undef, undef, undef, 2 ] ] # +strict +exists
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[0]]->[$N[1]] = 2 # '', 2, [ [ undef, 2 ] ] # +strict +delete
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[0]]->[$N[3]] = 2 # '', 2, [ [ undef, 1, undef, 2 ] ] # +strict +delete
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[2]]->[$N[3]] = 2 # '', 2, [ [ undef, 1 ], undef, [ undef, undef, undef, 2 ] ] # +strict +delete
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[0]]->[$N[1]] = 2 # '', 2, [ [ undef, 2 ] ] # +strict +store
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[0]]->[$N[3]] = 2 # '', 2, [ [ undef, 1, undef, 2 ] ] # +strict +store
$x->[$N[0]]->[$N[1]] = 1 # $x->[$N[2]]->[$N[3]] = 2 # qr/^Reference vivification forbidden/, undef, [ [ undef, 1 ] ] # +strict +store
