#!/usr/bin/env perl

use Test::More tests => 9;

use lib 't/lib';
use lib 'lib';
use lib '../lib';
use Test::Wiretap;

my @function_args;
{
  package SomePackage;

  sub function {
    @function_args = @_;
    return wantarray ? qw(a list of values) : 'single-value';
  }
}

# Arguments to the tap functions:
#  before gets @_
#  after gets ([@_], [@returned])
{
  my (@before_args, @after_args) = @_;
  my $tap = Test::Wiretap->new({
    name => 'SomePackage::function',
    before => sub { @before_args = @_ },
    after => sub { @after_args = @_ },
  });

  my @list_context_return = SomePackage::function('a', 'b', 'c');

  is_deeply( \@before_args, [qw(a b c)], "'before' sub gets the original args" );
  is_deeply( \@function_args, [qw(a b c)], "original function gets the original args" );
  is_deeply( \@after_args, [
    [qw(a b c)],
    [qw(a list of values)],
    'list',
  ], "'after' sub gets the original args, return values, and call context" );

  is_deeply( \@list_context_return, [qw(a list of values)],
    'list-context returns work' );

  # a little more detail on the return values: scalar context
  my $scalar_context_return = SomePackage::function('a', 'b');

  is_deeply( \@function_args, [qw(a b)],
    "original function gets the original args (2)" );
  is_deeply( \@after_args, [
    [qw(a b)],
    'single-value',
    'scalar',
  ], "'after' sub gets the original args, return values, and call context (2)" );

  is( $scalar_context_return, 'single-value', "scalar-context returns work" );

  # a little more detail on the return values: void context
  SomePackage::function(qw(x y z));

  is_deeply( \@function_args, [qw(x y z)],
    "original function gets the original args (3)" );
  is_deeply( \@after_args, [
    [qw(x y z)],
    undef,
    'void',
  ], "'after' sub gets the original args, return values, and call context (3)" );
}
