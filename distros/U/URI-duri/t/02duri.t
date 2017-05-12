use lib '../lib';
use Data::Dumper;
use Test::More tests => 115;
use URI;
use URI::duri;

my @uris = (
	URI->new('duri:2000:http://example.com/'), ####################### 0
	URI->new('duri:2000-01:http://example.com/'),                    # 1
	URI->new('duri:2000-01-01:http://example.com/'), ################# 2
	URI->new('duri:2000-01-01T12:34:http://example.com/'),           # 3
	URI->new('duri:2000-01-01T12:34:56:http://example.com/'), ######## 4
	URI->new('duri:2000-01-01T12:34:56.789:http://example.com/'),    # 5
	URI->new('duri:2000-01-01Z:http://example.com/'), ################ 6
	URI->new('duri:2000-01-01T12:34Z:http://example.com/'),          # 7
	URI->new('duri:2000-01-01T12:34:56Z:http://example.com/'), ####### 8
	URI->new('duri:2000-01-01T12:34:56.789Z:http://example.com/'),   # 9
);

foreach (0 .. 9)
{	
	ok(
		$uris[$_]->datetime->has_year,
		"$uris[$_] has year",
	);
	is(
		$uris[$_]->datetime->year,
		'2000',
		"$uris[$_] has correct year",
	);
}

foreach (1 .. 9)
{	
	ok(
		$uris[$_]->datetime->has_month,
		"$uris[$_] has month",
	);
	is(
		$uris[$_]->datetime->month,
		'01',
		"$uris[$_] has correct month",
	);
}

foreach (2 .. 9)
{	
	ok(
		$uris[$_]->datetime->has_day,
		"$uris[$_] has day",
	);
	is(
		$uris[$_]->datetime->day,
		'01',
		"$uris[$_] has correct day",
	);
}


foreach (3, 4, 5, 7, 8, 9)
{	
	ok(
		$uris[$_]->datetime->has_hour &&
		$uris[$_]->datetime->has_minute,
		"$uris[$_] has hour and minute",
	);
	is(
		$uris[$_]->datetime->hour,
		'12',
		"$uris[$_] has correct hour",
	);
	is(
		$uris[$_]->datetime->minute,
		'34',
		"$uris[$_] has correct minute",
	);
}

foreach (4, 5, 8, 9)
{	
	ok(
		$uris[$_]->datetime->has_second,
		"$uris[$_] has second",
	);
	is(
		$uris[$_]->datetime->second,
		'56',
		"$uris[$_] has correct second",
	);
}

foreach (5, 9)
{	
	ok(
		$uris[$_]->datetime->has_nanosecond,
		"$uris[$_] has nanosecond",
	);
	ok(
		abs($uris[$_]->datetime->nanosecond - 789_000_000) < 5,
		"$uris[$_] has correct second",
	);
}

foreach (6 .. 9)
{	
	ok(
		$uris[$_]->datetime->has_time_zone,
		"$uris[$_] has time zone",
	);
	ok(
		$uris[$_]->datetime->time_zone->is_utc,
		"$uris[$_] has correct time zone",
	);
}

foreach (0 .. 9)
{
	my $emb = $uris[$_]->embedded_uri;
	isa_ok $emb => 'URI';
	is("$emb", "http://example.com/");
}

my $complex = URI->new('duri:2000-01-01T12:34:56.789+00:00:urn:example:foo');

is(
	$complex->datetime->year,
	'2000',
);
is(
	$complex->datetime->second,
	'56',
);
is(
	$complex->embedded_uri,
	'urn:example:foo',
);

done_testing();