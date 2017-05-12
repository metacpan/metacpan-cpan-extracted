#!/usr/bin/perl

use strict;
use warnings;

use Test::Most;

my $boss = require 't/prologue.pl';

my $search = $boss->PlaceFinder( q => '701 First Ave, Sunnyvale, CA' );
ok $search->count, 'has count';
is @{ $search->results }, $search->count, 'count matches';
isa_ok( $search->results->[0], 'WebService::Yahoo::BOSS::Response::PlaceFinder');

for my $flag (qw(B D Q R T U W X)) {
    ok $boss->PlaceFinder( q => '701 First Ave, Sunnyvale, CA', flags => $flag),
        "search with flag $flag";
}
ok $boss->PlaceFinder( q => '701 First Ave, Sunnyvale, CA', flags => "BDQRTUWX"),
    "search with combined flags";

ok $boss->PlaceFinder( q => '701 First Ave, Sunnyvale, CA', flags => "BDQRTUWX", gflags => "AC"),
    "search with combined flags and gflags";

# Runarb: 10 now 2015: 
#           This test appear to trigger an bug in boss where we sometimes get a 500 error,
#           and sometimes get an empty response. Commented out for now.
#
#$search = $boss->PlaceFinder( q => 'ThereIsNowhereWithThisName');
#ok $search->results, 'response for search with no results has results ref';
#is @{ $search->results }, 0, 'response results list is empty';

throws_ok { $boss->PlaceFinder( q => 'Sunnyvale, CA', nonesuchargument => 1) }
    qr/nonesuchargument/, 'throws exception on unknown parameter';

done_testing();
