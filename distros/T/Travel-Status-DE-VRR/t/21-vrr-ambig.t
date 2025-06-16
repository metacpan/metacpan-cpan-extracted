#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use utf8;

use File::Slurp qw(slurp);
use JSON;
use Test::More tests => 9;

BEGIN {
	use_ok('Travel::Status::DE::VRR');
}
require_ok('Travel::Status::DE::VRR');

my $json
  = JSON->new->utf8->decode( scalar slurp('t/in/essen_alfred_ambiguous.json') );

my $status = Travel::Status::DE::VRR->new( from_json => $json );

isa_ok( $status, 'Travel::Status::DE::VRR' );
can_ok( $status, qw(errstr results) );

$status->check_for_ambiguous();

is( $status->errstr, 'ambiguous name parameter', 'errstr ok' );

is_deeply( [ $status->place_candidates ], [], 'place candidates ok' );
is_deeply(
	[ map { $_->id_num . ' ' . $_->full_name } $status->name_candidates ],
	[
		'20009114 Essen, Alfred-Krupp-Schule',
		'20009113 Essen, Alfredbrücke',
		'20009115 Essen, Alfredusbad',
	],
	'name candidates ok'
);

is_deeply( [ $status->lines ],   [], 'no lines' );
is_deeply( [ $status->results ], [], 'no results' );
