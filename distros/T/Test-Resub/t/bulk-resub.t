#!/usr/bin/env perl

use strict;
use warnings;

use lib '../lib';
use Test::Resub qw(bulk_resub);

use Test::More tests => 2;

{
  package Somewhere;

  sub dispatch_table {
    return (
      add => \&do_add,
      get => \&do_get,
    );
  }
}

my %d = (
  add => sub { 'add' },
  get => sub { 'get' },
);

my %rs = bulk_resub 'Somewhere', \%d, create => 1;
is( Somewhere->add, 'add' );
is( Somewhere->get, 'get' );
