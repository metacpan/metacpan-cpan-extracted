#!perl

use strict;
use warnings;
use utf8;
use Time::Duration::Abbreviated;

use Test::More;

subtest 'earlier_exact' => sub {
    is earlier_exact(31626061),  '1 yr 1 day 1 hr 1 min 1 sec ago';
    is earlier_exact(-31626061), '1 yr 1 day 1 hr 1 min 1 sec later';

    subtest 'aliased by ago_exact()' => sub {
        is ago_exact(31626061 * 2),  '2 yrs 2 days 2 hrs 2 min 2 sec ago';
        is ago_exact(-31626061 * 2), '2 yrs 2 days 2 hrs 2 min 2 sec later';
    };

    subtest 'false value' => sub {
        is earlier_exact(),  'now';
        is earlier_exact(0), 'now';
        is ago_exact(),  'now';
        is ago_exact(0), 'now';
    };
};

subtest 'earlier' => sub {
    subtest 'default precision' => sub {
        is earlier(31626061),     '1 yr 1 day ago';
        is earlier(31626061, 0),  '1 yr 1 day ago';
        is earlier(-31626061),    '1 yr 1 day later';
        is earlier(-31626061, 0), '1 yr 1 day later';
    };

    subtest 'specified precision' => sub {
        is earlier(31626061 * 2, 3),  '2 yrs 2 days 2 hrs ago';
        is earlier(-31626061 * 2, 3), '2 yrs 2 days 2 hrs later';
    };

    subtest 'aliased by ago_exact()' => sub {
        is ago(31626061 * 2),  '2 yrs 2 days ago';
        is ago(-31626061 * 2), '2 yrs 2 days later';
    };

    subtest 'false value' => sub {
        is earlier(),  'now';
        is earlier(0), 'now';
        is ago(),  'now';
        is ago(0), 'now';
    };
};

done_testing;

