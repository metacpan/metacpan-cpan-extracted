#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 23;

use autobox::universal qw(type);

my $undef;
my $integer = 42;
my $float = 3.1415927;
my $string = 'Hello, world!';
my @array;
my %hash;
my $sub = sub {};

is(type(undef), 'UNDEF');
is(type($undef), 'UNDEF');
is(type(42), 'INTEGER');
is(type($integer), 'INTEGER');
is(type(3.1415927), 'FLOAT');
is(type($float), 'FLOAT');
is(type(''), 'STRING');
is(type('Hello, world!'), 'STRING');
is(type($string), 'STRING');
is(type([]), 'ARRAY');
is(type(\@array), 'ARRAY');
is(type({}), 'HASH');
is(type(\%hash), 'HASH');
is(type((\&type)), 'CODE');
is(type($sub), 'CODE');

my $integer_to_string = 42;
my $float_to_string = 3.1415927;
my $float_to_integer = 3.1515927;
my $integer_to_undef = 42;

$integer_to_string = 'Hello';
$float_to_string = 'World';
$float_to_integer = 42;
$integer_to_undef = undef;

is($integer_to_string, 'Hello');
is($float_to_string, 'World');
ok($float_to_integer == 42);
ok(not(defined($integer_to_undef)));

is(type($integer_to_string), 'STRING');
is(type($float_to_string), 'STRING');
is(type($float_to_integer), 'INTEGER');
is(type($integer_to_undef), 'UNDEF');
