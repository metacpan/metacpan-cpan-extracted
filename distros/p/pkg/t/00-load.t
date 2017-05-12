#!perl -T

use Test::More tests => 1;

BEGIN {
  use_ok('pkg');
}

diag( "Testing pkg $pkg::VERSION, Perl $], $^X" );
