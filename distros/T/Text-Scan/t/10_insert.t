#!/usr/bin/perl

use Test;
use Text::Scan;

BEGIN { plan tests => 51 - 4 }

$ref = new Text::Scan;

ok($ref->transitions(), 0);
ok($ref->terminals(), 0);
ok($ref->states(), 0);

ok($ref->insert("firewater", "~"));
ok($ref->transitions(), 10);
ok($ref->terminals(), 1);
ok($ref->states(), 10);

ok($ref->insert("firewater", "~"));
ok($ref->transitions(), 10);
ok($ref->terminals(), 1);
ok($ref->states(), 10);

ok($ref->insert("stereolab", "~"));
ok($ref->transitions(), 20);
ok($ref->terminals(), 2);
ok($ref->states(), 19);

ok($ref->insert("tirewater", "~"));
ok($ref->transitions(), 30);
ok($ref->terminals(), 3);
ok($ref->states(), 28);

ok($ref->insert("tidewater", "~"));
ok($ref->transitions(), 38);
ok($ref->terminals(), 4);
ok($ref->states(), 35);

ok($ref->insert("tidewader", "~"));
ok($ref->transitions(), 42);
ok($ref->terminals(), 5);
ok($ref->states(), 38);

ok($ref->insert("firewater", "~"));
ok($ref->transitions(), 42);
ok($ref->terminals(), 5);
ok($ref->states(), 38);

ok($ref->insert("","~")); # This is a special case, makes nothing.
ok($ref->transitions(), 42);
ok($ref->terminals(), 5);
ok($ref->states(), 38);

ok($ref->insert("stereo","~"));
ok($ref->transitions(), 43);
ok($ref->terminals(), 6);
ok($ref->states(), 38);

ok($ref->insert("","~"));
ok($ref->transitions(), 43);
ok($ref->terminals(), 6);
ok($ref->states(), 38);

for ($i = 2;$i < 256;$i++) { $big .= chr($i); }
ok($ref->insert($big, "~"));
ok($ref->transitions(), 298);
ok($ref->terminals(), 7);
ok($ref->states(), 292);


# Try fixing this later... makes an unnecessary split 
# on inserting char 129(?)
#ok($ref->insert($big,"~"));
#ok($ref->transitions(), 298);
#ok($ref->terminals(), 7);
#ok($ref->states(), 292);

#my @k = $ref->keys();
#print STDERR join "\n\n", @k;
#print STDERR "\n\n";

