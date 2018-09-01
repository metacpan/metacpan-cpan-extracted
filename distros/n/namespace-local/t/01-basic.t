#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

use Scalar::Util qw(refaddr);

throws_ok {
        # Add a deliberately failing canary test here
        is blessed( bless {}, "Foo" ), "Bar", "FAILED: blessed round-trip";
} qr/Undefined subroutine.*main::blessed/, "Don't leak upward";

do {
    use namespace::local;
    use Scalar::Util qw(blessed);

    lives_ok {
        ok !blessed {}, "Blessed works";
        is blessed( bless {}, "Foo" ), "Foo", "blessed round-trip";
    } "blesses lives";
};

throws_ok {
        # Add a deliberately failing canary test here
        is blessed( bless {}, "Foo" ), "Bar", "FAILED: blessed round-trip";
} qr/Undefined subroutine.*main::blessed/, "Don't leak after scope";

lives_ok {
    like refaddr {}, qr/\d+/, "refaddr check";
} "refaddr available because imported b4";

done_testing;

