#!/usr/bin/perl -w

use strict;
use Test::More;

use lib qw(./t);
use _setup;

BEGIN {
    _setup->tests(16);
}

require './t/tests/02_code.t';

__END__
