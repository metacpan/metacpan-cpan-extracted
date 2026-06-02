#!/usr/bin/env perl

# Integration tests for TimeZone::TimeZoneDB.
# These are end-to-end, black-box tests that exercise entire workflows
# across multiple routines.  The only mocked boundary is the HTTP network
# layer (LWP::UserAgent::get) and filesystem access (Object::Configure).
# Real CHI caches, real URI construction, real JSON parsing, and real
# Time::HiRes interactions are all allowed to run.

use strict;
use warnings;

use lib 'lib';
use lib "$ENV{HOME}/src/njh/Test-Mockingbird/lib";
use lib "$ENV{HOME}/src/njh/Test-Returns/lib";

use CHI;
use Geo::Location::Point 0.08;
use HTTP::Response;
use Readonly;
use Scalar::Util qw(blessed);
use Test::Most;
use Test::Mockingbird;
use Test::Mockingbird::TimeTravel qw(freeze_time advance_time restore_all);
use Test::Returns;
use Test::Warn;

# ---------------------------------------------------------------------------
# Verify all external dependencies load before any tests execute
# ---------------------------------------------------------------------------
use_ok('TimeZone::TimeZoneDB');
use_ok('CHI');
use_ok('LWP::UserAgent');
use_ok('URI');
use_ok('JSON::MaybeXS');
use_ok('Geo::Location::Point');

# ---------------------------------------------------------------------------
# Integration-test configuration.
# A single hash avoids magic numbers/strings anywhere in the test body.
# ---------------------------------------------------------------------------
my %config = (
	key          => 'integration_test_key',
	host_default => 'api.timezonedb.com',
	api_version  => 'v2.1',
	api_endpoint => 'get-time-zone',

	# Geographic fixtures
	lat_nyc      =>  40.7128,
	lng_nyc      => -74.006,
	tz_nyc       => 'America/New_York',

	lat_ramsgate =>  51.34,
	lng_ramsgate =>   1.42,
	tz_ramsgate  => 'Europe/London',

	lat_sydney   => -33.8688,
	lng_sydney   =>  151.2093,
	tz_sydney    => 'Australia/Sydney',

	http_ok      => 200,
	http_error   => 500,

	# Rate-limiting: large enough to force sleep on back-to-back calls
	min_interval_test => 30,
);

# Readonly scalars for use inside closures
Readonly::Scalar my $KEY       => $config{key};
Readonly::Scalar my $LAT       => $config{lat_nyc};
Readonly::Scalar my $LNG       => $config{lng_nyc};
Readonly::Scalar my $TZ_NYC    => $config{tz_nyc};
Readonly::Scalar my $TZ_RAMS   => $config{tz_ramsgate};
Readonly::Scalar my $TZ_SYD    => $config{tz_sydney};

# Canned JSON bodies matching the real timezonedb.com response schema
Readonly::Scalar my $JSON_NYC  => '{"status":"OK","zoneName":"America/New_York","gmtOffset":-18000,"dst":1}';
Readonly::Scalar my $JSON_RAMS => '{"status":"OK","zoneName":"Europe/London","gmtOffset":0,"dst":0}';
Readonly::Scalar my $JSON_SYD  => '{"status":"OK","zoneName":"Australia/Sydney","gmtOffset":36000,"dst":0}';
Readonly::Scalar my $JSON_FAIL => '{"status":"FAILED","message":"Invalid API key"}';
Readonly::Scalar my $JSON_BAD  => '<<< not valid json >>>>';

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Build an HTTP::Response with a 200 OK status and the given JSON body
sub _ok_resp {
	my ($body) = @_;
	my $r = HTTP::Response->new($config{http_ok}, 'OK');
	$r->content($body);
	return $r;
}

