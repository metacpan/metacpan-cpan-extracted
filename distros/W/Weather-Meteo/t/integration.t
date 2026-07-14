#!/usr/bin/env perl

# integration.t -- end-to-end black-box tests for Weather::Meteo
#
# Covers full workflows across new(), ua(), and weather() together.
# External HTTP is replaced by a controlled TestUA class whose get()
# returns realistic JSON; Test::Mockingbird::spy records every call
# so we can assert what was actually requested from the network.
# CHI, JSON::MaybeXS, URI and Time::HiRes run without mocking.

use strict;
use warnings;

use CHI;
use HTTP::Response;
use Readonly;
use Test::Most;
use Test::Mockingbird;
use Test::Returns;

use lib 'lib';
use Weather::Meteo;

# ===========================================================================
# TestUA -- a real LWP::UserAgent subclass that intercepts HTTP instead of
# hitting the network.  Spy on TestUA::get to observe every URL requested.
# ===========================================================================
{
	package TestUA;
	use parent 'LWP::UserAgent';

	# Store the JSON payload to serve; can be overridden per-instance
	our $PAYLOAD = '{}';

	# Fake HTTP GET: return PAYLOAD as a 200 OK response
	sub get {
		my ($self, $url) = @_;
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($TestUA::PAYLOAD);
		return $r;
	}
}

# ===========================================================================
# Constants and config
# ===========================================================================

# Fixed geographic coordinates used throughout
Readonly my $LAT      => '51.34';
Readonly my $LON      => '1.42';
Readonly my $DATE     => '2022-12-25';
Readonly my $DATE2    => '2023-06-15';
Readonly my $PRE_1940 => '1939-01-01';

# Documented API defaults
Readonly my $DEFAULT_HOST  => 'archive-api.open-meteo.com';
Readonly my $HOURLY_FIELDS => 'temperature_2m,rain,snowfall,weathercode';
Readonly my $WIND_UNIT     => 'mph';
Readonly my $PRECIP_UNIT   => 'inch';

# Number of entries the API returns per day (documented: one per hour)
Readonly my $HOURS_PER_DAY => 24;

# A realistic full API response with 24 hourly entries and one daily entry
my %config = (
	# 24-slot hourly + 1-slot daily response matching the live API structure
	full_json => do {
		my @t2m  = (5.1,4.9,4.7,4.5,4.3,4.2,4.1,4.0,4.5,5.0,5.8,6.3,6.7,6.5,6.2,5.8,5.4,5.0,4.8,4.6,4.4,4.2,4.0,3.9);
		my @rain = (0) x 24;
		my @snow = (0) x 24;
		my @wc   = (1,1,1,1,2,2,2,3,3,2,1,1,2,2,3,3,2,2,1,1,1,2,2,1);
		my @hrs  = map { sprintf('"2022-12-25T%02d:00"', $_) } 0..23;
		'{"latitude":51.34,"longitude":1.42,'
		. '"hourly":{"time":[' . join(',', @hrs) . '],'
		. '"temperature_2m":[' . join(',', @t2m)  . '],'
		. '"rain":['           . join(',', @rain) . '],'
		. '"snowfall":['       . join(',', @snow) . '],'
		. '"weathercode":['    . join(',', @wc)   . ']},'
		. '"daily":{"time":["2022-12-25"],'
		. '"weathercode":[3],"temperature_2m_max":[6.7],"temperature_2m_min":[3.9],'
		. '"rain_sum":[0.0],"snowfall_sum":[0.0],"precipitation_hours":[0.0],'
		. '"windspeed_10m_max":[12.5],"windgusts_10m_max":[25.3],'
		. '"sunrise":["2022-12-25T08:09"],"sunset":["2022-12-25T15:57"]}}';
	},

	# Alternative response for a second date
	alt_json => '{"hourly":{"temperature_2m":[20,21,22,23,24,25,26,27,28,27,26,25,24,23,22,21,20,19,18,17,16,15,14,13],'
	         . '"rain":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],'
	         . '"snowfall":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],'
	         . '"weathercode":[2,2,1,1,1,1,1,1,1,1,2,2,3,3,2,1,1,1,1,1,2,2,1,1]},'
	         . '"daily":{"time":["2023-06-15"],"temperature_2m_max":[28.0],"temperature_2m_min":[13.0],'
	         . '"weathercode":[3],"rain_sum":[0.0],"snowfall_sum":[0.0],"precipitation_hours":[0.0],'
	         . '"windspeed_10m_max":[10.2],"windgusts_10m_max":[18.5],'
	         . '"sunrise":["2023-06-15T04:43"],"sunset":["2023-06-15T21:22"]}}',

	# Forecast response: hourly + daily with sunrise/sunset
	forecast_json => '{"hourly":{"temperature_2m":[15,16,17],"rain":[0,0,0],'
	              . '"snowfall":[0,0,0],"weathercode":[2,2,2]},'
	              . '"daily":{"time":["2026-07-14"],'
	              . '"sunrise":["2026-07-14T04:52"],"sunset":["2026-07-14T21:18"],'
	              . '"weathercode":[2],"temperature_2m_max":[22.5],"temperature_2m_min":[14.2],'
	              . '"rain_sum":[0.0],"snowfall_sum":[0.0],"precipitation_hours":[0.0],'
	              . '"windspeed_10m_max":[15.3],"windgusts_10m_max":[28.7]}}',

	# Minimal daily-only response for sunrise_sunset()
	sunrise_json  => '{"daily":{"time":["2022-12-25"],'
	              . '"sunrise":["2022-12-25T08:09"],"sunset":["2022-12-25T15:57"]}}',

	# Cache key for the primary coordinates and date with default timezone
	cache_key => "weather:${LAT}:${LON}:${DATE}:Europe/London",
);

