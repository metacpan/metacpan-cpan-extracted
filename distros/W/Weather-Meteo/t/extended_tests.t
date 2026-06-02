#!/usr/bin/env perl

# extended_tests.t -- coverage-driven tests targeting uncovered branches
# and conditions identified via Devel::Cover analysis of the full test suite.
#
# Each subtest here covers a specific code path not exercised elsewhere:
# timezone handling, location-arg short-circuits, HTTP response guard
# sub-conditions, coordinate normalisation completion, and constructor
# branch completeness.

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

# ---------------------------------------------------------------------------
# Constants -- baseline values and exact error fragments
# ---------------------------------------------------------------------------
Readonly my $LAT          => '51.34';
Readonly my $LON          => '1.42';
Readonly my $DATE         => '2022-12-25';
Readonly my $DATE2        => '2023-06-15';
Readonly my $DEFAULT_HOST => 'archive-api.open-meteo.com';
Readonly my $DEFAULT_TZ   => 'Europe/London';
Readonly my $ALT_TZ       => 'America/New_York';
Readonly my $ERR_USAGE    => 'Usage: weather(latitude';
Readonly my $ERR_BAD_RESP => 'did not return a valid HTTP response';

# ---------------------------------------------------------------------------
# %config -- non-constant values
# ---------------------------------------------------------------------------
my %config = (
	ok_json      => '{"hourly":{"temperature_2m":[1,2,3],"rain":[0,0,0],'
	             .  '"snowfall":[0,0,0],"weathercode":[1,2,1]}}',
	custom_host  => 'myapi.example.com',
	min_interval => 5,
);

# ---------------------------------------------------------------------------
# Helper: fresh isolated CHI cache
# ---------------------------------------------------------------------------
sub _fresh_cache {
	return CHI->new(driver => 'Memory', global => 0, expires_in => '1 hour');
}

# ---------------------------------------------------------------------------
# Helper: mock LWP::UserAgent::get to return a valid response and capture URL.
# Stores the last requested URL in the supplied scalar reference.
# ---------------------------------------------------------------------------
sub _mock_capture_url {
	my ($url_ref) = @_;
	mock 'LWP::UserAgent::get' => sub {
		my ($self_ua, $url) = @_;
		${$url_ref} = $url;
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{ok_json});
		return $r;
	};
}

# ---------------------------------------------------------------------------
# Helper: mock UA to return ok_json and count calls.
# ---------------------------------------------------------------------------
sub _mock_counting_ua {
	my ($count_ref) = @_;
	mock 'LWP::UserAgent::get' => sub {
		$$count_ref++;
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{ok_json});
		return $r;
	};
}

# ===========================================================================
# SECTION 1: Location argument short-circuit branches
# ===========================================================================

# Purpose: two-arg form where the first arg is an unblessed reference must
# fall to the else branch; without lat/lon the code croaks with the usage string.
subtest 'weather() -- two-arg form, first arg unblessed: croaks with usage' => sub {
	my $meteo = Weather::Meteo->new();

	# An unblessed arrayref is not a location object -- falls to Params::Get
	throws_ok { $meteo->weather([], $DATE) }
		qr/\Q$ERR_USAGE\E/,
		'two-arg unblessed ref: croak contains usage string';

	diag("err fragment: $ERR_USAGE") if $ENV{TEST_VERBOSE};
};

# Purpose: two-arg form where first arg IS blessed but has no latitude()
# method -- condition $_[0]->can('latitude') is false; falls to else branch.
subtest 'weather() -- two-arg form, blessed but no latitude(): croaks' => sub {
	my $meteo = Weather::Meteo->new();

	# Blessed object without latitude() / longitude()
	my $no_lat = bless {}, 'BlessedNoLat';
	throws_ok { $meteo->weather($no_lat, $DATE) }
		qr/\Q$ERR_USAGE\E/,
		'two-arg blessed-no-lat: croak contains usage string';
};

# Purpose: named-location form where the location value is not blessed --
# Scalar::Util::blessed returns false so lat stays undef, triggering croak.
subtest 'weather() -- named location is unblessed hashref: croaks' => sub {
	my $meteo = Weather::Meteo->new();

	throws_ok { $meteo->weather({ location => {}, date => $DATE }) }
		qr/\Q$ERR_USAGE\E/,
		'named-location unblessed hashref: croak contains usage string';
};

