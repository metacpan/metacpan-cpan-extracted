#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Time::Format::MySQL qw(from_unixtime unix_timestamp);
use Test::Exception;

subtest basic => sub {
    TODO: {
        local $TODO = q|I do not understand stub timezone ... ;(|;
        ok 1;
    };

    like from_unixtime(time),
        qr!(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})!;

    like unix_timestamp('1990-01-11 19:05:00'),
        qr!^\d+$!;
};

subtest exception => sub {
    dies_ok   { from_unixtime() };
    lives_and { like unix_timestamp(), qr!^\d+$! };
};

subtest format => sub {
    like from_unixtime(time, '%Y%m%d %H%M%S'),
        qr!(\d{8} \d{6})!;

    like unix_timestamp('19900111 190500', '%Y%m%d %H%M%S'),
        qr!^\d+$!;
};

done_testing;
