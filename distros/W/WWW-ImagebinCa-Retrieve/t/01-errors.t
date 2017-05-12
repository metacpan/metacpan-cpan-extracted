#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 2;

use WWW::ImagebinCa::Retrieve;

my $bin = WWW::ImagebinCa::Retrieve->new(timeout => 10);

my $response = $bin->retrieve(q|something_that_doesn't exit|);

ok(
    (not defined $response),
    'return from ->retrieve() must be undefined due to the error',
);

ok(
    (defined $bin->error),
    '->error() must be defined',
);