# Purpose: named-location blessed but lacking latitude() -- can('latitude')
# returns false so the short-circuit exits without extracting coords.
subtest 'weather() -- named location blessed but no latitude(): croaks' => sub {
	my $meteo = Weather::Meteo->new();
	my $obj   = bless {}, 'BlessedNoLat2';

	throws_ok { $meteo->weather({ location => $obj, date => $DATE }) }
		qr/\Q$ERR_USAGE\E/,
		'named-location blessed-no-lat: croak contains usage string';
};

# ===========================================================================
# SECTION 2: Timezone (tz) parameter handling
# ===========================================================================

# Purpose: when TIMEZONEDB_KEY is set and the location object has a tz()
# method, weather() must call tz() and use the returned timezone in the URL.
# This covers the `$_[0]->can('tz') && $ENV{'TIMEZONEDB_KEY'}` TRUE branch.
subtest 'weather() -- TIMEZONEDB_KEY set: tz() called and used in URL' => sub {
	{
		# Minimal stand-in for Geo::Location::Point with timezone support
		package TZAwareLoc;
		sub new       { bless {}, shift }
		sub latitude  { $LAT }
		sub longitude { $LON }
		sub tz        { $ALT_TZ }
	}

	my $captured_url = '';
	_mock_capture_url(\$captured_url);

	# Temporarily set the env var that enables the tz() path
	local $ENV{TIMEZONEDB_KEY} = 'test_api_key';

	my $loc   = TZAwareLoc->new();
	my $meteo = Weather::Meteo->new(cache => _fresh_cache());
	$meteo->weather($loc, $DATE);

	# The URL must contain the alternative timezone, not the default
	like($captured_url,   qr/America/, 'ALT_TZ appears in URL when TIMEZONEDB_KEY set');
	unlike($captured_url, qr/London/,  'default TZ absent when location tz used');

	restore_all();
	diag("url=$captured_url") if $ENV{TEST_VERBOSE};
};

# Purpose: when can('tz') is true but TIMEZONEDB_KEY is NOT set, the tz()
# method must NOT be called -- default timezone must be used instead.
# This covers the FALSE branch of `$_[0]->can('tz') && $ENV{TIMEZONEDB_KEY}`.
subtest 'weather() -- can(tz) true but no TIMEZONEDB_KEY: default tz used' => sub {
	my $captured_url = '';
	_mock_capture_url(\$captured_url);

	# TIMEZONEDB_KEY is deliberately absent
	local $ENV{TIMEZONEDB_KEY} = undef;
	delete $ENV{TIMEZONEDB_KEY};

	my $loc   = TZAwareLoc->new();
	my $meteo = Weather::Meteo->new(cache => _fresh_cache());
	$meteo->weather($loc, $DATE);

	# Without the key, tz() is not called; the default timezone is used
	like($captured_url, qr/London/, 'default London tz used without TIMEZONEDB_KEY');

	restore_all();
	diag("url=$captured_url") if $ENV{TEST_VERBOSE};
};

# Purpose: explicit tz parameter in the hashref call form must flow through
# to the request URL and the cache key.
subtest 'weather() -- explicit tz in hashref form appears in URL' => sub {
	my $captured_url = '';
	_mock_capture_url(\$captured_url);

	my $meteo = Weather::Meteo->new(cache => _fresh_cache());
	$meteo->weather({ latitude => $LAT, longitude => $LON,
	                  date => $DATE, tz => $ALT_TZ });

	like($captured_url, qr/America/, 'explicit ALT_TZ appears in URL');
	restore_all();
	diag("url=$captured_url") if $ENV{TEST_VERBOSE};
};

# Purpose: two calls with the same coords and date but different tz values
# must each make a network request because they have different cache keys.
subtest 'weather() -- different tz values produce separate cache keys' => sub {
	my $call_count = 0;
	_mock_counting_ua(\$call_count);

	my $meteo = Weather::Meteo->new(cache => _fresh_cache());

	# Call once with default tz, once with alternative tz
	$meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });
	$meteo->weather({ latitude => $LAT, longitude => $LON,
	                  date => $DATE, tz => $ALT_TZ });

	cmp_ok($call_count, '==', 2, 'different tz values produce two UA calls');

	restore_all();
	diag("call_count=$call_count") if $ENV{TEST_VERBOSE};
};

