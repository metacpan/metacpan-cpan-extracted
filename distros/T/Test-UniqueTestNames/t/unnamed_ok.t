#!/usr/bin/perl

use strict;
use warnings;

use Test::Builder::Tester tests => 3;
use Test::More;
use Test::NoWarnings;

use lib 'lib';
use_ok( 'Test::UniqueTestNames', qw/ unnamed_ok had_unique_test_names /);

my $line_num = line_num( +14 );

my $expected_output = 'ok 1
ok 2 - bar
ok 3 - foo
ok 4 - all test names unique';

test_out( $expected_output );
ok( 1 );
ok( 1, 'bar' );
ok( 1, 'foo' );
had_unique_test_names();
test_test( "all tests have unique names, passes an unnamed test when unnamed_ok is imported." );
