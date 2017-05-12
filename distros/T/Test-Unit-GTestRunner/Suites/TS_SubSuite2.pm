#! /bin/false

package Suites::TS_SubSuite2;

use strict;

use base qw (Test::Unit::TestSuite);

sub name { "Another lower level test suite" };
sub include_tests { "Suites::CustomerTest", "Suites::TS_SubSuite3" };

1;
