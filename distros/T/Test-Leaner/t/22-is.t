#!perl -T

use strict;
use warnings;

BEGIN { delete $ENV{PERL_TEST_LEANER_USES_TEST_MORE} }

use Test::Leaner;

plan tests => 8;

is   undef, undef, 'undef is undef';
isnt 0,     undef, 'zero is not undef';
isnt undef, 0,     'undef is not zero';
is   0,     0,     'zero is zero';
is   1,     1,     'one is one';
isnt '1.0', 1,     '1.0 is not one string-wise';

my @fruits  = ('pear', 'apple');
my @veggies = ('lettuce', 'spinach');
is @fruits, @veggies, 'is() forces scalar context';
my @more_fruits = (@fruits, 'banana');
isnt @fruits, @more_fruits, 'isnt() forces scalar context';
