#!/usr/bin/perl -w

package Bar;

package Foo;
use VSO;

has 'name' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 1,
);

has 'ua' => (
  is        => 'ro',
  default   => sub {
    bless { }, 'Bar';
  }
);

package main;

use strict;
use warnings 'all';
use Test::More 'no_plan';

ok(
  my $foo = Foo->new(name => 'Bob'),
  'Foo.new(bob)'
);

ok(
  $foo->ua,
  'foo.ua'
);


