#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use Test::NoWarnings qw//;

use Test::Exception;
use Hook::LexWrap;

TODO: {
    local $TODO = "waiting for Hook::LexWrap's caller() to be fixed (see cpan rt ticket #38892)";
    # This is a problem when Test::UniqueTestNames is used along with Test::Exception
    #   Test::UniqueTestNames uses Hook::LexWrap, which doesn't declare the right prototype for caller.
    #   The rt ticket above provides the patch for that.
    Test::NoWarnings::had_no_warnings;
}
