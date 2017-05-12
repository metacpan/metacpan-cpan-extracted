#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
 use_ok('Variable::Temp');
}

diag("Testing Variable::Temp $Variable::Temp::VERSION, Perl $], $^X");
