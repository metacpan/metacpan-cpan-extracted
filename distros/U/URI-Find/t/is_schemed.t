#!/usr/bin/perl -w

use strict;

use Test::More 'no_plan';

use URI::Find;

my @tests = (
    ["http://foo.bar"   => 1],
    ["foo.com"          => 0],
);

for my $test (@tests) {
    my($uri, $want) = @$test;
    is !!URI::Find->is_schemed($uri), !!$want, "is_schemed($uri)";
}
