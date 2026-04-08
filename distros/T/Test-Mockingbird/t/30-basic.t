#!/usr/bin/env perl

use strict;
use warnings;
use Class::Simple;
use Test::Most;

use Test::Mockingbird;

my $simple = new_ok('Class::Simple');

ok(!$simple->can('first_method'));
ok(!$simple->can('second_method'));

my $first;
my $second;
mock 'Class::Simple::first_method' => sub { $first++; };
mock 'Class::Simple::second_method' => sub { $second++; };

$simple->first_method();
$simple->second_method();
$simple->second_method();

ok($simple->can('first_method'));
ok($simple->can('second_method'));

cmp_ok($first, '==', 1, 'first_method is mocked');
cmp_ok($second, '==', 2, 'second_method is mocked');

done_testing();
