#!/usr/bin/perl

use Test::More;
plan tests => 5;
use lib '.';			# stupid restriction
require_ok "t/basic.pl";

SKIP: {
    skip "GhostScript (gs) not available", 4
      unless findbin("gs");
    skip "NetPBM (ppmtogif) not available", 4
      unless findbin("ppmtogif");
    testit("gif");
}
