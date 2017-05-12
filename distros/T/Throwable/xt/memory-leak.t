#!perl

use strict;
use warnings;
use Test::More;
use Test::Memory::Cycle;

{
  package MyError;
  use Moo;
  extends 'Throwable::Error';
}

eval { MyError->throw('the error') };
memory_cycle_ok($@, 'Exception has no memory cycles');

done_testing();
