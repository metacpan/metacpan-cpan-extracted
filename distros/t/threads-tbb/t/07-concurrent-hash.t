#!/usr/bin/perl

use Test::More no_plan;
use strict;

BEGIN { use_ok("threads::tbb") }

my $hash_tie_obj = threads::tbb::concurrent::hash->new;

isa_ok($hash_tie_obj, "threads::tbb::concurrent::hash", "new perl_concurrent_hash");

tie my %hash, "threads::tbb::concurrent::hash";

isa_ok(tied(%hash), "threads::tbb::concurrent::hash", "tied(\%hash)");

is($hash{King_2}, undef, "slots default to undef");
$hash{King_2} = "pawn";
pass("assigned OK");
is($hash{King_2}, "pawn", "returning data from slots");

my $lock = $hash_tie_obj->reader("King_1");
is($lock, undef, "reader: not found");

$hash_tie_obj->STORE( Queen_2 => "bishop" );
$hash_tie_obj->STORE( King_1 => undef );

$lock = $hash_tie_obj->reader("King_1");
isa_ok($lock, "threads::tbb::concurrent::hash::reader", "hash slot reader");
eval { $lock->set("knight") };
isnt($@, undef, "exception writing to set value of reader");
diag("(expected) Exception: $@") if -t STDOUT;

$lock = $hash_tie_obj->writer("King_2");
isa_ok($lock, "threads::tbb::concurrent::hash::writer", "hash slot writer");
is($lock->get, undef, "writer defaults to undef");

$lock->set("pawn");
is($lock->get, "pawn", "writer can set value");

our $DESTROYED = 0;
{package MyObj;
 sub DESTROY { $main::DESTROYED++ }
}
$hash{King_2} = bless{},MyObj::;
is($DESTROYED, 0, "objects in concurrent hash not destroyed too soon");
untie %hash;
is($DESTROYED, 1, "objects in concurrent hash destroyed on time");
