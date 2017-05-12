#!/usr/bin/perl -w

package State;
use VSO;

subtype 'StateName'
  => as 'Str'
  => where { join( ' ', map { ucfirst(lc($_)) } split /\s+/, $_) eq $_ };

coerce 'StateName'
  => from 'Str'
  => via  { join( ' ', map { ucfirst(lc($_)) } split /\s+/, $_) };

has 'name' => (
  is        => 'rw',
  isa       => 'StateName',
  required  => 1,
  coerce    => 1,
);

has 'population' => (
  is        => 'rw',
  isa       => 'Int',
  required  => 1,
);

package main;

use strict;
use warnings 'all';
use Test::More 'no_plan';

ok(
  my $CO = State->new( name => 'Colorado', population => 5_000_000 ),
  'Colorado'
);

ok(
  my $CA = State->new( name => 'California', population => 30_000_000 ),
  'California'
);


