#! /usr/bin/perl

use strict;
use Test::More;

if ($ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING}) {
        eval "use Test::Distribution";
        plan skip_all => "Test::Distribution required for checking distribution" if $@;
} else {
        plan skip_all => "Author tests not required for installation";
}

