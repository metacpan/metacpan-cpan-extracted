#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/eval';
use Test::More;

no circular::require;

use_ok('Foo');

done_testing;
