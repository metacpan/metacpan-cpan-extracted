#!/usr/bin/perl -w

use strict;

use Test::More tests => 1;

use MyTestModule23;

# TEST
is (hello(3,4), 25, "3*3+4*4 = 25");

