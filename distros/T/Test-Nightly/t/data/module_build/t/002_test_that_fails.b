#!/usr/bin/perl -w

use lib qw( ./blib/lib ../blib/lib );

use strict;
use Test::More tests => 1;

use blib;

my $var = 2;

ok($var eq 1, "Test worked");


