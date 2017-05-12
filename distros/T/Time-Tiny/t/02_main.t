#!/usr/bin/perl

# Main testing for Time::Tiny

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 15;
use Time::Tiny ();





#####################################################################
# Basic test

SCOPE: {
	my $tiny = Time::Tiny->new(
		hour   => 1,
		minute => 2,
		second => 3,
	);
	isa_ok( $tiny, 'Time::Tiny' );
	is( $tiny->hour,  '1', '->hour ok'   );
	is( $tiny->minute, 2,  '->minute ok' );
	is( $tiny->second, 3,  '->second ok' );
	is( $tiny->as_string, '01:02:03', '->as_string ok' );
	is( "$tiny", '01:02:03', 'Stringification ok' );
	is_deeply(
		Time::Tiny->from_string( $tiny->as_string ),
		$tiny, '->from_string ok',
	);

	my $now = Time::Tiny->now;
	isa_ok( $now, 'Time::Tiny' );
}





#####################################################################
# DateTime Testing

SKIP: {
	# Do we have DateTime
	eval { require DateTime };
	skip( "Skipping DateTime tests (not installed)", 7 ) if $@;

	# Create a normal date
	my $date = Time::Tiny->new(
		hour   => 1,
		minute => 2,
		second => 3,
	);
	isa_ok( $date, 'Time::Tiny' );

	# Expand to a DateTime
	my $dt = $date->DateTime;
	isa_ok( $dt, 'DateTime' );
	# DateTime::Locale version 1.00 changes "C" to "en-US-POSIX".
	my $expected = eval { DateTime::Locale->VERSION(1) } ? "en-US-POSIX" : "C";
	is( $dt->locale->id,      $expected,  '->locale ok'   );
	is( $dt->time_zone->name, 'floating', '->timezone ok' );

	# Compare accessor results
	is( $date->hour,   $dt->hour,   '->year matches'  );
	is( $date->minute, $dt->minute, '->month matches' );
	is( $date->second, $dt->second, '->day matches'   );
}
