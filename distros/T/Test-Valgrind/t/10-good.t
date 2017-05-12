#!perl

use strict;
use warnings;

use Test::More;

use lib 't/lib';

eval {
 require Test::Valgrind;
 Test::Valgrind->import(
  diag           => 1,
  regen_def_supp => 1,
 );
};
if ($@) {
 diag $@;
 plan skip_all
        => 'Test::Valgrind is required to test your distribution with valgrind';
}

{
 package Test::Valgrind::Test::Fake;

 use base qw<strict>;
}

plan tests => 1;
fail 'dummy test in the child, should not interfere with the actual TAP stream';
