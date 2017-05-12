#!/usr/bin/perl

use strict;

use Test::More tests => 3;
use Tie::DataUUID qw($uuid);

is(ref tied $uuid, "Tie::DataUUID", "right class");
ok($uuid ne $uuid, "it changes");
like("$uuid $uuid", "/[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12} [A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}/i", "looks good");
