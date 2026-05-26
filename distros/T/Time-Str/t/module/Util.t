#!perl
use strict;
use warnings;

use Test::More;

use lib 't';
use Util qw[throws_ok];

BEGIN {
  use_ok('Time::Str::Util', qw[ lower_bound
                                range_bounds
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

## range_bounds

throws_ok { range_bounds() }
  qr/^Usage: range_bounds/,
  'range_bounds: no arguments';

throws_ok { range_bounds("not_a_ref", 10, 20) }
  qr/must be an array reference/,
  'range_bounds: non-ref argument';

throws_ok { range_bounds(\@arr, 30, 20) }
  qr/Parameter 'min_value' must not exceed 'max_value'/,
  'range_bounds: min > max';

# basic range
{
  my ($lo, $hi) = range_bounds(\@arr, 15, 35);
  is($lo, 1, 'range_bounds: lo for [15, 35]');
  is($hi, 3, 'range_bounds: hi for [15, 35]');
}

# exact match on boundaries
{
  my ($lo, $hi) = range_bounds(\@arr, 20, 40);
  is($lo, 1, 'range_bounds: lo for [20, 40]');
  is($hi, 4, 'range_bounds: hi for [20, 40]');
}

# range covers all elements
{
  my ($lo, $hi) = range_bounds(\@arr, 5, 55);
  is($lo, 0, 'range_bounds: lo for full range');
  is($hi, 5, 'range_bounds: hi for full range');
}

# range below all elements
{
  my ($lo, $hi) = range_bounds(\@arr, 1, 5);
  is($lo, 0, 'range_bounds: lo for range below all');
  is($hi, 0, 'range_bounds: hi for range below all');
}

# range above all elements
{
  my ($lo, $hi) = range_bounds(\@arr, 55, 60);
  is($lo, 5, 'range_bounds: lo for range above all');
  is($hi, 5, 'range_bounds: hi for range above all');
}

# single element match
{
  my ($lo, $hi) = range_bounds(\@arr, 30, 30);
  is($lo, 2, 'range_bounds: lo for single value');
  is($hi, 3, 'range_bounds: hi for single value');
}

# no elements in range
{
  my ($lo, $hi) = range_bounds(\@arr, 21, 29);
  is($lo, 2, 'range_bounds: lo for gap range');
  is($hi, 2, 'range_bounds: hi for gap range');
}

# empty array
{
  my ($lo, $hi) = range_bounds([], 10, 20);
  is($lo, 0, 'range_bounds: lo for empty array');
  is($hi, 0, 'range_bounds: hi for empty array');
}

# duplicates
{
  my @dup = (10, 20, 20, 20, 30);
  my ($lo, $hi) = range_bounds(\@dup, 20, 20);
  is($lo, 1, 'range_bounds: lo for duplicates');
  is($hi, 4, 'range_bounds: hi for duplicates');
}

# consistency: range_bounds matches lower_bound + upper_bound
{
  my ($lo, $hi) = range_bounds(\@arr, 15, 35);
  is($lo, lower_bound(\@arr, 15), 'range_bounds: lo matches lower_bound');
  is($hi, upper_bound(\@arr, 35), 'range_bounds: hi matches upper_bound');
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
