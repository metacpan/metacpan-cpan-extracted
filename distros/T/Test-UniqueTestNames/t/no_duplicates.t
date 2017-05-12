#!/usr/bin/perl

use strict;
use warnings;

use Test::Builder::Tester tests => 4;
use Test::More;
use Test::NoWarnings;

use lib 'lib';
use_ok( 'Test::UniqueTestNames', qw/ had_unique_test_names /);

test_out( "ok 1 - foo" );
ok( 1, 'foo' );
test_test( "captured correct output for ok test" );

test_out( "ok 1 - all test names unique" );
had_unique_test_names();
test_test( "correct output captured with no other tests" );
