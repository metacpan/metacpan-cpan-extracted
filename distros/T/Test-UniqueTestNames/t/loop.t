#!/usr/bin/perl

use strict;
use warnings;

use Test::Builder::Tester tests => 3;
use Test::More;
use Test::NoWarnings;

use lib 'lib';
use_ok( 'Test::UniqueTestNames', qw/ had_unique_test_names /);

my $line_num = line_num( +18 );
my $expected_error = "#   Failed test 'all test names unique'
#   at lib/Test/UniqueTestNames.pm line 156.
# The following 1 test name(s) were not unique:
# Test Name                               Occurrences     Line(s)
# ----------------------------------------------------------------
# foo                                         3           $line_num (3 times)";

my $expected_output = 'ok 1 - foo
ok 2 - bar
ok 3 - foo
ok 4 - foo
not ok 5 - all test names unique';

test_err( $expected_error );
test_out( $expected_output );

my @data = (qw/ foo bar foo foo /);
ok( 1, $_ ) for @data;

had_unique_test_names();
test_test( "fails when there are multiple tests with the same name in a loop" );
