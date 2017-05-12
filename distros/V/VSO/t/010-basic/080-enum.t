#!/usr/bin/perl -w

package Foo;
use VSO;

enum 'DayOfWeek' => [qw( Sun Mon Tue Wed Thu Fri Sat )];

has 'day' => (
  is        => 'ro',
  isa       => 'DayOfWeek',
  required  => 1,
);

package main;

use strict;
use warnings 'all';
use Test::More 'no_plan';

GOOD: {
  ok(
    Foo->new( day => 'Mon' ),
    'Foo.new(day=>Mon) works'
  );
};

BAD: {
  eval {
    Foo->new( day => 'Blargh' )
  };
  like $@, qr(Must be a valid 'DayOfWeek');
};