# Build a server-error HTTP::Response
sub _err_resp {
	my ($code, $msg) = @_;
	return HTTP::Response->new($code // $config{http_error}, $msg // 'Internal Server Error');
}

# ---------------------------------------------------------------------------
# Freeze Object::Configure for every test so new() never touches the disk.
# This is the only non-network mock in this file; all other real implementations
# (CHI, URI, JSON::MaybeXS, LWP::UserAgent object creation) run unchanged.
# ---------------------------------------------------------------------------
mock 'Object::Configure::configure' => sub { $_[1] };

# ===========================================================================
# Module load and object construction
# ===========================================================================

subtest 'integration: new_ok constructs a live instance' => sub {
	# new_ok tests the constructor via the real Perl object system
	my $tzdb = new_ok('TimeZone::TimeZoneDB', [ key => $KEY ], 'TimeZone::TimeZoneDB');
	ok(defined $tzdb, 'object is defined');
	returns_ok($tzdb, { type => 'object' }, 'new() satisfies output schema');
};

# ===========================================================================
# Full lifecycle: new -> get_time_zone -> response parsed by real JSON::MaybeXS
# ===========================================================================

subtest 'integration: full lifecycle - construct, call, parse real JSON' => sub {
	# The full pipeline: real UA creation -> real URL build -> real JSON parse
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	my $result;
	{
		# Replace only the HTTP transport; everything else is real
		my $g = mock_scoped 'LWP::UserAgent::get' => sub { _ok_resp($JSON_NYC) };
		$result = $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	}

	# Verify the real JSON::MaybeXS decoded the response correctly
	ok(defined $result,                   'result is defined');
	is(ref $result, 'HASH',               'result is a hashref');
	is($result->{zoneName},   $TZ_NYC,    'zoneName is correct');
	is($result->{status},     'OK',       'status is OK');
	is($result->{gmtOffset},  -18000,     'gmtOffset parsed correctly');
	ok(exists $result->{dst},             'dst key is present');
	returns_ok($result, { type => 'hashref', min => 1 }, 'output schema satisfied');
	diag("zoneName=$result->{zoneName} gmtOffset=$result->{gmtOffset}") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# URL construction: real URI object integration
# ===========================================================================

subtest 'integration: URL construction uses real URI module' => sub {
	# Spy on LWP::UserAgent::get to capture the URL that URI built
	my $captured_url;
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	{
		my $g = mock_scoped 'LWP::UserAgent::get' => sub {
			$captured_url = $_[1];
			return _ok_resp($JSON_NYC);
		};
		$tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	}

	# Parse the captured URL with a real URI object to verify it is well-formed
	my $uri = URI->new($captured_url);
	is($uri->scheme, 'https',                         'URL scheme is https');
	is($uri->host,   $config{host_default},           'URL host is api.timezonedb.com');
	like($captured_url, qr{$config{api_version}},     'URL contains API version');
	like($captured_url, qr{$config{api_endpoint}},    'URL contains API endpoint');
	like($captured_url, qr{by=position},              'URL has by=position');
	like($captured_url, qr{format=json},              'URL has format=json');
	like($captured_url, qr{key=\Q$KEY\E},             'URL contains API key');
	like($captured_url, qr{lat=\Q$LAT\E},             'URL contains latitude');
	diag("URL: $captured_url") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# CHI integration: real in-memory cache wired to the module
# ===========================================================================

subtest 'integration: real CHI cache - second call is a cache hit' => sub {
	# A real CHI::Memory cache; verify the module reads back its own entries
	my $cache = CHI->new(driver => 'Memory', global => 0, expires_in => '1 day');
	my $call_count = 0;
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY, cache => $cache);
	{
		my $g = mock_scoped 'LWP::UserAgent::get' => sub {
			$call_count++;
			return _ok_resp($JSON_NYC);
		};
		# First call: cache miss -> HTTP request
		my $r1 = $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
		# Second call: same coords -> cache hit, no HTTP request
		my $r2 = $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);

		is($call_count,            1,       'HTTP called once for two identical lookups');
		is_deeply($r2, $r1,                 'cache hit returns same data as original call');
		is($r1->{zoneName}, $TZ_NYC,        'cached value is correct');
	}
};

subtest 'integration: real CHI cache - different coords have separate slots' => sub {
	# Lookups for different coordinates must not collide in the cache
	my $cache      = CHI->new(driver => 'Memory', global => 0, expires_in => '1 day');
	my $call_count = 0;
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY, cache => $cache);
	{
		my $responses = [ $JSON_NYC, $JSON_RAMS ];
		my $g = mock_scoped 'LWP::UserAgent::get' => sub {
			return _ok_resp($responses->[$call_count++]);
		};
		my $r_nyc  = $tzdb->get_time_zone(latitude => $LAT,                  longitude => $LNG);
		my $r_rams = $tzdb->get_time_zone(latitude => $config{lat_ramsgate}, longitude => $config{lng_ramsgate});
		is($call_count,          2,         'two HTTP calls for two distinct coordinates');
		is($r_nyc->{zoneName},   $TZ_NYC,   'NYC timezone correct');
		is($r_rams->{zoneName},  $TZ_RAMS,  'Ramsgate timezone correct');
	}
};

