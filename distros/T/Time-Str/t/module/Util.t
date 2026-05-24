#!perl
use strict;
use warnings;

use Test::More;

use lib 't';
use Util qw[throws_ok];

BEGIN {
  use_ok('Time::Str::Util', qw[ lower_bound
                                upper_bound ]);
}

my @arr = (10, 20, 30, 40, 50);

## lower_bound

throws_ok { lower_bound() }
  qr/^Usage: lower_bound/,
  'lower_bound: no arguments';

throws_ok { lower_bound("not_a_ref", 10) }
  qr/must be an array reference/,
  'lower_bound: non-ref argument';

is(lower_bound(\@arr, 5), 0,
  'lower_bound: value below all');

is(lower_bound(\@arr, 10), 0,
  'lower_bound: matches first');

is(lower_bound(\@arr, 15), 1,
  'lower_bound: between 10 and 20');

is(lower_bound(\@arr, 25), 2,
  'lower_bound: between 20 and 30');

is(lower_bound(\@arr, 30), 2,
  'lower_bound: matches middle');

is(lower_bound(\@arr, 50), 4,
  'lower_bound: matches last');

is(lower_bound(\@arr, 55), 5,
  'lower_bound: value above all');

is(lower_bound(\@arr, 25, 1, 4), 2,
  'lower_bound: with lo/hi bounds');

is(lower_bound(\@arr, 5, 2, 5), 2,
  'lower_bound: value below search range');

is(lower_bound([], 10), 0,
  'lower_bound: empty array');

is(lower_bound([42], 41), 0,
  'lower_bound: single element, value below');

is(lower_bound([42], 42), 0,
  'lower_bound: single element, value equal');

is(lower_bound([42], 43), 1,
  'lower_bound: single element, value above');

# duplicates
{
  my @dup = (10, 20, 20, 20, 30);
  is(lower_bound(\@dup, 20), 1,
    'lower_bound: duplicates, finds first');
}

## upper_bound

throws_ok { upper_bound() }
  qr/^Usage: upper_bound/,
  'upper_bound: no arguments';

throws_ok { upper_bound("not_a_ref", 10) }
  qr/must be an array reference/,
  'upper_bound: non-ref argument';

is(upper_bound(\@arr, 5), 0,
  'upper_bound: value below all');

is(upper_bound(\@arr, 10), 1,
  'upper_bound: matches first');

is(upper_bound(\@arr, 15), 1,
  'upper_bound: between 10 and 20');

is(upper_bound(\@arr, 25), 2,
  'upper_bound: between 20 and 30');

is(upper_bound(\@arr, 30), 3,
  'upper_bound: matches middle');

is(upper_bound(\@arr, 50), 5,
  'upper_bound: matches last');

is(upper_bound(\@arr, 55), 5,
  'upper_bound: value above all');

is(upper_bound(\@arr, 30, 1, 4), 3,
  'upper_bound: with lo/hi bounds');

is(upper_bound(\@arr, 55, 2, 5), 5,
  'upper_bound: value above search range');

is(upper_bound([], 10), 0,
  'upper_bound: empty array');

is(upper_bound([42], 41), 0,
  'upper_bound: single element, value below');

is(upper_bound([42], 42), 1,
  'upper_bound: single element, value equal');

is(upper_bound([42], 43), 1,
  'upper_bound: single element, value above');

# duplicates
{
  my @dup = (10, 20, 20, 20, 30);
  is(upper_bound(\@dup, 20), 4,
    'upper_bound: duplicates, finds past last');
}

## lower_bound vs upper_bound relationship

# For unique values: lower_bound == upper_bound when value not in array
is(lower_bound(\@arr, 15), upper_bound(\@arr, 15),
  'lower == upper for non-matching value');

# For matching values: upper_bound = lower_bound + 1 (unique elements)
is(upper_bound(\@arr, 30), lower_bound(\@arr, 30) + 1,
  'upper = lower + 1 for matching unique value');

# For duplicates: upper - lower = count of matching elements
{
  my @dup = (10, 20, 20, 20, 30);
  is(upper_bound(\@dup, 20) - lower_bound(\@dup, 20), 3,
    'upper - lower = count of duplicates');
}

## negative values
{
  my @neg = (-50, -30, -10, 0, 10, 30);
  is(lower_bound(\@neg, -30), 1,
    'lower_bound: negative value match');
  is(upper_bound(\@neg, -30), 2,
    'upper_bound: negative value match');
  is(lower_bound(\@neg, -20), 2,
    'lower_bound: between negatives');
}

done_testing;
