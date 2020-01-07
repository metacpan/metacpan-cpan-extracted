#!/usr/bin/perl

use Test::More;
plan tests => 6;
use lib '.';			# stupid restriction
require_ok "xt/basic.pl";

SKIP: {
    skip "GhostScript (gs) not available", 4
      unless findbin("gs");
    testit("png");
}
