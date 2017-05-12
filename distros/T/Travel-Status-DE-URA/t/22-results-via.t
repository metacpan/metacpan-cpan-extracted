#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use utf8;

use List::Util qw(first);
use Test::More tests => 16;

BEGIN {
	use_ok('Travel::Status::DE::URA');
}
require_ok('Travel::Status::DE::URA');

my ($s, @results);

# via filter in ->results, implicit route_after

$s = Travel::Status::DE::URA->new(
	ura_base  => 'file:t/in',
	ura_version => 1,
	datetime  => DateTime->new(
		year   => 2013,
		month  => 12,
		day    => 23,
		hour   => 12,
		minute => 42,
		time_zone => 'Europe/Berlin'
	),
	hide_past => 0,
	stop      => 'Aachen Bushof',
);
@results = $s->results( via => 'Finkensief' );

is( @results, 5, '"Aachen Bushof" via_after Finkensief' );
ok( ( first { $_->line == 25 } @results ),
	'"Aachen Bushof" via_after "Brand" contains line 25' );
ok(
	( first { $_->destination eq 'Stolberg Mühlener Bf.' } @results ),
	'"Aachen Bushof" via_after "Brand" contains dest Stolberg Muehlener Bf.'
);
ok( ( first { $_->line == 1 } @results ),
	'"Aachen Bushof" via_after "Brand" contains line 1' );
ok(
	( first { $_->destination eq 'Schevenhütte' } @results ),
	'"Aachen Bushof" via_after "Brand" contains dest Schevenhuette'
);
is( ( first { $_->line != 1 and $_->line != 25 } @results ),
	undef, '"Aachen Bushof" via_after "Brand" does not contain other lines' );
is(
	(
		first {
			$_->destination ne 'Stolberg Mühlener Bf.'
			  and $_->destination ne 'Schevenhütte';
		}
		@results
	),
	undef,
	'"Aachen Bushof" via_after "Brand" does not contain other dests'
);

# via filter in ->results, explicit route calculation

$s = Travel::Status::DE::URA->new(
	ura_base  => 'file:t/in',
	ura_version => 1,
	hide_past => 0,
	stop      => 'Aachen Bushof',
);
@results = $s->results(
	via         => 'Finkensief',
	calculate_routes => 1,
);

is( @results, 5, '"Aachen Bushof" via_after Finkensief' );
ok( ( first { $_->line == 25 } @results ),
	'"Aachen Bushof" via_after "Brand" contains line 25' );
ok(
	( first { $_->destination eq 'Stolberg Mühlener Bf.' } @results ),
	'"Aachen Bushof" via_after "Brand" contains dest Stolberg Muehlener Bf.'
);
ok( ( first { $_->line == 1 } @results ),
	'"Aachen Bushof" via_after "Brand" contains line 1' );
ok(
	( first { $_->destination eq 'Schevenhütte' } @results ),
	'"Aachen Bushof" via_after "Brand" contains dest Schevenhuette'
);
is( ( first { $_->line != 1 and $_->line != 25 } @results ),
	undef, '"Aachen Bushof" via_after "Brand" does not contain anything else' );
is(
	(
		first {
			$_->destination ne 'Stolberg Mühlener Bf.'
			  and $_->destination ne 'Schevenhütte';
		}
		@results
	),
	undef,
	'"Aachen Bushof" via_after "Brand" does not contain other dests'
);

# via filter in ->results, explicit route_before

#$s = Travel::Status::DE::URA->new(
#	ura_base  => 'file:t/in',
#	ura_version => 1,
#	hide_past => 0,
#	stop      => 'Aachen Bushof',
#);
#@results = $s->results(
#	via         => 'Finkensief',
#);
#
#is( @results, 5, '"Aachen Bushof" via_before Finkensief' );
#ok( ( first { $_->line == 25 } @results ),
#	'"Aachen Bushof" via_after "Brand" contains line 25' );
#ok(
#	( first { $_->destination eq 'Vaals Heuvel' } @results ),
#	'"Aachen Bushof" via_after "Brand" contains dest Vaals Heuvel'
#);
#ok( ( first { $_->line == 1 } @results ),
#	'"Aachen Bushof" via_after "Brand" contains line 1' );
#ok(
#	( first { $_->destination eq 'Lintert Friedhof' } @results ),
#	'"Aachen Bushof" via_after "Brand" contains dest Lintert Friedhof'
#);
#is( ( first { $_->line != 1 and $_->line != 25 } @results ),
#	undef, '"Aachen Bushof" via_after "Brand" does not contain anything else' );
#is(
#	(
#		first {
#			$_->destination ne 'Vaals Heuvel'
#			  and $_->destination ne 'Lintert Friedhof';
#		}
#		@results
#	),
#	undef,
#	'"Aachen Bushof" via_after "Brand" does not contain other dests'
#);
