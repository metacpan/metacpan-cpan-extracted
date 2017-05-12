#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok 'Test::Slow';
}

diag "Testing Test::Slow $Test::Slow::VERSION, Perl $], $^X";
