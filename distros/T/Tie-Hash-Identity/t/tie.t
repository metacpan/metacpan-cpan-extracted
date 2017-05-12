#!perl -T

use strict;
use warnings;
use Test::More tests => 4;

use_ok('Tie::Hash::Identity');

tie my %h, 'Tie::Hash::Identity';

is($h{abc}, 'abc', '$h{abc}');
is($h{1+2}, '3', '$h{1+2}');
is("abc$h{ 2 ** 3 }def", 'abc8def', '$h{2**3}');
