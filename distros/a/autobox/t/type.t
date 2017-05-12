#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 23;

use autobox DEFAULT => 'autobox::universal', UNDEF => 'autobox::universal';

my $undef;
my $integer = 42;
my $float = 3.1415927;
my $string = 'Hello, world!';
my @array;
my %hash;
my $sub = sub {};

is(undef->type, 'UNDEF');
is($undef->type, 'UNDEF');
is(42->type, 'INTEGER');
is($integer->type, 'INTEGER');
is(3.1415927->type, 'FLOAT');
is($float->type, 'FLOAT');
is(''->type, 'STRING');
is('Hello, world!'->type, 'STRING');
is($string->type, 'STRING');
is([]->type, 'ARRAY');
is(@array->type, 'ARRAY');
is({}->type, 'HASH');
is(%hash->type, 'HASH');
is((\&type)->type, 'CODE');
is($sub->type, 'CODE');

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

is($integer_to_string->type, 'STRING');
is($float_to_string->type, 'STRING');
is($float_to_integer->type, 'INTEGER');
is($integer_to_undef->type, 'UNDEF');