# ---------------------------------------------------------------------------
# _fresh_cache -- isolated CHI memory cache; prevents cross-subtest leakage
# ---------------------------------------------------------------------------
sub _fresh_cache {
	return CHI->new(driver => 'Memory', global => 0, expires_in => '1 hour');
}

# ---------------------------------------------------------------------------
# _ua -- fresh TestUA serving the given JSON payload
# ---------------------------------------------------------------------------
sub _ua {
	my ($json) = @_;
	$json //= $config{full_json};
	local $TestUA::PAYLOAD = $json;
	my $ua = TestUA->new();
	# Bake the payload into the instance so it survives the local
	my $baked = $json;
	mock 'TestUA::get' => sub {
		my ($self, $url) = @_;
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($baked);
		return $r;
	};
	return $ua;
}

# ===========================================================================
# 1. Module loads and core construction
# ===========================================================================

# Purpose: verify the module loads cleanly and the constructor works.
subtest 'module loads and new_ok works' => sub {
	use_ok('Weather::Meteo');

	# new_ok verifies isa as well as construction
	my $meteo = new_ok('Weather::Meteo');
	isa_ok($meteo, 'Weather::Meteo', 'new() returns a Weather::Meteo');

	# The public interface must be present
	ok($meteo->can('weather'),        'weather() method present');
	ok($meteo->can('forecast'),       'forecast() method present');
	ok($meteo->can('sunrise_sunset'), 'sunrise_sunset() method present');
	ok($meteo->can('ua'),             'ua() method present');

	diag('module load ok') if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 2. Full end-to-end workflow: new() -> weather() -> structured response
# ===========================================================================

# Purpose: end-to-end smoke test -- the full documented workflow produces
# a hashref whose keys match the documented API response structure.
subtest 'full workflow: new() -> weather() returns correct structure' => sub {
	my $ua    = _ua($config{full_json});
	my $meteo = Weather::Meteo->new(ua => $ua, cache => _fresh_cache());

	# Canonical call form -- hashref with lat, lon, date
	my $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	ok(defined($result), 'weather() returns a defined value');
	returns_ok($result, { type => 'hashref' }, 'return is a hashref');

	# Both hourly and daily sections must be present
	ok(exists($result->{'hourly'}), 'hourly key present');
	ok(exists($result->{'daily'}),  'daily key present');

	restore_all();
	diag('full workflow ok') if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 3. Hourly data has exactly 24 entries per documented API contract
# ===========================================================================

# Purpose: the module's CLAUDE.md states hourly arrays always have 24 entries;
# verify this holds for the temperature, rain, snowfall, and weathercode fields.
subtest 'hourly arrays contain exactly 24 entries' => sub {
	my $ua    = _ua($config{full_json});
	my $meteo = Weather::Meteo->new(ua => $ua, cache => _fresh_cache());
	my $data  = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	# Each hourly sub-key must have exactly HOURS_PER_DAY elements
	for my $field (qw(temperature_2m rain snowfall weathercode)) {
		my $count = scalar(@{ $data->{'hourly'}->{$field} });
		cmp_ok($count, '==', $HOURS_PER_DAY, "hourly $field has $HOURS_PER_DAY entries");
	}

	restore_all();
	diag("hourly entry count=$HOURS_PER_DAY") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 4. URL parameters: spy verifies correct arguments sent to the network
# ===========================================================================

# Purpose: use a spy on TestUA::get to assert every required query parameter
# is present and correctly valued in the URL dispatched to the API.
subtest 'weather() builds URL with all required query parameters' => sub {
	my $ua    = TestUA->new();
	my $spy   = spy 'TestUA::get';

	# Restore previous mock so spy wraps the real TestUA::get
	local $TestUA::PAYLOAD = $config{full_json};

	my $meteo = Weather::Meteo->new(ua => $ua, cache => _fresh_cache());
	$meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	my @calls = $spy->();
	cmp_ok(scalar(@calls), '==', 1, 'exactly one UA call for fresh request');

	# The URL is the third element of the first call record [method, self, url]
	my $url = $calls[0][2];
	diag("url=$url") if $ENV{TEST_VERBOSE};

	# Verify all documented fixed parameters are present
	like($url, qr/latitude=\Q$LAT\E/,        'URL contains latitude');
	like($url, qr/longitude=\Q$LON\E/,       'URL contains longitude');
	like($url, qr/start_date=\Q$DATE\E/,     'URL contains start_date');
	like($url, qr/end_date=\Q$DATE\E/,       'URL contains end_date');
	like($url, qr/windspeed_unit=$WIND_UNIT/, 'URL uses mph wind units');
	like($url, qr/precipitation_unit=$PRECIP_UNIT/, 'URL uses inch precip units');
	like($url, qr/hourly=/,                  'URL requests hourly data');
	like($url, qr/daily=/,                   'URL requests daily data');
	like($url, qr/sunrise/,                  'URL requests sunrise in daily data');
	like($url, qr/sunset/,                   'URL requests sunset in daily data');
	like($url, qr/\Q$DEFAULT_HOST\E/,        'URL targets default host');

	restore_all();
};

# ===========================================================================
# 5. Custom host flows through to request URL (spy confirms)
# ===========================================================================

# Purpose: new(host => ...) must replace the default host in the request URL.
subtest 'custom host propagates to the request URL' => sub {
	my $custom_host = 'myapi.example.com';
	my $ua          = TestUA->new();
	my $spy         = spy 'TestUA::get';
	local $TestUA::PAYLOAD = $config{full_json};

	my $meteo = Weather::Meteo->new(
		ua    => $ua,
		host  => $custom_host,
		cache => _fresh_cache(),
	);
	$meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	my @calls = $spy->();
	my $url = $calls[0][2];

	like($url,   qr/\Q$custom_host\E/, 'custom host appears in URL');
	unlike($url, qr/\Q$DEFAULT_HOST\E/, 'default host absent when overridden');

	restore_all();
	diag("url=$url") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 6. Concurrent instances -- independent caches never share results
# ===========================================================================

# Purpose: two instances constructed simultaneously with separate caches must
# each make their own network call; no cross-contamination of state.
subtest 'two concurrent instances with separate caches are independent' => sub {
	my $ua_a = TestUA->new();
	my $ua_b = TestUA->new();
	local $TestUA::PAYLOAD = $config{full_json};

	my $spy_a = spy 'TestUA::get';

	# Instance A has its own cache; instance B has a different one
	my $meteo_a = Weather::Meteo->new(ua => $ua_a, cache => _fresh_cache());
	my $meteo_b = Weather::Meteo->new(ua => $ua_b, cache => _fresh_cache());

	$meteo_a->weather({ latitude => $LAT, longitude => $LON, date => $DATE });
	$meteo_b->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	# Both instances must have made a network call (no shared cache)
	my @calls = $spy_a->();
	cmp_ok(scalar(@calls), '==', 2, 'two UA calls: one per instance');

	restore_all();
	diag('concurrent independent instances ok') if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 7. Concurrent instances -- shared cache: second instance gets cache hit
# ===========================================================================

# Purpose: two instances sharing the same CHI cache object should cooperate:
# the first call populates the cache; the second call must skip the network.
subtest 'two concurrent instances sharing a cache cooperate' => sub {
	my $shared_cache = _fresh_cache();
	my $ua           = TestUA->new();
	local $TestUA::PAYLOAD = $config{full_json};

	my $spy = spy 'TestUA::get';

	# Both instances point at the same cache object
	my $meteo_a = Weather::Meteo->new(ua => $ua, cache => $shared_cache);
	my $meteo_b = Weather::Meteo->new(ua => $ua, cache => $shared_cache);

	# A populates the cache; B should read from it
	$meteo_a->weather({ latitude => $LAT, longitude => $LON, date => $DATE });
	$meteo_b->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	my @calls = $spy->();
	cmp_ok(scalar(@calls), '==', 1, 'UA called once: B used cache populated by A');

	restore_all();
	diag('shared cache cooperation ok') if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 8. Three concurrent instances: A+B share cache, C is independent
# ===========================================================================

# Purpose: verify that cache sharing is strictly opt-in via the cache argument.
# A and B share a cache object; C has its own.  After A calls weather(), B
# gets a cache hit but C still makes a network call.
subtest 'three instances: A+B shared cache, C independent' => sub {
	my $shared = _fresh_cache();
	my $ua     = TestUA->new();
	local $TestUA::PAYLOAD = $config{full_json};

	my $spy = spy 'TestUA::get';

	my $a = Weather::Meteo->new(ua => $ua, cache => $shared);
	my $b = Weather::Meteo->new(ua => $ua, cache => $shared);
	my $c = Weather::Meteo->new(ua => $ua, cache => _fresh_cache());

	# A primes the shared cache
	$a->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	# B should hit shared cache (no UA call); C must call UA
	$b->weather({ latitude => $LAT, longitude => $LON, date => $DATE });
	$c->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	my @calls = $spy->();
	cmp_ok(scalar(@calls), '==', 2, 'exactly 2 UA calls: A and C (B hit cache)');

	restore_all();
	diag('three-instance cache isolation ok') if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 9. Stateful cache: same instance, repeated call, single network hit
# ===========================================================================

# Purpose: within a single instance the cache must de-duplicate identical
# requests so the underlying HTTP layer is invoked only once.
subtest 'same instance: repeated identical call hits cache on second try' => sub {
	my $ua    = TestUA->new();
	local $TestUA::PAYLOAD = $config{full_json};

	my $spy   = spy 'TestUA::get';
	my $meteo = Weather::Meteo->new(ua => $ua, cache => _fresh_cache());

	# Two identical calls -- only the first should hit the network
	my $r1 = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });
	my $r2 = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	my @calls = $spy->();
	cmp_ok(scalar(@calls), '==', 1, 'UA called once for two identical requests');
	is_deeply($r2, $r1, 'second result equals first (served from cache)');

	restore_all();
	diag('stateful cache ok') if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 10. Different dates produce independent cache entries
# ===========================================================================

# Purpose: two requests for the same coordinates but different dates must each
# result in a separate network call (they have different cache keys).
subtest 'different dates produce independent network calls' => sub {
	my $ua = TestUA->new();
	local $TestUA::PAYLOAD = $config{full_json};

	my $spy   = spy 'TestUA::get';
	my $meteo = Weather::Meteo->new(ua => $ua, cache => _fresh_cache());

	$meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE  });
	$meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE2 });

	my @calls = $spy->();
	cmp_ok(scalar(@calls), '==', 2, 'two UA calls for two different dates');

	# Each URL must contain the corresponding date
	like($calls[0][2], qr/start_date=$DATE/,  'first call URL has DATE');
	like($calls[1][2], qr/start_date=$DATE2/, 'second call URL has DATE2');

	restore_all();
	diag('date-separated cache ok') if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 11. Rate limiting: Time::HiRes::sleep is called on rapid second request
# ===========================================================================

# Purpose: when min_interval > 0, a second request made before the interval
# expires must call Time::HiRes::sleep.  We spy on sleep (real sleep runs)
# using a tiny 0.01 s interval so the test suite is not noticeably slowed.
subtest 'rate limiting: Time::HiRes::sleep called between rapid requests' => sub {
	my $ua = TestUA->new();
	local $TestUA::PAYLOAD = $config{full_json};

	# Suppress the inevitable "Prototype mismatch" warnings that Perl emits
	# when Test::Mockingbird installs and later restores its wrapper over the
	# prototyped XSUB Time::HiRes::sleep.  The spy itself works correctly.
	local $SIG{__WARN__} = sub {
		warn @_ unless $_[0] =~ /Prototype mismatch.*Time::HiRes::sleep/;
	};

	# Spy on sleep -- the real sleep runs (0.01 s max); we just observe calls
	my $sleep_spy = spy 'Time::HiRes::sleep';

	my $meteo = Weather::Meteo->new(
		ua           => $ua,
		cache        => _fresh_cache(),
		min_interval => 0.01,	# 10 ms -- tiny but enough to trigger
	);

	# First request: last_request starts at 0, elapsed >> 0.01 -- no sleep
	$meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	# Second request: elapsed ~ 0, which is < 0.01 -- sleep must be called
	$meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE2 });

	my @sleeps = $sleep_spy->();
	cmp_ok(scalar(@sleeps), '>=', 1, 'Time::HiRes::sleep called at least once');
	cmp_ok($sleeps[0][1], '>', 0, 'sleep duration is positive');

	restore_all();
	diag("sleep calls=" . scalar(@sleeps)) if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 12. No sleep when min_interval is zero (the documented default)
# ===========================================================================

# Purpose: the documented default min_interval of 0 must never cause a sleep.
subtest 'no sleep when min_interval=0 (default)' => sub {
	my $ua = TestUA->new();
	local $TestUA::PAYLOAD = $config{full_json};

	local $SIG{__WARN__} = sub {
		warn @_ unless $_[0] =~ /Prototype mismatch.*Time::HiRes::sleep/;
	};

	my $sleep_spy = spy 'Time::HiRes::sleep';

	my $meteo = Weather::Meteo->new(ua => $ua, cache => _fresh_cache());

	# Make two calls; with min_interval=0 no sleep should ever occur
	$meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE  });
	$meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE2 });

	my @sleeps = $sleep_spy->();
	cmp_ok(scalar(@sleeps), '==', 0, 'no sleep with min_interval=0');

	restore_all();
	diag('no-sleep ok') if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 13. UA replacement mid-session via ua() setter