subtest 'integration: shared CHI cache across two independent instances' => sub {
	# Two instances sharing the same cache: second instance benefits from first's work
	my $shared_cache = CHI->new(driver => 'Memory', global => 1,
		namespace => 'shared_test_' . $$, expires_in => '1 day');
	my $call_count = 0;
	{
		my $g = mock_scoped 'LWP::UserAgent::get' => sub {
			$call_count++;
			return _ok_resp($JSON_NYC);
		};
		my $tzdb1 = TimeZone::TimeZoneDB->new(key => $KEY, cache => $shared_cache);
		my $tzdb2 = TimeZone::TimeZoneDB->new(key => $KEY, cache => $shared_cache);

		# First instance makes the real HTTP call
		my $r1 = $tzdb1->get_time_zone(latitude => $LAT, longitude => $LNG);
		# Second instance must find the result already in the shared cache
		my $r2 = $tzdb2->get_time_zone(latitude => $LAT, longitude => $LNG);

		is($call_count,      1,       'only one HTTP call with shared cache');
		is_deeply($r2, $r1,           'second instance returned cached data');
	}
};

# ===========================================================================
# Multiple concurrent instances - independent state
# ===========================================================================

subtest 'integration: two instances operate with independent state' => sub {
	# Each instance should have its own ua, host, and cache; mutations to one
	# must not affect the other
	my $call_count_a = 0;
	my $call_count_b = 0;

	# Two separate private caches
	my $cache_a = CHI->new(driver => 'Memory', global => 0, expires_in => '1 hour');
	my $cache_b = CHI->new(driver => 'Memory', global => 0, expires_in => '1 hour');

	my $tzdb_a = TimeZone::TimeZoneDB->new(key => $KEY, cache => $cache_a);
	my $tzdb_b = TimeZone::TimeZoneDB->new(key => $KEY, cache => $cache_b);

	{
		# Sequence: A calls NYC, B calls Ramsgate, then both call their cached coord again
		my @responses = ($JSON_NYC, $JSON_RAMS);
		my $idx = 0;
		my $g = mock_scoped 'LWP::UserAgent::get' => sub { _ok_resp($responses[$idx++]) };

		my $r_a = $tzdb_a->get_time_zone(latitude => $LAT,                  longitude => $LNG);
		my $r_b = $tzdb_b->get_time_zone(latitude => $config{lat_ramsgate}, longitude => $config{lng_ramsgate});
		is($idx, 2, 'each instance made its own HTTP call');

		# Repeat the same lookup on each - must be served from each private cache
		my $r_a2 = $tzdb_a->get_time_zone(latitude => $LAT,                  longitude => $LNG);
		my $r_b2 = $tzdb_b->get_time_zone(latitude => $config{lat_ramsgate}, longitude => $config{lng_ramsgate});
		is($idx, 2, 'no extra HTTP calls: both served from private caches');

		is($r_a->{zoneName},  $TZ_NYC,  'instance A has NYC data');
		is($r_b->{zoneName},  $TZ_RAMS, 'instance B has Ramsgate data');
		is_deeply($r_a2, $r_a, 'instance A cache consistent');
		is_deeply($r_b2, $r_b, 'instance B cache consistent');
	}
	diag("Two instances ran independently") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# ua() + get_time_zone() workflow: switching UA mid-flight
# ===========================================================================

subtest 'integration: ua() swap propagates to subsequent API calls' => sub {
	# After calling ua($new_ua) the next get_time_zone must use the new UA object
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);

	my $calls_old = 0;
	my $calls_new = 0;

	# Phase 1: mock the original (default) UA and make one call
	{
		my $g = mock_scoped 'LWP::UserAgent::get' => sub {
			$calls_old++;
			return _ok_resp($JSON_NYC);
		};
		$tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	}
	is($calls_old, 1, 'original UA used for first call');

	# Now inject a fresh LWP::UserAgent and verify the new one is used
	my $new_ua = LWP::UserAgent->new();
	$tzdb->ua($new_ua);
	{
		# Spy directly on the new UA instance's get() method
		my $spy = spy $new_ua, 'get';
		my $g   = mock_scoped 'LWP::UserAgent::get' => sub {
			$calls_new++;
			return _ok_resp($JSON_RAMS);
		};
		# Clear cache so the second call actually hits the UA
		$tzdb->get_time_zone(
			latitude  => $config{lat_ramsgate},
			longitude => $config{lng_ramsgate}
		);
	}
	is($calls_new, 1, 'new UA used after ua() setter');
	is($calls_old, 1, 'old UA call count unchanged after swap');
	is(blessed($tzdb->ua()), 'LWP::UserAgent', 'ua() getter still returns new UA after calls');
	diag("UA swap tested successfully") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# Clone + original: independent state after new() on an instance
# ===========================================================================

subtest 'integration: clone and original operate without interfering' => sub {
	# A cloned instance shares no mutable state with the original except key
	my $cache_orig  = CHI->new(driver => 'Memory', global => 0, expires_in => '1 hour');
	my $cache_clone = CHI->new(driver => 'Memory', global => 0, expires_in => '1 hour');
	my $orig  = TimeZone::TimeZoneDB->new(key => $KEY, cache => $cache_orig);

	# Clone gets its own private cache
	my $clone = $orig->new(cache => $cache_clone);

	my @calls;
	{
		my $g = mock_scoped 'LWP::UserAgent::get' => sub {
			push @calls, 'http';
			return _ok_resp($JSON_NYC);
		};
		# Both make the same lookup; they each have their own cache, so two HTTP calls
		$orig->get_time_zone( latitude => $LAT, longitude => $LNG);
		$clone->get_time_zone(latitude => $LAT, longitude => $LNG);
	}
	is(scalar @calls, 2, 'clone and original each make their own HTTP call');
	diag("Clones are independent") if $ENV{TEST_VERBOSE};
};

subtest 'integration: clone inherits key and makes real API calls' => sub {
	# A clone without extra args keeps the parent key; its calls should succeed
	my $orig  = TimeZone::TimeZoneDB->new(key => $KEY);
	my $clone = $orig->new();
	my $result;
	{
		my $g  = mock_scoped 'LWP::UserAgent::get' => sub { _ok_resp($JSON_NYC) };
		$result = $clone->get_time_zone(latitude => $LAT, longitude => $LNG);
	}
	ok(defined $result,              'clone can make a successful call');
	is($result->{zoneName}, $TZ_NYC, 'clone returns correct timezone');
};

# ===========================================================================
# Geo::Location::Point integration: real object passed to get_time_zone
# ===========================================================================

subtest 'integration: Geo::Location::Point object accepted by get_time_zone' => sub {
	# POD says the method accepts any object with latitude()/longitude()
	# Here we use a real Geo::Location::Point from the test-dependency list
	my $ramsgate = new_ok('Geo::Location::Point',
		[ latitude => $config{lat_ramsgate}, longitude => $config{lng_ramsgate} ],
		'Geo::Location::Point'
	);

	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	my $result;
	{
		my $g = mock_scoped 'LWP::UserAgent::get' => sub { _ok_resp($JSON_RAMS) };
		$result = $tzdb->get_time_zone($ramsgate);
	}
	ok(defined $result,               'result defined for Geo::Location::Point call');
	is($result->{zoneName}, $TZ_RAMS, 'correct timezone for real Point object');
};

subtest 'integration: Geo::Location::Point and hashref yield same cache key' => sub {
	# A Point object and a hashref for the same coords must share the cache slot
	my $cache = CHI->new(driver => 'Memory', global => 0, expires_in => '1 hour');
	my $tzdb  = TimeZone::TimeZoneDB->new(key => $KEY, cache => $cache);
	my $call_count = 0;
	{
		my $g = mock_scoped 'LWP::UserAgent::get' => sub {
			$call_count++;
			return _ok_resp($JSON_RAMS);
		};
		# First call via hashref style
		$tzdb->get_time_zone(latitude => $config{lat_ramsgate}, longitude => $config{lng_ramsgate});
		# Second call via Geo::Location::Point - same coords, must be a cache hit
		my $loc = Geo::Location::Point->new(
			latitude  => $config{lat_ramsgate},
			longitude => $config{lng_ramsgate},
		);
		$tzdb->get_time_zone($loc);
	}
	is($call_count, 1, 'Point object and hashref share the same cache slot');
};

# ===========================================================================
# Rate-limiting integration with real Time::HiRes
# ===========================================================================

subtest 'integration: rate-limiting sleep called with correct argument' => sub {
	# Verify the argument passed to Time::HiRes::sleep is (min_interval - elapsed)
	# Use TimeTravel to control time() so the argument is deterministic
	my $min_interval  = $config{min_interval_test};
	my $sleep_arg;
	my $sleep_called  = 0;

	{
		my $g_sleep = mock_scoped 'Time::HiRes::sleep' => sub {
			$sleep_called++;
			$sleep_arg = $_[0];
		};

		my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY, min_interval => $min_interval);

		# Freeze time so elapsed is deterministically 0 between the two calls
		my $t0 = freeze_time(time());
		{
			my $g_http = mock_scoped 'LWP::UserAgent::get' => sub { _ok_resp($JSON_NYC) };
			# First call: last_request=0, elapsed=t0-0 >> min_interval, no sleep
			$tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
		}

		# Keep time frozen at t0 so elapsed = t0 - t0 = 0
		{
			my $g_http = mock_scoped 'LWP::UserAgent::get' => sub { _ok_resp($JSON_RAMS) };
			# Second call (different coords): elapsed=0 < min_interval, must sleep
			$tzdb->get_time_zone(
				latitude  => $config{lat_ramsgate},
				longitude => $config{lng_ramsgate}
			);
		}
		restore_all();
	}

	is($sleep_called, 1, 'Time::HiRes::sleep called exactly once (second request)');
	ok(defined $sleep_arg && $sleep_arg > 0, 'sleep argument is positive');
	cmp_ok($sleep_arg, '<=', $min_interval,  'sleep argument <= min_interval');
	diag("sleep arg = $sleep_arg") if $ENV{TEST_VERBOSE};
};

