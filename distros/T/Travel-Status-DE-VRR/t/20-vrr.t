#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use utf8;

use Encode      qw(decode);
use File::Slurp qw(slurp);
use JSON;
use Test::More tests => 112;

BEGIN {
	use_ok('Travel::Status::DE::VRR');
}
require_ok('Travel::Status::DE::VRR');

my $json = JSON->new->utf8->decode( scalar slurp('t/in/essen_bp.json') );

my $status = Travel::Status::DE::VRR->new( from_json => $json );

isa_ok( $status, 'Travel::Status::DE::EFA' );
can_ok( $status, qw(errstr results) );

is( $status->errstr, undef, 'no error' );

my @results = $status->results;

for my $result (@results) {
	isa_ok( $result, 'Travel::Status::DE::EFA::Departure' );
	can_ok( $result,
		qw(datetime destination hints line type platform sched_datetime) );
}

is(
	$results[0]->destination,
	'Essen Germaniaplatz',
	'first result: destination ok'
);
is_deeply( [ $results[0]->hints ], [], 'first result: no hints' );
is( $results[0]->line, '106', 'first result: line ok' );
is( $results[0]->datetime->strftime('%d.%m.%Y'),
	'21.09.2024', 'first result: real date ok' );
is( $results[0]->datetime->strftime('%H:%M'),
	'18:35', 'first result: real time ok' );
is( $results[0]->delay, 0, 'first result: delay 0' );
is( $results[0]->sched_datetime->strftime('%d.%m.%Y'),
	'21.09.2024', 'first result: scheduled date ok' );
is( $results[0]->sched_datetime->strftime('%H:%M'),
	'18:35', 'first result: scheduled time ok' );
is( $results[0]->mot_name, 'tram', 'first result: mot_name ok' );

is(
	$results[3]->destination,
	'Gelsenkirchen Buerer Str.',
	'fourth result: destination ok'
);
is_deeply( [ $results[3]->hints ], [], 'fourth result: no hints' );
is( $results[3]->line, 'U11', 'fourth result: line ok' );
is( $results[3]->datetime->strftime('%d.%m.%Y'),
	'21.09.2024', 'fourth result: real date ok' );
is( $results[3]->datetime->strftime('%H:%M'),
	'18:36', 'fourth result: real time ok' );
is( $results[3]->delay, 0, 'fourth result: delay 0' );
is( $results[3]->sched_datetime->strftime('%d.%m.%Y'),
	'21.09.2024', 'fourth result: scheduled date ok' );
is( $results[3]->sched_datetime->strftime('%H:%M'),
	'18:36', 'fourth result: scheduled time ok' );
is( $results[3]->mot_name, 'u-bahn', 'fourth result: mot_name ok' );

is(
	$results[-1]->destination,
	'Essen Zeche Ludwig',
	'last result: destination ok'
);
is_deeply( [ $results[-1]->hints ], [], 'last result: no hints' );
is( $results[-1]->delay, 0,     'last result: delay 0' );
is( $results[-1]->line,  '105', 'last result: line ok' );
is( $results[-1]->datetime->strftime('%d.%m.%Y'),
	'21.09.2024', 'last result: date ok' );
is( $results[-1]->datetime->strftime('%H:%M'), '19:08',
	'last result: time ok' );
is( $results[-1]->sched_datetime->strftime('%d.%m.%Y'),
	'21.09.2024', 'first result: scheduled date ok' );
is( $results[-1]->sched_datetime->strftime('%H:%M'),
	'19:08', 'last result: scheduled time ok' );
is( $results[-1]->mot_name, 'tram', 'last result: mot_name ok' );