# ===========================================================================

# Purpose: calling ua($new_ua) between weather() calls must switch the HTTP
# backend so the new UA is used for subsequent requests.
subtest 'replacing UA mid-session affects subsequent requests' => sub {
	# Two separate TestUA subclasses so spies are independent
	{ package TestUA_A;
	  use parent 'LWP::UserAgent';
	  sub get { my ($s,$u)=@_; my $r=HTTP::Response->new(200,'OK'); $r->content($config{full_json}); $r } }

	{ package TestUA_B;
	  use parent 'LWP::UserAgent';
	  sub get { my ($s,$u)=@_; my $r=HTTP::Response->new(200,'OK'); $r->content($config{alt_json});  $r } }

	my $ua_a  = TestUA_A->new();
	my $ua_b  = TestUA_B->new();
	my $spy_a = spy 'TestUA_A::get';
	my $spy_b = spy 'TestUA_B::get';

	my $meteo = Weather::Meteo->new(ua => $ua_a, cache => _fresh_cache());

	# First call uses UA A
	$meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	# Swap UA mid-session
	$meteo->ua($ua_b);

	# Second call (different date) must use UA B
	$meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE2 });

	my @a_calls = $spy_a->();
	my @b_calls = $spy_b->();

	cmp_ok(scalar(@a_calls), '==', 1, 'UA A was called for the first request');
	cmp_ok(scalar(@b_calls), '==', 1, 'UA B was called after the swap');

	restore_all();
	diag('mid-session UA swap ok') if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 14. Location object integration: latitude/longitude methods are called
