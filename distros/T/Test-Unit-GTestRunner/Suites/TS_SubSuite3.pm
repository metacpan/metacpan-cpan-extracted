#! /bin/false

package Suites::TS_SubSuite3;

use strict;

use base qw (Test::Unit::TestSuite);

sub name { "A bottom level test suite" };
sub include_tests { "Suites::CustomerTest2", "Suites::CustomerTest1" };

1;
