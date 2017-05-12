#!/usr/bin/perl -w

package Foo;

use VSO;

package Bar;

use VSO;
extends 'Foo';


package main;

use strict;
use warnings 'all';
use Test::More 'no_plan';

use lib 't/lib';

use_ok('State');

my %args = (
  name        => 'Colorado',
  capital     => 'Denver',
  population  => 5_000_000,
  foo         => { blah => Bar->new },
  func        => sub { }
);

NORMAL: {
  eval {
    my $state = State->new();
  };
  ok $@, 'constructor without any args fails';
  eval {
    my $state = State->new(
      %args,
      name  => undef,
    );
  };
  like $@, qr(Required param 'name');
  
  eval {
    my $state = State->new(
      %args,
      capital  => undef,
    );
  };
  like $@, qr(Required param 'capital');
  
  eval {
    my $state = State->new(
      %args,
      population  => undef,
    );
  };
  like $@, qr(Required param 'population');
  
  eval {
    my $state = State->new(
      %args,
      population  => 'a string',
    );
  };
  ok $@, 'population as string in constructor causes failure';
  like $@, qr(Invalid value for State\.population: isn't a State::Population: \[Str\] 'a string': Population must be greater than zero), 'error looks right';
  
  my $state = State->new( %args );
  ok $state, "Got a new state object";

  is $state->name, 'Colorado', 'state.name is correct';
  is $state->capital, 'Denver', 'state.capital is correct';
  is $state->population, 5_000_000, 'state.population is correct';
  
  eval { $state->name('Texas') };
  is $state->name, 'Colorado', 'state.name not changed';
  like $@, qr(Cannot change readonly property 'name'), 'error looks right';
  
  $state->population( 8_500_000 );
  is $state->population, 8_500_000, 'state.population was changed';
  eval { $state->population('a string') };
  is $state->population, 8_500_000, 'state.population not changed';
  like $@, qr(Invalid value for State\.population: isn't a State::Population: \[Str\] 'a string': Population must be greater than zero), 'error looks right';
  
};


ALTERNATE_TYPES: {
#last;
  my $state = State->new(
    %args,
    func  => 'Hello'
  );
  
  # Void:
  $state->greet();
  # Scalar:
  my $val = $state->greet();
  is $val => 1, "state.greet in scalar context works";
  my @val = $state->greet();
  is_deeply \@val, [1..10], "state.greet in list context works";
};