# ===========================================================================

# Purpose: when weather() receives a Geo::Location::Point-like object it must
# call latitude() and longitude() on that object and pass the returned values
# to the API.  Spy confirms the methods are invoked; URL confirms the values.
subtest 'location object: latitude/longitude methods called and values in URL' => sub {
	{ package FakeLoc;
	  sub new  { bless {}, shift }
	  sub latitude  { $LAT }
	  sub longitude { $LON }
	}

	my $ua  = TestUA->new();
	local $TestUA::PAYLOAD = $config{full_json};

	my $lat_spy = spy 'FakeLoc::latitude';
	my $lon_spy = spy 'FakeLoc::longitude';
	my $ua_spy  = spy 'TestUA::get';

	my $loc   = FakeLoc->new();
	my $meteo = Weather::Meteo->new(ua => $ua, cache => _fresh_cache());

	# Positional (location, date) form
	$meteo->weather($loc, $DATE);

	# latitude() and longitude() must each have been called
	my @lat_calls = $lat_spy->();
	my @lon_calls = $lon_spy->();
	cmp_ok(scalar(@lat_calls), '>=', 1, 'latitude() was called on location object');
	cmp_ok(scalar(@lon_calls), '>=', 1, 'longitude() was called on location object');

	# The URL must contain the values those methods returned
	my @ua_calls = $ua_spy->();
	like($ua_calls[0][2], qr/latitude=\Q$LAT\E/,  'lat value in URL');
	like($ua_calls[0][2], qr/longitude=\Q$LON\E/, 'lon value in URL');

	restore_all();
	diag('location object integration ok') if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 15. DateTime-like object: strftime('%F') called; result flows into URL
# ===========================================================================

# Purpose: when the date argument is a blessed object that responds to
# strftime, weather() must call strftime('%F') on it and use the returned
# string as the date in the request URL.  Spy confirms the call signature.
subtest 'date object: strftime called with %F and result appears in URL' => sub {
	{ package FakeDT;
	  sub new       { bless {}, shift }
	  sub strftime  { $DATE }	# always returns our fixed date string
	}

	my $ua = TestUA->new();
	local $TestUA::PAYLOAD = $config{full_json};

	my $dt_spy = spy 'FakeDT::strftime';
	my $ua_spy = spy 'TestUA::get';

	my $dt    = FakeDT->new();
	my $meteo = Weather::Meteo->new(ua => $ua, cache => _fresh_cache());

	$meteo->weather({ latitude => $LAT, longitude => $LON, date => $dt });

	# strftime must have been called exactly once
	my @dt_calls = $dt_spy->();
	cmp_ok(scalar(@dt_calls), '==', 1, 'strftime called once on date object');

	# The format argument must be '%F' (ISO 8601 full date)
	is($dt_calls[0][2], '%F', 'strftime called with format "%F"');

	# The URL must contain the date string that strftime returned
	my @ua_calls = $ua_spy->();
	like($ua_calls[0][2], qr/start_date=\Q$DATE\E/, 'strftime result in URL');

	restore_all();
	diag('date object integration ok') if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 16. Pre-1940 date: no network call is made
# ===========================================================================

# Purpose: a date before 1940 must return undef without touching the network.
# Spy on TestUA::get to verify zero UA calls are made.
subtest 'pre-1940 date: network is not contacted' => sub {
	my $ua  = TestUA->new();
	my $spy = spy 'TestUA::get';

	my $meteo  = Weather::Meteo->new(ua => $ua, cache => _fresh_cache());
	my $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $PRE_1940 });

	ok(!defined($result), 'pre-1940 returns undef');

	my @calls = $spy->();
	cmp_ok(scalar(@calls), '==', 0, 'no network call for pre-1940 date');

	restore_all();
	diag('pre-1940 no-network ok') if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 17. Error recovery: HTTP error followed by successful request
# ===========================================================================

# Purpose: after an HTTP 500 response (which carps and returns undef), a
# subsequent call to a different date must still succeed and return data.
subtest 'error recovery: success follows an HTTP error' => sub {
	my $call_count = 0;

	{ package RecoveryUA;
	  use parent 'LWP::UserAgent';
	  our $N = 0;
	  sub get {
		  my ($self, $url) = @_;
		  $RecoveryUA::N++;
		  if ($RecoveryUA::N == 1) {
			  return HTTP::Response->new(500, 'Server Error');
		  }
		  my $r = HTTP::Response->new(200, 'OK');
		  $r->content($config{full_json});
		  return $r;
	  }
	}
	$RecoveryUA::N = 0;

	my $ua   = RecoveryUA->new();
	my $spy  = spy 'RecoveryUA::get';
	my $cache = _fresh_cache();

	my $meteo  = Weather::Meteo->new(ua => $ua, cache => $cache);
	my $warned = 0;
	local $SIG{__WARN__} = sub { $warned++ };

	# First call fails with HTTP 500
	my $bad = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });
	ok(!defined($bad), 'first call (500) returns undef');
	ok($warned,         'HTTP error emitted a carp warning');

	# Second call (different date) must succeed
	my $good = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE2 });
	ok(defined($good),            'second call succeeds after prior HTTP error');
	ok(exists($good->{'hourly'}), 'recovered result has hourly key');

	my @calls = $spy->();
	cmp_ok(scalar(@calls), '==', 2, 'UA called twice: once for error, once for recovery');

	restore_all();
	diag('error recovery ok') if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 18. Custom CHI cache integration: round-trip store and retrieve
