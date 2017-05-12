#!/usr/bin/perl

use strict;

use Test::More tests => 4;
use_ok "Tie::DataUUID";

tie my $foo, "Tie::DataUUID";
is(ref tied $foo, "Tie::DataUUID", "right class");
ok($foo ne $foo, "it changes");
like("$foo $foo", "/[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12} [A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}/i", "right looking string");
