package main;

use strict;
use warnings;

use Test::More 0.88;

require_ok 'Test::Prereq::Meta'
    or BAIL_OUT $@;

my $ms = eval { Test::Prereq::Meta->new() };
isa_ok $ms, 'Test::Prereq::Meta'
    or BAIL_OUT $@;

done_testing;

1;