# Purpose: passing tz='Europe/London' explicitly must produce the same cache
# key as not passing tz at all (the default is 'Europe/London').
subtest 'weather() -- explicit default tz same as omitting tz' => sub {
	my $call_count = 0;
	_mock_counting_ua(\$call_count);

	my $meteo = Weather::Meteo->new(cache => _fresh_cache());

	# First call with no tz (defaults to Europe/London)
	$meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	# Second call with explicit Europe/London -- should hit the same cache key
	$meteo->weather({ latitude => $LAT, longitude => $LON,
	                  date => $DATE, tz => $DEFAULT_TZ });

	cmp_ok($call_count, '==', 1, 'explicit default tz hits same cache entry');

	restore_all();
	diag("call_count=$call_count") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# SECTION 3: HTTP response guard sub-conditions
# ===========================================================================

# Purpose: when UA->get returns a blessed object that lacks is_error(), the
# module must carp and return undef without an unhandled "can't call method" die.
# This covers the `$res->can('is_error')` sub-condition in the guard.
subtest 'weather() -- UA returns blessed object without is_error: carp + undef' => sub {
	# An object that has no is_error method
	my $bad_resp = bless {}, 'WeirdResponse';
	mock 'LWP::UserAgent::get' => sub { $bad_resp };

	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $warned = 0;
	local $SIG{__WARN__} = sub { $warned++ };

	my $result;
	lives_ok { $result = $meteo->weather({ latitude => $LAT, longitude => $LON,
	                                       date => $DATE }) }
		'blessed-no-is_error: no unhandled exception';
	ok(!defined($result), 'blessed-no-is_error: returns undef');
	ok($warned,           'blessed-no-is_error: carp emitted');

	restore_all();
	diag("warned=$warned") if $ENV{TEST_VERBOSE};
};

# Purpose: the carp message for a bad UA response must mention the module name
# and the diagnostic phrase so the caller can identify the problem.
subtest 'weather() -- bad UA response carp message is descriptive' => sub {
	mock 'LWP::UserAgent::get' => sub { bless {}, 'WeirdResponse2' };

	my $meteo = Weather::Meteo->new(cache => _fresh_cache());
	warning_like { $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE }) }
		qr/\Q$ERR_BAD_RESP\E/,
		'bad UA response: warning says "did not return a valid HTTP response"';

	restore_all();
};

