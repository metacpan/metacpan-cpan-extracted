#!/usr/bin/perl
#
use strict;
use warnings;

use Test::More tests => 3;
use Test::Exit;

exits_ok { eval { exit 1; } } "exits_ok";
exits_nonzero { eval { exit 42; } } "exits_nonzero";
exits_zero { eval { exit 0; } } "exits_zero";
