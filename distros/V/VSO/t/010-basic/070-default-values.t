#!/usr/bin/perl -w

package Thing;
use VSO;
has 'name' => (
  is        => 'rw',
  isa       => 'Str',
  required  => 1,
  default   => sub { 'dakine' }
);

package main;

use strict;
use warnings 'all';
use Test::More 'no_plan';


DEFAULT: {
  ok( my $obj = Thing->new(), 'Thing.new' );
  is $obj->name => 'dakine', 'default was used';
  ok $obj->name('Smith'), 'changed name';
  is $obj->name => 'Smith', 'name-change stuck';
};

PROVIDED: {
  ok( my $obj = Thing->new(name => 'Will'), 'Thing.new' );
  is $obj->name => 'Will', 'default was used';
  ok $obj->name('Smith'), 'changed name';
  is $obj->name => 'Smith', 'name-change stuck';
};