# Purpose: UA returning defined scalar 1 (truthy but not a ref) must be handled
# by the guard the same way as undef -- covers the `ref($res)` sub-condition.
subtest 'weather() -- UA returns 1 (defined non-ref): carp + undef' => sub {
	mock 'LWP::UserAgent::get' => sub { 1 };

	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $warned = 0;
	local $SIG{__WARN__} = sub { $warned++ };

	my $result;
	lives_ok { $result = $meteo->weather({ latitude => $LAT, longitude => $LON,
	                                       date => $DATE }) }
		'UA returns 1: no unhandled exception';
	ok(!defined($result), 'UA returns 1: result is undef');
	ok($warned,           'UA returns 1: carp emitted');

	restore_all();
	diag("warned=$warned") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# SECTION 4: Coordinate normalisation completion
# ===========================================================================

# Purpose: a leading-decimal longitude '.0' must be normalised to '0.0' and
# the request must proceed.  Paired with lat='.0' to also cover both
# lat and lon normalisation in one call.
subtest 'weather() -- leading-decimal ".0" for both lat and lon normalised' => sub {
	my $captured_url = '';
	_mock_capture_url(\$captured_url);

	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $result = $meteo->weather({ latitude => '.0', longitude => '.0', date => $DATE });

	ok(defined($result), 'lat=".0" lon=".0": result defined');

	# URL must contain 0.0 (the normalised form) not bare ".0"
	like($captured_url, qr/latitude=0\.0/, 'lat normalised to 0.0 in URL');
	like($captured_url, qr/longitude=0\.0/, 'lon normalised to 0.0 in URL');

	restore_all();
	diag("url=$captured_url") if $ENV{TEST_VERBOSE};
};

# Purpose: a negative leading-decimal longitude '-.4' must be normalised to
# '-0.4'.  This completes coverage of the `/^\-\.(\d+)$/` branch for longitude.
subtest 'weather() -- negative leading-decimal longitude "-.4" normalised' => sub {
	my $captured_url = '';
	_mock_capture_url(\$captured_url);

	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $result = $meteo->weather({ latitude => $LAT, longitude => '-.4', date => $DATE });

	ok(defined($result), 'lon="-.4": result defined');
	like($captured_url, qr/longitude=-0\.4/, 'lon normalised to -0.4 in URL');

	restore_all();
	diag("url=$captured_url") if $ENV{TEST_VERBOSE};
};

# Purpose: integer coordinates (no decimal part) must pass the `/^-?\d+(\.\d+)?$/`
# pattern with the optional decimal group absent.
subtest 'weather() -- integer coordinates accepted without decimal' => sub {
	my $captured_url = '';
	_mock_capture_url(\$captured_url);

	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $result = $meteo->weather({ latitude => 51, longitude => 1, date => $DATE });

	ok(defined($result), 'integer coords: result defined');
	like($captured_url, qr/latitude=51[^.]/, 'integer lat in URL without decimal');

	restore_all();
	diag("url=$captured_url") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# SECTION 5: new() constructor branches
# ===========================================================================

# Purpose: passing a truthy host to new() must cover the truthy branch of
# `$params->{host} || 'archive-api...'` and use the supplied host.
subtest 'new() -- explicit truthy host stored and used in requests' => sub {
	my $captured_url = '';
	_mock_capture_url(\$captured_url);

	# Pass a real custom host value (truthy string)
	my $meteo = Weather::Meteo->new(
		host  => $config{custom_host},
		cache => _fresh_cache(),
	);
	$meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	like($captured_url, qr/\Q$config{custom_host}\E/, 'custom host in URL');
	restore_all();
	diag("url=$captured_url") if $ENV{TEST_VERBOSE};
};

# Purpose: passing an explicit ua to new() must cover the FALSE branch of
# `if(!defined($ua))` so LWP::UserAgent->new() is NOT called.
subtest 'new() -- explicit ua covers !defined(ua) FALSE branch' => sub {
	my $explicit_ua = LWP::UserAgent->new();

	# The object returned must expose our exact ua instance via ua()
	my $meteo = Weather::Meteo->new(ua => $explicit_ua);
	is($meteo->ua(), $explicit_ua, 'explicit ua returned by ua() accessor');

	diag('explicit ua branch ok') if $ENV{TEST_VERBOSE};
};

# Purpose: passing an explicit cache object to new() must cover the truthy
# branch of `$params->{cache} || CHI->new(...)` so CHI is not instantiated.
subtest 'new() -- explicit cache covers the cache || CHI branch' => sub {
	my $my_cache = _fresh_cache();
	my $meteo    = Weather::Meteo->new(cache => $my_cache);

	# If our cache was used, a weather() call should populate it
	mock 'LWP::UserAgent::get' => sub {
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{ok_json});
		return $r;
	};
	$meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	# The explicit cache should now contain the result
	my $cached = $my_cache->get("weather:$LAT:$LON:$DATE:$DEFAULT_TZ");
	ok(defined($cached), 'result stored in the explicitly supplied cache');

	restore_all();
	diag('explicit cache branch ok') if $ENV{TEST_VERBOSE};
};

# Purpose: passing a positive min_interval to new() must cover the truthy
# branch of `$params->{min_interval} || MIN_INTERVAL`.
subtest 'new() -- positive min_interval covers the min_interval || branch' => sub {
	# 5 seconds is clearly truthy; internal slot must hold 5 not 0
	my $meteo = Weather::Meteo->new(min_interval => $config{min_interval});
	isa_ok($meteo, 'Weather::Meteo', 'new() with min_interval=5 succeeds');

	# Verify the value is stored (using a white-box peek -- the only way)
	cmp_ok($meteo->{'min_interval'}, '==', $config{min_interval},
		'min_interval=5 stored correctly');

	diag('min_interval truthy branch ok') if $ENV{TEST_VERBOSE};
};

# Purpose: passing min_interval=0 must NOT override it with MIN_INTERVAL (also 0)
# because `0 || 0 = 0`.  Verify the constructor accepts zero explicitly.
subtest 'new() -- min_interval=0 explicit still stored as 0' => sub {
	my $meteo = Weather::Meteo->new(min_interval => 0);
	isa_ok($meteo, 'Weather::Meteo', 'new() with explicit min_interval=0');
	cmp_ok($meteo->{'min_interval'}, '==', 0, 'explicit 0 stored as 0');
};

# ===========================================================================
# SECTION 6: HTTP error path details
# ===========================================================================

# Purpose: HTTP 404 (not found) triggers is_error() just like 500; verify
# the module treats all 4xx/5xx responses the same way.
subtest 'weather() -- HTTP 404 is treated as an error' => sub {
	mock 'LWP::UserAgent::get' => sub { HTTP::Response->new(404, 'Not Found') };

	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $warned = 0;
	local $SIG{__WARN__} = sub { $warned++ };

	my $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	ok(!defined($result), 'HTTP 404: returns undef');
	ok($warned,           'HTTP 404: carp emitted');

	restore_all();
	diag("warned=$warned") if $ENV{TEST_VERBOSE};
};

# Purpose: the HTTP error carp message must include the URL so the caller
# can diagnose which endpoint failed.
subtest 'weather() -- HTTP error carp message contains the request URL' => sub {
	mock 'LWP::UserAgent::get' => sub { HTTP::Response->new(500, 'Server Error') };

	my $meteo   = Weather::Meteo->new(cache => _fresh_cache());
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };

	$meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	ok(scalar(@warnings), 'HTTP error: at least one warning emitted');

	# Warning must mention the host so the caller can diagnose the endpoint
	like($warnings[0], qr/\Q$DEFAULT_HOST\E/, 'HTTP error warning contains host');

	restore_all();
	diag("warning: $warnings[0]") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# SECTION 7: Cache key verification
# ===========================================================================

# Purpose: the cache key must encode all four components so that requests
# that differ only in tz do not collide.  Verify the exact format.
subtest 'weather() -- cache key encodes lat:lon:date:tz' => sub {
	my $cache = _fresh_cache();
	mock 'LWP::UserAgent::get' => sub {
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{ok_json});
		return $r;
	};

	my $meteo = Weather::Meteo->new(cache => $cache);
	$meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	# The expected key is the documented format
	my $expected_key = "weather:$LAT:$LON:$DATE:$DEFAULT_TZ";
	ok(defined($cache->get($expected_key)), "cache entry exists under key '$expected_key'");

	restore_all();
	diag("key=$expected_key") if $ENV{TEST_VERBOSE};
};

