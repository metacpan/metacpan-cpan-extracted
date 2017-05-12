#!/usr/bin/env perl

use Test::More tests => 1;

BEGIN {
  use_ok( 'Test::Resub' );
}

diag( "Testing Test::Resub $Test::Resub::VERSION, Perl $], $^X" );
