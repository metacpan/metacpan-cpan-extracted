#!perl -w
use strict;
use Test::More tests => 4;

require_ok( 'Tie::Hash::Constant' );
tie my %foo, 'Tie::Hash::Constant' => 'pie';
ok( tied %foo, "foo is tied" );
is( $foo{noexist}, 'pie', 'noexist got pie' );
$foo{notpie} = 'notpie';
is( $foo{notpie}, 'pie', 'notpie got pie' );
