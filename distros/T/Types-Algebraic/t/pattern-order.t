#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 2;

use Types::Algebraic;

data Color = Red | Blue;

match (Red) {
    with (Blue) { fail("1: Why would you hit this?"); }
    with (Red)  { ok("1: Hit first matching case"); }
    default     { fail("1: Hit second matching case"); }
}

match (Red) {
    with (Blue) { fail("2: Why would you hit this?"); }
    default     { ok("2: Hit first matching case"); }
    with (Red)  { fail("2: Hit second matching case"); }
}
