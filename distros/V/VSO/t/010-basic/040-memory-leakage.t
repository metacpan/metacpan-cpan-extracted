#!/usr/bin/perl -w

package Foo;

use VSO;

package main;

use strict;
use warnings 'all';
use Test::More 'no_plan';
eval {
  require Test::Memory::Cycle;
  Test::Memory::Cycle->import;
};
if( $@ )
{
  warn "Test::Memory::Cycle required for these tests\n";
  ok(1);
  exit(0);
}# end if()

use lib 't/lib';
use State;

for( 1..1000 )
{
my $state = State->new(
  name        => 'Colorado',
  capital     => 'Denver',
  population  => 5_000_000,
  foo         => { bar => bless {}, 'Foo' },
  func        => sub { }
);

memory_cycle_ok( $state );
last;
}