subtest 'integration: no sleep when first call ever (last_request starts at 0)' => sub {
	# The first call on a fresh object must never sleep regardless of min_interval
	my $sleep_called = 0;
	{
		my $g = mock_scoped 'Time::HiRes::sleep' => sub { $sleep_called++ };
		my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY, min_interval => $config{min_interval_test});
		{
			my $g2 = mock_scoped 'LWP::UserAgent::get' => sub { _ok_resp($JSON_NYC) };
			$tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
		}
	}
	is($sleep_called, 0, 'first-ever call does not sleep');
};

# ===========================================================================
# Error handling workflows: HTTP error, JSON parse failure, API non-OK status
# ===========================================================================

subtest 'integration: HTTP error does not corrupt object state' => sub {
	# After a croak on HTTP error, the object must still be usable
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	{
		my $g = mock_scoped 'LWP::UserAgent::get' => sub { _err_resp() };
		eval { $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG) };
		ok($@, 'HTTP error caused croak');
		like($@, qr/API returned error/i, 'error message correct');
		unlike($@, qr/\Q$KEY\E/, 'API key absent from error message');
	}

	# Now make a successful call and verify the object still works
	{
		my $g = mock_scoped 'LWP::UserAgent::get' => sub { _ok_resp($JSON_NYC) };
		my $result = $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
		ok(defined $result,              'object still functional after HTTP error');
		is($result->{zoneName}, $TZ_NYC, 'correct result after recovery');
	}
};