# Purpose: a request with an explicit tz must land under a DIFFERENT cache key
# from the same request with the default tz.
subtest 'weather() -- cache key differs when tz differs' => sub {
	my $cache = _fresh_cache();
	mock 'LWP::UserAgent::get' => sub {
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{ok_json});
		return $r;
	};

	my $meteo = Weather::Meteo->new(cache => $cache);
	$meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });
	$meteo->weather({ latitude => $LAT, longitude => $LON,
	                  date => $DATE, tz => $ALT_TZ });

	# Both keys must exist independently
	my $key_default = "weather:$LAT:$LON:$DATE:$DEFAULT_TZ";
	my $key_alt     = "weather:$LAT:$LON:$DATE:$ALT_TZ";
	ok(defined($cache->get($key_default)), 'default tz key present');
	ok(defined($cache->get($key_alt)),     'alt tz key present');

	restore_all();
	diag("key_default=$key_default  key_alt=$key_alt") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# SECTION 8: Constructor and accessor completeness
# ===========================================================================

# Purpose: cloning an object must inherit host, min_interval, and cache from
# the original, covering all constructor field inheritance paths.
subtest 'new() -- clone inherits host, min_interval, and cache from original' => sub {
	my $custom_cache = _fresh_cache();
	my $orig = Weather::Meteo->new(
		host         => $config{custom_host},
		min_interval => $config{min_interval},
		cache        => $custom_cache,
	);

	# Cloning with no overrides must copy all fields
	my $clone = $orig->new();

	isa_ok($clone, 'Weather::Meteo', 'clone is a Weather::Meteo');
	cmp_ok($clone->{'min_interval'}, '==', $config{min_interval}, 'clone inherits min_interval');
	is($clone->{'host'},             $config{custom_host},        'clone inherits host');
	is($clone->{'cache'},            $custom_cache,               'clone inherits cache');

	diag('clone inheritance ok') if $ENV{TEST_VERBOSE};
};

# Purpose: calling ua() as a setter must return the new UA object, not undef.
subtest 'ua() -- setter return value is the new UA' => sub {
	my $meteo  = Weather::Meteo->new();
	my $new_ua = LWP::UserAgent->new();

	# In this module ua() returns $self->{ua}, which is set to $new_ua
	my $returned = $meteo->ua($new_ua);
	is($returned, $new_ua, 'ua() setter returns the newly stored UA');

	diag('ua() setter return value ok') if $ENV{TEST_VERBOSE};
};

# Purpose: confirm that weather() returns_ok against the hashref schema and
# also that the return value is identical on the second (cached) call.
subtest 'weather() -- cached result satisfies hashref schema' => sub {
	my $cache = _fresh_cache();
	mock 'LWP::UserAgent::get' => sub {
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{ok_json});
		return $r;
	};

	my $meteo = Weather::Meteo->new(cache => $cache);
	my $r1    = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });
	my $r2    = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	# First call: verify type
	returns_ok($r1, { type => 'hashref' }, 'first result satisfies hashref schema');

	# Second call from cache must be structurally identical
	is_deeply($r2, $r1, 'cached result is deeply equal to original');

	restore_all();
	diag('cache round-trip schema ok') if $ENV{TEST_VERBOSE};
};

done_testing();
