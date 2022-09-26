use strict;
use warnings;
use Test::More;

use Type::Nano qw( enum );

my $e1 = enum 'FooBar', [ 'foo', 'bar' ];
ok $e1->check( 'foo' );
ok $e1->check( 'bar' );
ok !$e1->check( 'FOO' );
ok !$e1->check( [] );

my $e2 = enum [ 'foo', 'bar' ];
ok $e2->check( 'foo' );
ok $e2->check( 'bar' );
ok !$e2->check( 'FOO' );
ok !$e2->check( [] );

done_testing;
