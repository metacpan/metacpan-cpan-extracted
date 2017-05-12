#!perl

# Tests that the Text::Greeking package compiles

use strict;
use warnings;
use Test::More tests => 2;

ok($] >= 5.006, "Your perl is new enough");

use_ok('Text::Greeking');
