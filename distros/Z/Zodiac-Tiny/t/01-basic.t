#!perl

use 5.010;
use strict;
use warnings;

use Test::More 0.98;
use Zodiac::Tiny qw(zodiac_of);

is(zodiac_of("2015-11-28"), "sagittarius");

subtest "DateTime" => sub {
    plan skip_all => "DateTime not available"
        unless eval { require DateTime; 1 };
    is(zodiac_of(DateTime->new(year=>2000, month=>12, day=>25)), "capricornus");
};

subtest "Time::Moment" => sub {
    plan skip_all => "Time::Moment not available"
        unless eval { require Time::Moment; 1 };
    is(zodiac_of(Time::Moment->new(year=>2000, month=>12, day=>25)),
       "capricornus");
    done_testing;
};

done_testing;
