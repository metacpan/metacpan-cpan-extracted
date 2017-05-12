#!perl

use strict;
use warnings;

use Test::More;
use Test::Vars;

vars_ok 'Test::More';
vars_ok 'Test::Simple';
vars_ok 'Test::Builder';

done_testing;
