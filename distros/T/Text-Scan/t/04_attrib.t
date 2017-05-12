#!/usr/bin/perl

use Test;
use Text::Scan;

BEGIN { plan tests => 5 }

ok($ref = new Text::Scan);
ok(ref($ref), 'Text::Scan');

ok($ref->states(), 0);
ok($ref->transitions(), 0);
ok($ref->terminals(), 0);

