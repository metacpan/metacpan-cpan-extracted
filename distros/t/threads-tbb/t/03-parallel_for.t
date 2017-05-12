#!/usr/bin/perl
#
#  first test of actual parallelisation
#

use Test::More no_plan;
use strict;
use lib "t";
use StaticCB;  # master thread needs it too
BEGIN { use_ok("threads::tbb") };

tie my @array, "threads::tbb::concurrent::array";
pass("made an array");
push @array, qw(Parker Lady_Penelope Brains Virgil_Tracy Jeff_Tracey
		John_Tracy Kyrano The_Hood Tin_Tin Alan_Tracy);
is(@array, 10, "put 10 strings in it");

my $tbb = threads::tbb->new(
	threads => 4,
	modules => [ "StaticCB" ],
);

my $range = threads::tbb::blocked_int->new(0, scalar(@array), 2);
is($range->end, 10, "Made a blocked range");

my $body = $tbb->for_int_array_func( tied(@array), "StaticCB::myhandler" );

isa_ok($body, "threads::tbb::for_int_array_func", "new for_int_array_func");

$body->parallel_for($range);

pass("didn't crash!");

my @mapped = $tbb->map_list_func("StaticCB::map_func", 1, 10, 15, 5, 3);

use Data::Dumper;
is_deeply(\@mapped, [ 1, 3, 3, 1, 1, 1, 5, 3 ], "map_list_func")
	or diag Dumper \@mapped;
