#!/usr/bin/env perl -w
use strict;
use Test::More;

BEGIN {
    unless (exists $ENV{TEST_PUBLIC_VIEWPOINTS}) {
        plan skip_all => "Will hit the app server, define TEST_PUBLIC_VIEWPOINTS env var needs to really run this test";
    }
}

use WebService::PublicViewpoints;

my @points = WebService::PublicViewpoints->find(num => 3, country_code => "US");

ok( scalar(@points) <= 3, "retrieved at most 3 points");

my $p = $points[0];

foreach my $field (qw(url country_code country state city lat lng)) {
    ok defined $p->$field, "should define $field";
}

foreach (@points) {
    is $_->country_code, "US", "The retrieved point are in US as specified"
}

done_testing;
