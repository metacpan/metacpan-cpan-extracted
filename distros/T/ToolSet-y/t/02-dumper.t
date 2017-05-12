#!/usr/bin/perl
use strict;
use warnings;
no warnings;
use Test::More tests => 2;                      # last test to print

use ToolSet::y;
eval { Dumper(1) };
ok('' eq $@, "Dumper used from Data::Dumper");

eval { Dumperr(1) };
ok($@, "Dumperr doesn't exist");

