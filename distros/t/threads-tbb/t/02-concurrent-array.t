#!/usr/bin/perl

use Test::More no_plan;
use strict;

BEGIN { use_ok("threads::tbb") }

my $array_tie_obj = threads::tbb::concurrent::array->new;
my $tbb = threads::tbb->new;

isa_ok($array_tie_obj, "threads::tbb::concurrent::array", "new perl_concurrent_vector");
is($array_tie_obj->size, 0, "Knows its size");
$array_tie_obj->STORESIZE(1);
is($array_tie_obj->size, 1, "STORESIZE");
$array_tie_obj->STORE(0, "foo");
my $back = $array_tie_obj->FETCH(0);
is($back, "foo", "STORE/FETCH");

tie my @array, "threads::tbb::concurrent::array";

isa_ok(tied(@array), "threads::tbb::concurrent::array", "tied(\@array)");
is( scalar(@array), 0, "FETCHSIZE()" );

#(tied @array)->STORESIZE(1); # hmm
$array[0] = "bob";
#(tied @array)->STORE(0, "bob"); # hmm
is(scalar(@array), 1, "STORE - size increased");
is($array[0], "bob", "STORE - slot changed");

push @array, "bill";
is(scalar(@array), 2, "PUSH - size increased");
is($array[1], "bill", "PUSH - slot changed");

push @array, "bas", "bert";

is(scalar(@array), 4, "PUSH (many) - size increased");
is($array[2], "bas", "PUSH (many) - slot 2 changed");
is($array[3], "bert", "PUSH (many) - slot 3 changed");

is($array[4], undef, "nothing in an empty slot");
is(scalar(@array), 4, "access beyond end does not EXTEND");

$#array = 4;
is(scalar(@array), 5, "STORESIZE via \$#array");
is($array[4], undef, "FETCH converts nil to sv_undef OK");

$array[4] = "ben";
is($array[4], "ben", "Reassign undef to value");
$array[4] = "bud";
is($array[4], "bud", "Reassign value to value");

our $DESTROYED = 0;
{package MyObj;
 sub DESTROY { $main::DESTROYED++ }
}
push @array, bless{},MyObj::;
isa_ok($array[5], "MyObj", "Push an object on the array");
untie(@array);
is($DESTROYED, 1, "items in array destroyed in a timely fashion");
