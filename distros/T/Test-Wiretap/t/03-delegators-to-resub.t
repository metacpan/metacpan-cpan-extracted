#!/usr/bin/env perl

use Test::More tests => 8;

use lib 't/lib';
use lib 'lib';
use lib '../lib';
use Test::Wiretap;

{
  package SomePackage;

  sub function { }
}

# capturing of function args and return values
{
  my $tap = Test::Wiretap->new({
    name => 'SomePackage::function',
    capture => 1,
  });

  my @list = SomePackage::function(qw(a b c));
  my $scalar = SomePackage::function(qw(d e f));
  SomePackage::function(qw(g h i));

  # These all just come from Test::Resub; we need only test that
  # there's a delegator in place for them
  is_deeply( $tap->args, [
    [qw(a b c)],
    [qw(d e f)], 
    [qw(g h i)],
  ], '->args delegator' );

  is_deeply( $tap->method_args, [
    [qw(b c)],
    [qw(e f)], 
    [qw(h i)],
  ], '->method_args delegator' );

  is_deeply( $tap->named_method_args, [
    {b => 'c'},
    {e => 'f'},
    {h => 'i'},
  ], '->named_method_args delegator' ); 

  is_deeply( $tap->named_args(scalars => 1), [
    'a', {b => 'c'},
    'd', {e => 'f'},
    'g', {h => 'i'},
  ], '->named_args delegator' );

  is( $tap->called, 3, '->called delegator' );
  ok( $tap->was_called, '->was_called delegator' );
  ok( !$tap->not_called, '->not_called delegator' );

  $tap->reset;
  is( $tap->called, 0, '->reset delegator' );
}
