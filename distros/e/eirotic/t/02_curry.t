#! /usr/bin/perl

use Eirotic;
use Test::More;

{ package A; sub next { "door" } }

my $a = bless {}, 'A';
my $got = eval { $a->curry::next->() };

ok
( (!$@)
, "non fatal use of curry" );

is $got, "door", "correct use of curry";

done_testing;

