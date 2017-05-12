#!/usr/bin/perl

use lib 'lib',            't/lib';
use Test::Most 'no_plan';#tests => 7;
use OurTester qw($BAILED bails);

ok 1, 'Normal calls to ok() should succeed';
is 2, 2, '... as should all passing tests';

bail_on_fail;
bails { eq_or_diff( [3], [4] ) } '... but failing tests should bail';
ok 4, 'Subsequent calls to ok() should be fine';
ok !$BAILED, '... and not bail';
explain("this is a comment");