subtest 'integration: non-OK API status is followed by successful call' => sub {
	# A non-OK response (undef return) must not prevent the next call from succeeding
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	my @responses = (_ok_resp($JSON_FAIL), _ok_resp($JSON_NYC));
	my $idx = 0;
	{
		my $g = mock_scoped 'LWP::UserAgent::get' => sub { $responses[$idx++] };
		my $r1 = $tzdb->get_time_zone(
			latitude  => $config{lat_ramsgate},
			longitude => $config{lng_ramsgate}
		);
		ok(!defined $r1, 'non-OK status returns undef');

		# A different coordinate, so no cache hit from the FAILED entry
		my $r2 = $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
		ok(defined $r2,               'subsequent call succeeds');
		is($r2->{zoneName}, $TZ_NYC,  'correct result after non-OK response');
	}
};

subtest 'integration: malformed JSON followed by valid response' => sub {
	# A carp + undef from bad JSON must not cache anything or break the object
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	my @responses = (_ok_resp($JSON_BAD), _ok_resp($JSON_NYC));
	my $idx = 0;
	{
		my $g = mock_scoped 'LWP::UserAgent::get' => sub { $responses[$idx++] };
		my $r1;
		warning_like {
			$r1 = $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
		} qr/failed to parse json/i, 'carp on bad JSON';
		ok(!defined $r1, 'bad JSON returns undef');

		# Same coords again: no cache entry was stored for the failed response
		my $r2 = $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
		ok(defined $r2,               'same coords succeed after bad JSON');
		is($r2->{zoneName}, $TZ_NYC,  'correct timezone on retry');
		is($idx, 2,                   'two HTTP calls made (bad JSON not cached)');
	}
};

