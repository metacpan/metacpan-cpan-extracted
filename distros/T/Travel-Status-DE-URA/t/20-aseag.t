#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use utf8;

use Encode qw(decode);
use List::Util qw(first);
use Test::More tests => 23;
use Test::Fatal;

BEGIN {
	use_ok('Travel::Status::DE::URA');
}
require_ok('Travel::Status::DE::URA');

like(
	exception {
		Travel::Status::DE::URA->new( ura_base => 'file:t/in' );
	},
	qr{ura_base and ura_version are mandatory},
	'ura_base / ura_version are mandatory'
);

like(
	exception {
		Travel::Status::DE::URA->new( ura_version => 1 );
	},
	qr{ura_base and ura_version are mandatory},
	'ura_base / ura_version are mandatory'
);

like(
	exception { Travel::Status::DE::URA->new() },
	qr{ura_base and ura_version are mandatory},
	'ura_base / ura_version are mandatory'
);

is(
	exception {
		Travel::Status::DE::URA->new(
			ura_base    => 'file:t/in',
			ura_version => 1
		);
	},
	undef,
	'ura_base / ura_version are the only mandatory args'
);

my $s = Travel::Status::DE::URA->new(
	ura_base    => 'file:t/nope',
	ura_version => 1,
	datetime    => DateTime->new(
		year      => 2013,
		month     => 12,
		day       => 24,
		hour      => 12,
		minute    => 42,
		time_zone => 'Europe/Berlin'
	),
	hide_past => 0
);

isa_ok( $s, 'Travel::Status::DE::URA' );
can_ok( $s, qw(errstr results) );
like( $s->errstr, qr{404}, 'errstr is set' );
is_deeply( [ $s->results ], [], 'no results' );

$s = Travel::Status::DE::URA->new(
	ura_base    => 'file:t/in',
	ura_version => 1,
	datetime    => DateTime->new(
		year      => 2013,
		month     => 12,
		day       => 24,
		hour      => 12,
		minute    => 42,
		time_zone => 'Europe/Berlin'
	),
	hide_past => 0
);

isa_ok( $s, 'Travel::Status::DE::URA' );
can_ok( $s, qw(errstr results) );

is( $s->errstr, undef, 'errstr is not set' );

# stop neither in name nor in results should return everything
my @results = $s->results;

is( @results, 16197, 'All departures parsed and returned' );

# results are sorted by time
my $prev = $results[0];
my $ok   = 1;
for my $i ( 1 .. $#results ) {
	my $cur = $results[$i];
	if ( $prev->datetime->epoch > $cur->datetime->epoch ) {
		$ok = 0;
		last;
	}
}
ok( $ok, 'Results are ordered by departure' );

# hide_past => 1 should return nothing

my $s2 = Travel::Status::DE::URA->new(
	ura_base    => 'file:t/in',
	ura_version => 1,
	hide_past   => 1
);
is_deeply( [ $s->results( hide_past => 1 ) ],
	[], 'hide_past => 1 returns nothing' );
is_deeply( [ $s2->results ], [], 'hide_past => 1 returns nothing ' );

# exact matching: bushof should match nothing

@results = $s->results(
	stop => 'bushof',
);
is( @results, 0, '"bushof" matches nothing' );

@results = $s->results(
	stop => 'aachen bushof',
);
is( @results, 0, 'matching is case-sensitive' );

# exact matching: Aachen Bushof should work
@results = $s->results(
	stop => 'Aachen Bushof',
);

is( @results, 375, '"Aachen Bushof" matches 375 stops' );
is( ( first { $_->stop ne 'Aachen Bushof' } @results ),
	undef, '"Aachen Bushof" only matches "Aachen Bushof"' );

# exact matching: also works in constructor
$s = Travel::Status::DE::URA->new(
	ura_base    => 'file:t/in',
	ura_version => 1,
	datetime    => DateTime->new(
		year      => 2013,
		month     => 12,
		day       => 23,
		hour      => 12,
		minute    => 42,
		time_zone => 'Europe/Berlin'
	),
	hide_past => 0,
	stop      => 'Aachen Bushof',
);
@results = $s->results(
	stop => 'Aachen Bushof',
);
is( @results, 375, '"Aachen Bushof" matches 375 stops in constructor' );
is( ( first { $_->stop ne 'Aachen Bushof' } @results ),
	undef, '"Aachen Bushof" only matches "Aachen Bushof" in constructor' );
