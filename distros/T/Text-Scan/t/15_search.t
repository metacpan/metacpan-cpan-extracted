#!/usr/bin/perl

use Test;
use Text::Scan;

BEGIN { plan tests => 8 }

$ref = new Text::Scan;

ok($ref->insert("foobar", "~"));

ok($ref->insert("bloodhound", "~"));

ok($ref->has("foobar"), 1);

ok($ref->has("foo"), 0);

ok($ref->has("foobaz"), 0);

ok($ref->has("pianosaurus"), 0);

ok($ref->has("blood"), 0);

ok($ref->has("bloodhound"), 1);



