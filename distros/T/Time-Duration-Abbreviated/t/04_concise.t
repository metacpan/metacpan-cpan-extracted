#!perl

use strict;
use warnings;
use utf8;
use Time::Duration::Abbreviated;

use Test::More;

subtest 'concise' => sub {
    is concise(duration_exact(31626061)), '1yr1d1hr1min1sec';
    is concise(later_exact(31626061)),    '1yr1d1hr1min1sec later';
    is concise(earlier_exact(31626061)),  '1yr1d1hr1min1sec ago';
};

done_testing;

