#!/usr/bin/perl

use strict;
use warnings;

use Test::Builder::Tester tests => 3;
use Test::More;
use Test::NoWarnings;

use lib 'lib';
use_ok( 'Test::UniqueTestNames', qw/ had_unique_test_names /);

test_out( "ok 1 - all test names unique" );
had_unique_test_names();
test_test( "correct output captured with no other tests" );
