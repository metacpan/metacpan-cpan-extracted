#!/usr/bin/perl

use lib 'lib', 't/lib';
use Test::Most tests => 6;
use OurTester qw($DIED dies);

ok 1, 'Normal calls to ok() should succeed';
is 2, 2, '... as should all passing tests';
eq_or_diff [ 3, 4 ], [ 3, 4 ], '... and Test::Differences tests';
dies_ok {die} '... and Test::Exception tests';
cmp_deeply [ 3, 4 ], [ 3, 4 ], '... and Test::Deep tests';
warnings_are { warn 'Hi!' } 'Hi!', '... and Test::Warn tests';
explain +Test::Builder->new;
