#!/usr/bin/perl -w
use 5.010;
use strict;
use warnings;
use Test::More;

use_ok("WebService::Beeminder");

my $bee = WebService::Beeminder->new(
    token => 'dummy',
);

isa_ok($bee, "WebService::Beeminder");

diag "Testing " . $bee->agent->agent;

done_testing;
