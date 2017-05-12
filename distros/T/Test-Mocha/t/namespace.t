#!/usr/bin/perl -T

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok 'Test::Mocha';
}

my %permitted = map { $_ => 1 } qw(
  AUTOLOAD
  BEGIN
  can
  DESTROY
  DOES
  import
  ISA
  isa
  VERSION
);

for ( 'Test::Mocha::Mock', 'Test::Mocha::Spy' ) {
    no strict 'refs';
    my @nonpermitted = grep { !$permitted{$_} && !/^_/ } keys %{ $_ . '::' };
    ok( 0 == scalar(@nonpermitted), "$_ namespace is clean" )
      or diag( join ', ', @nonpermitted );
}

done_testing;
