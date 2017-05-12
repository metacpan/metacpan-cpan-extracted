#!/usr/bin/perl

use Test::More no_plan;
use strict;

BEGIN { use_ok("threads::tbb") }

{
my $scalar_tie_obj = threads::tbb::concurrent::item->new;

isa_ok($scalar_tie_obj, "threads::tbb::concurrent::item", "new perl_concurrent_item");

is($scalar_tie_obj->FETCH, undef, "starts as undef");
$scalar_tie_obj->STORE(1);
is($scalar_tie_obj->FETCH, 1, "stores and retrieves from same thread");
$scalar_tie_obj->STORE("foo");
my $back = $scalar_tie_obj->FETCH;
is($back, "foo", "STORE/FETCH");
}

{
tie my $scalar, "threads::tbb::concurrent::item";

isa_ok(tied($scalar), "threads::tbb::concurrent::item", "tied(\$scalar)");
is( $scalar, undef, "FETCH() via tie: starts as undef" );

$scalar = "bob";
is($scalar, "bob", "FETCH - string");
$scalar .= " the builder";
is($scalar, "bob the builder", "Works 'normally'");

$scalar = 2;
is($scalar, 2, "Works with numbers");

my $orig = bless [ 1,2,3,{ foo => "bar" } ], 'foo';
$scalar = $orig;
my $copy = $scalar;

is_deeply($copy, $orig, "blessed structures in and out");
undef($orig);
$scalar = "foo";

our $DESTROYED = 0;
{package MyObj;
 sub DESTROY { $main::DESTROYED++ }
}
$scalar = bless{},MyObj::;
$scalar = "foo";
is($DESTROYED, 1, "objects in concurrent item destroyed in a timely fashion");
}
