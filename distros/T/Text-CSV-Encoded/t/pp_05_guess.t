#!/usr/bin/perl -w

use strict;
use Test::More;

#BEGIN { $ARGV[0] = 1; }

use lib qw(./t);
use _setup;

BEGIN {
    _setup->tests(6);
}


require './t/tests/05_guess.t';

__END__
