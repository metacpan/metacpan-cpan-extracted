#!/usr/bin/perl -w

package Foo;
use VSO;

package Reffy;
use VSO;

has 'strings' => (
  is        => 'ro',
  isa       => 'ArrayRef[Str]',
  required  => 1,
);

has 'foos' => (
  is        => 'ro',
  isa       => 'ArrayRef[Foo]',
  required  => 1,
);

has 'stringhash' => (
  is        => 'ro',
  isa       => 'HashRef[Str]',
  required  => 1,
);

has 'foohash' => (
  is        => 'ro',
  isa       => 'HashRef[Foo]',
  required  => 1,
);

package main;

use strict;
use warnings 'all';
use Test::More 'no_plan';

my %args = (
  strings     => [qw( foo bar baz )],
  foos        => [Foo->new],
  stringhash  => { foo => 'bar' },
  foohash     => {foo => Foo->new},
);

SUCCESS: {
  ok(
    my $reffy = Reffy->new( %args ),
    'Reffy.new(%args)'
  );
};



