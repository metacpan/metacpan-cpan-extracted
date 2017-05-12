#!perl

use strict;
use warnings;
use utf8;
use Time::Duration::Abbreviated;

use Test::More;

subtest 'later_exact' => sub {
    is later_exact(31626061),  '1 yr 1 day 1 hr 1 min 1 sec later';
    is later_exact(-31626061), '1 yr 1 day 1 hr 1 min 1 sec ago';

    subtest 'aliased by from_now_exact()' => sub {
        is from_now_exact(31626061 * 2),  '2 yrs 2 days 2 hrs 2 min 2 sec later';
        is from_now_exact(-31626061 * 2), '2 yrs 2 days 2 hrs 2 min 2 sec ago';
    };

    subtest 'false value' => sub {
        is later_exact(),  'now';
        is later_exact(0), 'now';
        is from_now_exact(),  'now';
        is from_now_exact(0), 'now';
    };
};

subtest 'later' => sub {
    subtest 'default precision' => sub {
        is later(31626061),     '1 yr 1 day later';
        is later(31626061, 0),  '1 yr 1 day later';
        is later(-31626061),    '1 yr 1 day ago';
        is later(-31626061, 0), '1 yr 1 day ago';
    };

    subtest 'specified precision' => sub {
        is later(31626061 * 2, 3),  '2 yrs 2 days 2 hrs later';
        is later(-31626061 * 2, 3), '2 yrs 2 days 2 hrs ago';
    };

    subtest 'aliased by from_now()' => sub {
        is from_now(31626061 * 2),  '2 yrs 2 days later';
        is from_now(-31626061 * 2), '2 yrs 2 days ago';
    };

    subtest 'false value' => sub {
        is later(),  'now';
        is later(0), 'now';
        is from_now(),  'now';
        is from_now(0), 'now';
    };
};

done_testing;

