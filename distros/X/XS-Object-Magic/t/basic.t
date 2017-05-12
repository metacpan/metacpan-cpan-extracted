#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 28;

use Test::Fatal;

use Scalar::Util qw(reftype);

use ok 'XS::Object::Magic';

my $o = XS::Object::Magic::Test->new;

isa_ok($o, "XS::Object::Magic::Test");

is( reftype($o), "HASH", "reftype is hash" );

is( scalar(keys %$o), 0, "hash is empty" );

can_ok( $o, "count" );

ok( $o->has, "has a struct" );

is( $o->count, 1, "count method" );
is( $o->count, 2, "count method" );
is( $o->count, 3, "count method" );

is( XS::Object::Magic::Test::destroyed(), 0, "not yet destroyed" );

undef $o;

is( XS::Object::Magic::Test::destroyed(), 1, "destroyed" );

no warnings 'redefine';
*XS::Object::Magic::Test::DESTROY = sub {};

my $bad = bless {}, 'XS::Object::Magic::Test';

ok( !$bad->has, "does not have a struct" );

like( exception { $bad->count }, qr/does not have a struct/,
      "methods that need a struct die when there isn't one" );

$o = XS::Object::Magic::Test->new;

ok( $o->has, "has struct" );

is( $o->detach_garbage, 0, "can't detach struct at 0x123456" );

ok( $o->has, "still have struct" );

is( $o->detach_struct, 1, "detached the struct" );

ok( !$o->has, "does not have struct anymore" );

undef $o;

$o = XS::Object::Magic::Test->new;

ok( $o->has, "has struct" );

is( $o->detach_null, 1, "detached the struct with NULL arg" );

ok( !$o->has, "does not have struct anymore" );

is( $o->detach_null, 0, "nothing to detach this time" );

ok( !$o->has, "still does not have struct" );

like( exception { $o->count }, qr/does not have a struct/,
      "dies now that the struct is detached" );

undef $o;

$o = XS::Object::Magic::Test->new;

is( exception { $o->attach_again }, undef, 'attaching another struct works' );

ok( $o->has, "has struct" );

is( $o->detach_struct, 2, "detached the struct with NULL arg" );

like( exception { $o->count }, qr/does not have a struct/,
      "dies now that the struct is detached" );