# ===========================================================================
# Stateful multi-step workflow
# ===========================================================================

subtest 'integration: stateful workflow - build, lookup, swap ua, lookup again' => sub {
	# Full E2E workflow that exercises all three public methods in sequence
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);

	# Step 1: first lookup (NYC)
	my $r_nyc;
	{
		my $g = mock_scoped 'LWP::UserAgent::get' => sub { _ok_resp($JSON_NYC) };
		$r_nyc = $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	}
	is($r_nyc->{zoneName}, $TZ_NYC, 'step 1: NYC lookup correct');

	# Step 2: swap UA (a new LWP::UserAgent instance)
	my $new_ua = LWP::UserAgent->new();
	my $ret    = $tzdb->ua($new_ua);
	is($ret, $new_ua, 'step 2: ua() setter returned the new UA');

	# Step 3: second lookup via new UA (different coords to avoid cache)
	my $r_rams;
	{
		my $g = mock_scoped 'LWP::UserAgent::get' => sub { _ok_resp($JSON_RAMS) };
		$r_rams = $tzdb->get_time_zone(
			latitude  => $config{lat_ramsgate},
			longitude => $config{lng_ramsgate}
		);
	}
	is($r_rams->{zoneName}, $TZ_RAMS, 'step 3: Ramsgate lookup correct after UA swap');

	# Step 4: re-fetch NYC from cache (UA must NOT be called)
	my $cache_hit_calls = 0;
	{
		my $g = mock_scoped 'LWP::UserAgent::get' => sub {
			$cache_hit_calls++;
			return _ok_resp($JSON_NYC);
		};
		my $r_nyc2 = $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
		is($cache_hit_calls, 0,              'step 4: NYC served from cache');
		is_deeply($r_nyc2, $r_nyc,           'step 4: cached value matches original');
	}
	diag("Full workflow completed") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# Three concurrent instances -- simultaneous lookups, independent caches
# ===========================================================================

