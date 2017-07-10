#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use Type::Simple qw(
  validate
  Str
  Alpha
  Alnum
  Ascii
  Num
  Print
  Punct
  Space
  Word
);

my @tests = (
    {
        value  => 'xyz',
        isa    => Str(),
        result => 1,
    },
    {
        value  => 'xyz',
        isa    => Alpha(),
        result => 1,
    },
    {
        value  => 'xyz123',
        isa    => Alpha(),
        result => 0,
    },
    {
        value  => 'xyz123',
        isa    => Alnum(),
        result => 1,
    },
    {
        value  => 'xyz123',
        isa    => Ascii(),
        result => 1,
    },
    {
        value  => "\x{263A}",
        isa    => Ascii(),
        result => 0,
    },
    {
        value  => "\x{263A}",
        isa    => Print(),
        result => 1,
    },
    {
        value  => 'xyz123',
        isa    => Num(),
        result => 0,
    },
    {
        value  => '123',
        isa    => Num(),
        result => 1,
    },
    {
        value  => 'abc 123',
        isa    => Alnum(),
        result => 0,
    },
    {
        value  => 'abc 123',
        isa    => Print(),
        result => 1,
    },
    {
        value  => 'abc 123',
        isa    => Punct(),
        result => 0,
    },
    {
        value  => '!@#$%^&*()',
        isa    => Punct(),
        result => 1,
    },
    {
        value  => "\t",
        isa    => Space(),
        result => 1,
    },
    {
        value  => 'foo_bar',
        isa    => Word(),
        result => 1,
    },
);

foreach my $test (@tests) {
    is( validate( $test->{isa}, $test->{value} ), $test->{result} );
}
