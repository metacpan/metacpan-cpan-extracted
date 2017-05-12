#! /bin/false

package Suites::TS_SubSuite1;

use strict;

use base qw (Test::Unit::TestSuite);

sub name { "A lower level test suite" };
sub include_tests { "Suites::CustomerTest", "Suites::CustomerTest1" };

1;
