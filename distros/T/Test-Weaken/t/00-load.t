#!perl

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    Test::More::use_ok('Test::Weaken');
}

Test::More::diag("Testing Test::Weaken $Test::Weaken::VERSION, Perl $], $^X");
