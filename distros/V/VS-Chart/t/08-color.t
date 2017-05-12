#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

BEGIN { use_ok("VS::Chart::Color"); }

my $color = VS::Chart::Color->color("black");
isa_ok($color, "VS::Chart::Color");
is($color->as_hex, "#000000");

$color = VS::Chart::Color->color("white");
isa_ok($color, "VS::Chart::Color");
is($color->as_hex, "#ffffff");