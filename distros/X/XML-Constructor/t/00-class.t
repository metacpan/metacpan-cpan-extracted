#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

our $CLASS;

plan tests  => 2;

BEGIN {
  $CLASS  = 'XML::Constructor';
  use_ok( $CLASS );
  can_ok( $CLASS, qw/generate toString/ );
  diag( "Testing XML::Constructor $XML::Constructor::VERSION, Perl $], $^X" );
}

done_testing;
