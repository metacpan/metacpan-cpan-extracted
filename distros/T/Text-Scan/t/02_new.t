#!/usr/bin/perl

use Test;
use Text::Scan;

BEGIN { plan tests => 2 }

ok($ref = new Text::Scan);
ok(ref($ref), 'Text::Scan');

