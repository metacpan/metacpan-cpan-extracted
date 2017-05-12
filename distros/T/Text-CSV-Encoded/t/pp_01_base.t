#!/usr/bin/perl -w

use strict;
use Test::More;

use lib qw(./t);
use _setup;

BEGIN {
    _setup->tests(81);
}


require './t/tests/01_base.t';

__END__
