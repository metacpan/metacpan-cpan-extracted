#!/usr/bin/perl -w

use strict;
use Test::More;

use lib qw(./t);
use _setup;

BEGIN {
    _setup->tests(20);
}


require './t/tests/03_file.t';

__END__
