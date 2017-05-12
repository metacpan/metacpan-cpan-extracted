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
# The following 5 test name(s) were not unique:
# Test Name                               Occurrences     Line(s)
# ----------------------------------------------------------------
# foo                                         5           43, 45, 53 (3 times)
# baz                                         2           46, 47
# shazam                                      2           48, 49
# flip circus                                 3           50, 51, 52
# this is a really long test name with no ... 2           54 (2 times)";

my $expected_output = 'ok 1 - foo
ok 2 - bar
ok 3 - foo
ok 4 - baz
ok 5 - baz
ok 6 - shazam
ok 7 - shazam
ok 8 - flip circus
ok 9 - flip circus
ok 10 - flip circus
ok 11 - foo
ok 12 - foo
ok 13 - foo
ok 14 - this is a really long test name with no purpose other than to break up the flow of the output
ok 15 - this is a really long test name with no purpose other than to break up the flow of the output
not ok 16 - all test names unique';

test_err( $expected_error );
test_out( $expected_output );
ok( 1, 'foo' );
ok( 1, 'bar' );
ok( 1, 'foo' );
ok( 1, 'baz' );
ok( 1, 'baz' );
ok( 1, 'shazam' );
ok( 1, 'shazam' );
ok( 1, 'flip circus' );
ok( 1, 'flip circus' );
ok( 1, 'flip circus' );
ok( 1, 'foo' ) for 1..3;
ok( 1, 'this is a really long test name with no purpose other than to break up the flow of the output' ) for 1..2;
had_unique_test_names();
test_test( "fails when there are multiple tests with the same names" );
