#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

my $m;

BEGIN { use_ok($m = "Test::TAP::Model::Visual") }

isa_ok((bless {}, $m), "Test::TAP::Model::Colorful");
isa_ok((bless {}, $m), "Test::TAP::Model");

can_ok($m, "file_class");
like($m->file_class, qr/::Visual$/, "it's visual");

can_ok($m, "summary");

