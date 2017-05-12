#!/usr/bin/perl

use lib 'lib', 't/lib';
use Test::Most tests => 4, '-Test::Exception';
use OurTester qw($DIED dies);

ok 1, 'Normal calls to ok() should succeed';
is 2, 2, '... as should all passing tests';
eq_or_diff [ 3, 4 ], [ 3, 4 ], '... and Test::Differences tests';
ok !defined &lives_ok,
  '... but excluding a test module excludes its test functions';
