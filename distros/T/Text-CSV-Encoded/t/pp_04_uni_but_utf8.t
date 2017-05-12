
use strict;
use Test::More;

use lib qw(./t);
use _setup;

BEGIN {
    _setup->tests(2);
}

require './t/tests/04_uni_but_utf8.t';
