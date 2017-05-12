#!/usr/bin/perl

# Basic tests on interpolating against hash references

use 5.008;
use strict;
use warnings;

use Test::More;

use YASF;

my $master_data = {
    one    => 1,
    two    => 2,
    three  => 3,
    month1 => 'January',
    month2 => 'February',
    month3 => 'March',
};

plan tests => 9;

my ($str, $data);

# Basic instantiation has already been tested. At this point, we assume that
# creating the objects works correctly.

$str = YASF->new('1={one} 2={two} 3={three}');

# Basic substitution with explicit data
is($str % $master_data, '1=1 2=2 3=3', 'Basic % substitution');
is($str->format($master_data), '1=1 2=2 3=3', 'Basic format() substitution');

# Basic substitution with bound data
$str->bind($master_data);
is($str->format, '1=1 2=2 3=3', 'format() substitution with bindings');
is($str, '1=1 2=2 3=3', 'Direct stringification');

# With bound data, verify that explicit data overrides the bound data:
$data = { one => 'one', two => 'two', three => 'three' };
is($str % $data, '1=one 2=two 3=three', 'Basic %, with override data');
is($str->format($data), '1=one 2=two 3=three', 'Basic format with overrides');

# Try some very basic nested keys. Not indexing, just partial substitution.
$str = YASF->new('{month{one}} {month{two}} {month{three}}');
is($str % $master_data, 'January February March', 'Basic %, nested keys');
is($str->format($master_data), 'January February March',
   'Basic format(), nested keys');

# Make sure leading and trailing content is preserved.
$str = YASF->new('pre 1={one} 2={two} 3={three} post');
is($str % $master_data, 'pre 1=1 2=2 3=3 post',
   'Prefix and postfix in templates');

exit;
