#!perl

use strict;
use warnings;
use utf8;
use Time::Duration::Abbreviated;

use Test::More;

subtest 'duration_exact' => sub {
    is duration_exact(31626061),     '1 yr 1 day 1 hr 1 min 1 sec';
    is duration_exact(31626061 * 2), '2 yrs 2 days 2 hrs 2 min 2 sec';

    subtest 'false value' => sub {
        is duration_exact(),  '0 sec';
        is duration_exact(0), '0 sec';
    };
};

subtest 'duration' => sub {
    subtest 'default precision' => sub {
        is duration(31626061),    '1 yr 1 day';
        is duration(31626061, 0), '1 yr 1 day';
    };

    subtest 'specified precision' => sub {
        is duration(31626061, 3),     '1 yr 1 day 1 hr';
        is duration(31626061 * 2, 4), '2 yrs 2 days 2 hrs 2 min';
    };

    subtest 'false value' => sub {
        is duration(),  '0 sec';
        is duration(0), '0 sec';
    };
};

done_testing;

