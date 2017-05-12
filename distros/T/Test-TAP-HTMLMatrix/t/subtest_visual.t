#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

my $m;

BEGIN { use_ok($m = "Test::TAP::Model::Subtest::Visual") }

isa_ok((bless {}, $m), "Test::TAP::Model::Subtest");

can_ok($m, "link");
can_ok($m, "css_class");

