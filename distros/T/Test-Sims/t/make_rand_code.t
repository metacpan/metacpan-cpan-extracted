#!/usr/bin/perl -w

use strict;
use warnings;

use lib 't/lib';
use Test::More;

plan skip_all => "Test requires Time::Piece" unless eval { require Time::Piece };

{
    package Sim::Date;

    use Test::Sims;

    make_rand seconds => sub {
        # Leap year calculations don't matter, its ok
        # if we leak into the next year.
        return int rand 366 * 24 * 60;
    };
}


{
    package Foo;

    Sim::Date->import(":rand");

    my $second = rand_seconds();
    ::like $second, qr/^\d+$/;
    ::cmp_ok $second, ">=", 0;
    ::cmp_ok $second, "<=", 366 * 24 * 60;
}

done_testing();
