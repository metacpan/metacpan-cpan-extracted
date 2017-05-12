#! perl -w

use strict;
use warnings;

use Test::More tests =>
  + 9
  + 2
;
use Tripletail '/dev/null';

&test_select;
&test_args;

# -----------------------------------------------------------------------------
# method select.
#
sub test_select
{
  my $called;
  local(*DoTest1) = sub{
    $called = 'test1';
  };
  local(*DoTest2);# avoid 'once'
  local(*DoTest2) = sub{
    $called = 'test2';
  };
  my $succ;

  $called = undef;
  pass('[sel] call Test1');
  $succ = $TL->dispatch("Test1");
  ok($succ, '[sel] - dispatch succeeded');
  is($called, 'test1', '[sel] - test1 has called');

  $called = undef;
  pass('[sel] call Test2');
  $succ = $TL->dispatch("Test2");
  ok($succ, '[sel] - dispatch succeeded');
  is($called, 'test2', '[sel] - test2 has called');

  $called = undef;
  pass('[sel] call Test3 (nofunc)');
  $succ = $TL->dispatch("Test3");
  ok(!$succ, '[sel] - dispatch failed');
  is($called, undef, '[sel] - no func has called');
}

# -----------------------------------------------------------------------------
# args parameter.
#
sub test_args
{
  my $actual_args;
  local(*DoTest1) = sub{
    $actual_args = [@_];
  };

  my $args = [ \1, \2 ];
  my $succ = $TL->dispatch("Test1", args => $args);
  ok($succ, '[args] dispatch succeeded');
  is_deeply($actual_args, $args, '[args] valid args');
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
