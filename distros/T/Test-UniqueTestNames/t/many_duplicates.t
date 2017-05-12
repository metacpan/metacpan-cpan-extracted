#!/usr/bin/perl

use strict;
use warnings;

use Test::Builder::Tester tests => 3;
use Test::More;
use Test::NoWarnings;

use lib 'lib';
use_ok( 'Test::UniqueTestNames', qw/ had_unique_test_names /);

my $expected_error = "#   Failed test 'all test names unique'
#   at lib/Test/UniqueTestNames.pm line 156.
# The following 2 test name(s) were not unique:
# Test Name                               Occurrences     Line(s)
# ----------------------------------------------------------------
# foo                                         2           29, 31
# bar                                         2           30, 32";

my $expected_output = 'ok 1 - foo
ok 2 - bar
ok 3 - foo
ok 4 - bar
not ok 5 - all test names unique';

test_err( $expected_error );
test_out( $expected_output );
ok( 1, 'foo' );
ok( 1, 'bar' );
ok( 1, 'foo' );
ok( 1, 'bar' );
had_unique_test_names();
test_test( "fails when there are multiple tests with the same name" );
