#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 5;
use Test::Easy::DataDriven qw(run_where);

my $foo = 'foo value';
my $bar = sub { uc(shift()) };
is( $foo, 'foo value', 'sanity test: $foo has correct default value' );
is( $bar->($foo), 'FOO VALUE', 'sanity test: $bar upper-cases its args' );

run_where(
  [\$foo => 'some different value'],
  [\$bar => sub { my $val = shift; $val =~ tr/aeiou//d; $val }],
  sub {
    is( $bar->($foo), 'sm dffrnt vl', '$foo and $bar swapped out' );
  },
);

is( $foo, 'foo value', '$foo is restored to its original value' );
is( $bar->($foo), 'FOO VALUE', '$bar is restored to its original value' );