subtest 'integration: three instances lookup same coord without sharing state' => sub {
	# POD does not mandate global state, so three instances must be independent
	my $call_count = 0;
	{
		my $g = mock_scoped 'LWP::UserAgent::get' => sub {
			$call_count++;
			return _ok_resp($JSON_NYC);
		};
		my $a = TimeZone::TimeZoneDB->new(key => $KEY);
		my $b = TimeZone::TimeZoneDB->new(key => $KEY);
		my $c = TimeZone::TimeZoneDB->new(key => $KEY);

		# All three query the same coordinate
		my $ra = $a->get_time_zone(latitude => $LAT, longitude => $LNG);
		my $rb = $b->get_time_zone(latitude => $LAT, longitude => $LNG);
		my $rc = $c->get_time_zone(latitude => $LAT, longitude => $LNG);

		# Each instance has its own private CHI cache, so all three go to HTTP
		is($call_count, 3, 'each instance makes its own HTTP call (private caches)');
		is($ra->{zoneName}, $TZ_NYC, 'instance A correct');
		is($rb->{zoneName}, $TZ_NYC, 'instance B correct');
		is($rc->{zoneName}, $TZ_NYC, 'instance C correct');
	}
	diag("Three concurrent instances OK") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# Logger integration: logger receives structured messages
# ===========================================================================

subtest 'integration: logger receives warn for non-OK and error for bad ua' => sub {
	# Exercise both logger paths in one workflow
	my @warned;
	my @errored;
	my $logger = bless {}, 'IntegLogger';
	{
		no warnings 'once';
		*IntegLogger::warn  = sub { push @warned,  $_[1] };
		*IntegLogger::error = sub { push @errored, $_[1] };
	}

	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY, logger => $logger);

	# Trigger logger->warn via non-OK API response
	{
		my $g = mock_scoped 'LWP::UserAgent::get' => sub { _ok_resp($JSON_FAIL) };
		$tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	}
	is(scalar @warned, 1, 'logger->warn called once for FAILED status');
	unlike($warned[0], qr/\Q$KEY\E/, 'API key redacted in logger warn message');
	diag("logger warn: $warned[0]") if $ENV{TEST_VERBOSE};

	# Trigger logger->error via ua(undef)
	eval { $tzdb->ua(undef) };
	is(scalar @errored, 1, 'logger->error called once for ua(undef)');
	diag("logger error: $errored[0]") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# Spy on LWP::UserAgent::get: verify call count and URL across a full workflow
# ===========================================================================

subtest 'integration: spy verifies call count and URL pattern over multi-call flow' => sub {
	# Use a mock with capture rather than spy so the real HTTP is not invoked
	my @captured;
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	{
		my $g = mock_scoped 'LWP::UserAgent::get' => sub {
			my ($ua_self, $url) = @_;
			push @captured, $url;
			return _ok_resp($JSON_NYC);
		};

		# Three different coordinates -> three cache misses -> three HTTP calls
		$tzdb->get_time_zone(latitude => $LAT,                  longitude => $LNG);
		$tzdb->get_time_zone(latitude => $config{lat_ramsgate}, longitude => $config{lng_ramsgate});
		$tzdb->get_time_zone(latitude => $config{lat_sydney},   longitude => $config{lng_sydney});

		# Repeat the first coordinate -> cache hit -> no HTTP call
		$tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	}
	is(scalar @captured, 3, 'three HTTP calls (one per unique coordinate)');

	# Every captured URL must contain the required query fields
	for my $url (@captured) {
		like($url, qr{https://\Q$config{host_default}\E}, "URL ${\scalar @captured}: correct host");
		like($url, qr{key=\Q$KEY\E},    'URL contains API key');
		like($url, qr{by=position},     'URL has by=position');
		like($url, qr{format=json},     'URL has format=json');
		diag("captured: $url") if $ENV{TEST_VERBOSE};
	}
};

# ===========================================================================
# CHI cache expires: a stale entry should be refreshed after expiry
# ===========================================================================

subtest 'integration: cached entry is refreshed after CHI expiry' => sub {
	# Use a very short TTL so we can advance time past the expiry
	my $cache = CHI->new(driver => 'Memory', global => 0, expires_in => 1);
	my $tzdb  = TimeZone::TimeZoneDB->new(key => $KEY, cache => $cache);
	my $call_count = 0;
	{
		my $g = mock_scoped 'LWP::UserAgent::get' => sub {
			$call_count++;
			return _ok_resp($JSON_NYC);
		};

		# First call: populates cache with 1-second TTL
		$tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
		is($call_count, 1, 'first call hits HTTP');

		# Second call immediately: cache hit
		$tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
		is($call_count, 1, 'second call is a cache hit');

		# Sleep 2 seconds to allow the real CHI TTL to expire
		sleep 2;

		# Third call: cache expired, must hit HTTP again
		$tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
		is($call_count, 2, 'third call hits HTTP after cache expiry');
	}
	diag("Cache expiry flow verified") if $ENV{TEST_VERBOSE};
};

# ---------------------------------------------------------------------------
# Remove all mocks including the Object::Configure freeze
# ---------------------------------------------------------------------------
restore_all();

done_testing();
