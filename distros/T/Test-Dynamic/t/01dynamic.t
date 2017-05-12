#!/usr/bin/perl -- -*-cperl-*-

use strict;
use warnings;
use Test::More;

plan tests => 1; ## Ha!

eval { require Test::Dynamic; };
$@ and BAIL_OUT qq{Could not load the Test::Dynamic module: $@};
pass("Test::Dynamic module loaded");



