#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

sub add {
    use namespace::local;
    our $x += shift;
    return $x;
};

is add( 2 ), 2, "Add works";
is add( 3 ), 5, "Add is stateful";
is $main::x || $main::x, undef, "No such variable";

done_testing;
