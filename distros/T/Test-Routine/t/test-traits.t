#!/bin/env perl
use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Routine;
use Test::Routine::Util;

use namespace::autoclean;

{
  package Test::Routine::Role::TestWithFlavor;
  use Moose::Role;

  has flavor => (
    is   => 'ro',
    isa  => 'Str',
    default => sub { 'vanilla' },
  );

  around skip_reason => sub {
    my ($orig, $self, $test_instance) = @_;

    return unless $test_instance->can('only_flavor');
    return unless $test_instance->only_flavor;
    return if $test_instance->only_flavor eq $self->flavor;

    return sprintf "only running %s tests, but test is %s flavor",
      $test_instance->only_flavor,
      $self->flavor;

    return $self->$orig($test_instance);
  };

  no Moose::Role;
}

{
  package Test::Routine::TestsHaveFlavor;

  use Moose::Role;

  sub test_routine_test_traits {
    return 'Test::Routine::Role::TestWithFlavor';
  }

  no Moose::Role;
}

with 'Test::Routine::TestsHaveFlavor';

has only_flavor => (
  is  => 'ro',
  isa => 'Str',
);

test "I like bananas" => sub {
  my ($self) = @_;
  ok(1);
};

test "Do you like bananas" => sub {
  my ($self) = @_;
  ok(1);
};

test "No, cucumbers are best" => { flavor => 'cuke' } => sub {
  my ($self) = @_;
  ok(1);
};

run_me;
run_me({ only_flavor => 'vanilla' });
run_me({ only_flavor => 'cuke' });
done_testing;
