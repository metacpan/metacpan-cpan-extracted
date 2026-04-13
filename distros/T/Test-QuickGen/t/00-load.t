#!perl -T

use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
  use_ok('Test::QuickGen') || print "Bail out!\n";
}

diag(
  "Testing Test::QuickGen $Test::QuickGen::VERSION, Perl $], $^X"
);
