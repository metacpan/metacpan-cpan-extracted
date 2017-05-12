use strict;
use warnings;

use Test::More;

use autobox::Camelize;

my %TESTS = (
    'ThisIsATest'         => 'this_is_a_test',
    'ThisIsAnother::Test' => 'this_is_another__test',
);

is $_->decamelize, $TESTS{$_}, "passed decamelizing: $_"
    for keys %TESTS;

%TESTS = reverse (%TESTS);

is $_->camelize, $TESTS{$_}, "passed camelizing: $_"
    for keys %TESTS;

done_testing;
