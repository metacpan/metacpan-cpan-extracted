#!perl

use strict;
use warnings;

use Test::More;

use lib 't/lib';

eval {
 require Test::Valgrind;
 Test::Valgrind->import(diag => 1);
};
if ($@) {
 diag $@;
 plan skip_all
        => 'Test::Valgrind is required to test your distribution with valgrind';
}

die 'dummy run-time exception, should not cause the test to fail';