# ===========================================================================

# Purpose: verify that weather() correctly writes to and reads from an
# externally supplied CHI object, and that the stored value is a hashref
# containing an hourly key.
subtest 'custom CHI cache: data stored and retrieved correctly' => sub {
	my $cache = _fresh_cache();
	my $ua    = TestUA->new();
	local $TestUA::PAYLOAD = $config{full_json};

	my $spy   = spy 'TestUA::get';
	my $meteo = Weather::Meteo->new(ua => $ua, cache => $cache);

	# Make the first (live) call; this should populate the cache
	my $result1 = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	# Verify the data landed in the cache under the expected key
	my $cached = $cache->get($config{cache_key});
	ok(defined($cached),            'data was written to the CHI cache');
	ok(exists($cached->{'hourly'}), 'cached entry has hourly key');

	# A second call must return the cached value, not hit the network
	my $result2 = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });
	is_deeply($result2, $result1, 'second call returns cached data');

	my @calls = $spy->();
	cmp_ok(scalar(@calls), '==', 1, 'UA called only once (second call used cache)');

	restore_all();
	diag('CHI cache round-trip ok') if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 19. forecast() end-to-end workflow
# ===========================================================================

# Purpose: forecast() returns a correct structure and targets the forecast host.
subtest 'forecast() end-to-end: returns hourly + daily with sunrise/sunset' => sub {
	my $ua  = TestUA->new();
	my $spy = spy 'TestUA::get';
	local $TestUA::PAYLOAD = $config{forecast_json};

	my $meteo  = Weather::Meteo->new(ua => $ua, cache => _fresh_cache());
	my $result = $meteo->forecast({ latitude => $LAT, longitude => $LON, days => 3 });

	ok(defined($result),            'forecast() returns a defined value');
	ok(exists($result->{'hourly'}), 'result has hourly key');
	ok(exists($result->{'daily'}),  'result has daily key');

	# Verify sunrise and sunset are present in the daily section
	my $daily = $result->{'daily'};
	ok(exists($daily->{'sunrise'}), 'daily contains sunrise');
	ok(exists($daily->{'sunset'}),  'daily contains sunset');

	# Confirm the request went to the forecast host
	my @calls = $spy->();
	cmp_ok(scalar(@calls), '==', 1, 'exactly one UA call made');
	my $url = $calls[0][2];
	like($url, qr/api\.open-meteo\.com/,  'URL targets forecast host');
	like($url, qr|/v1/forecast|,          'URL uses /v1/forecast path');
	like($url, qr/forecast_days=3/,       'URL contains requested days count');

	restore_all();
	diag('forecast workflow ok') if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 20. sunrise_sunset() end-to-end workflow
# ===========================================================================

# Purpose: sunrise_sunset() returns exactly { sunrise, sunset } and uses the
# archive endpoint for a historical date.
subtest 'sunrise_sunset() end-to-end: historical date returns { sunrise, sunset }' => sub {
	my $ua  = TestUA->new();
	my $spy = spy 'TestUA::get';
	local $TestUA::PAYLOAD = $config{sunrise_json};

	my $meteo  = Weather::Meteo->new(ua => $ua, cache => _fresh_cache());
	my $result = $meteo->sunrise_sunset({ latitude => $LAT, longitude => $LON, date => $DATE });

	ok(defined($result),             'sunrise_sunset() returns a defined value');
	ok(ref($result) eq 'HASH',       'result is a hashref');
	ok(exists($result->{'sunrise'}), 'result has sunrise key');
	ok(exists($result->{'sunset'}),  'result has sunset key');

	# Only sunrise and sunset -- no hourly or other daily fields
	ok(!exists($result->{'hourly'}), 'result does not include hourly');
	ok(!exists($result->{'daily'}),  'result does not expose raw daily');

	# Confirm the archive endpoint was called
	my @calls = $spy->();
	cmp_ok(scalar(@calls), '==', 1, 'exactly one UA call made');
	my $url = $calls[0][2];
	like($url, qr/archive-api\.open-meteo\.com/, 'historical date uses archive host');
	like($url, qr/start_date=\Q$DATE\E/,         'URL contains correct date');

	restore_all();
	diag('sunrise_sunset workflow ok') if $ENV{TEST_VERBOSE};
};

# Purpose: a second sunrise_sunset() call for the same args must use the cache.
subtest 'sunrise_sunset() caches result and skips UA on repeat call' => sub {
	my $ua  = TestUA->new();
	my $spy = spy 'TestUA::get';
	local $TestUA::PAYLOAD = $config{sunrise_json};

	my $meteo = Weather::Meteo->new(ua => $ua, cache => _fresh_cache());
	my $r1    = $meteo->sunrise_sunset({ latitude => $LAT, longitude => $LON, date => $DATE });
	my $r2    = $meteo->sunrise_sunset({ latitude => $LAT, longitude => $LON, date => $DATE });

	is_deeply($r2, $r1, 'cached result equals first result');
	cmp_ok(scalar($spy->()), '==', 1, 'UA called only once');

	restore_all();
	diag('sunrise_sunset cache ok') if $ENV{TEST_VERBOSE};
};

done_testing();
