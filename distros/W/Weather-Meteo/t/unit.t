#!/usr/bin/env perl

# unit.t -- black-box tests for Weather::Meteo
#
# Every test exercises only the public API as documented in the module POD.
# No object internals are inspected directly; behaviour is inferred from
# return values, captured HTTP requests, and side effects observable
# through the documented interface.

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
# Constants -- all literal values live here so tests read as prose
# ---------------------------------------------------------------------------
Readonly my $LAT          => '51.34';
Readonly my $LON          => '1.42';
Readonly my $DATE         => '2022-12-25';
Readonly my $PRE_1940     => '1939-12-31';
Readonly my $FIRST_YEAR   => 1940;
Readonly my $BAD_DATE     => 'not-a-date';
Readonly my $DEFAULT_HOST => 'archive-api.open-meteo.com';

# Error-message fragments that must appear verbatim in croak/carp text
Readonly my $ERR_USAGE     => 'Usage: weather(latitude';
Readonly my $ERR_BAD_COORD => 'Invalid latitude/longitude format';
Readonly my $ERR_BAD_DATE  => "'${\$BAD_DATE}' is not a valid date";
Readonly my $ERR_BAD_FMT   => 'Invalid date format. Expected YYYY-MM-DD';
Readonly my $ERR_BAD_UA    => 'must be an object that understands the get method';

# ---------------------------------------------------------------------------
# %config -- everything that is not a Readonly constant
# ---------------------------------------------------------------------------
my %config = (
	hourly_json    => '{"hourly":{"temperature_2m":[5,6,7],"rain":[0,0,0]},'
	               . '"daily":{"temperature_2m_max":[12]}}',
	no_hourly_json => '{"daily":{"temperature_2m_max":[10]}}',
	api_error_json => '{"error":true,"reason":"Bad coords"}',
	invalid_json   => 'not valid json',
	custom_host    => 'test-host.example.com',
	min_interval   => 0,

	# Realistic forecast response including sunrise/sunset in daily
	forecast_json  => '{"hourly":{"temperature_2m":[15,16,17],"rain":[0,0,0],'
	               . '"snowfall":[0,0,0],"weathercode":[2,2,2]},'
	               . '"daily":{"time":["2026-07-14"],'
	               . '"sunrise":["2026-07-14T04:52"],"sunset":["2026-07-14T21:18"],'
	               . '"weathercode":[2],"temperature_2m_max":[22.5],"temperature_2m_min":[14.2],'
	               . '"rain_sum":[0.0],"snowfall_sum":[0.0],"precipitation_hours":[0.0],'
	               . '"windspeed_10m_max":[15.3],"windgusts_10m_max":[28.7]}}',

	# Minimal daily-only response for sunrise_sunset()
	sunrise_json   => '{"daily":{"time":["2022-12-25"],'
	               . '"sunrise":["2022-12-25T08:09"],"sunset":["2022-12-25T15:57"]}}',
);

# ---------------------------------------------------------------------------
# _fresh_cache -- isolated in-memory cache; prevents cross-subtest leakage
# ---------------------------------------------------------------------------
sub _fresh_cache {
	return CHI->new(driver => 'Memory', global => 0, expires_in => '1 hour');
}

# ---------------------------------------------------------------------------
# _mock_ok_ua -- mocks LWP::UserAgent::get to return a valid hourly response.
# Optionally captures the URL into a scalar ref for later inspection.
# Always pair with restore_all() at the end of the subtest.
# ---------------------------------------------------------------------------
sub _mock_ok_ua {
	my ($url_capture_ref) = @_;
	mock 'LWP::UserAgent::get' => sub {
		my ($self_ua, $url) = @_;
		${$url_capture_ref} = $url if $url_capture_ref;
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{hourly_json});
		return $r;
	};
}

# ===========================================================================
# POD-documented behaviour: new()
# ===========================================================================

# Purpose: new() must return a blessed Weather::Meteo object.
subtest 'new() -- returns a Weather::Meteo object' => sub {
	my $meteo = Weather::Meteo->new();

	isa_ok($meteo, 'Weather::Meteo', 'new() returns correct class');
	returns_ok($meteo, { type => 'object' }, 'return satisfies object schema');

	diag('new() class ok') if $ENV{TEST_VERBOSE};
};

# Purpose: the returned object must expose the documented public methods.
subtest 'new() -- returned object has all documented public methods' => sub {
	my $meteo = Weather::Meteo->new();

	# POD documents five public methods
	ok($meteo->can('new'),            'new() method available');
	ok($meteo->can('weather'),        'weather() method available');
	ok($meteo->can('forecast'),       'forecast() method available');
	ok($meteo->can('sunrise_sunset'), 'sunrise_sunset() method available');
	ok($meteo->can('ua'),             'ua() method available');

	diag('public methods ok') if $ENV{TEST_VERBOSE};
};

# Purpose: without a 'ua' argument, new() must auto-create an HTTP user agent.
subtest 'new() -- default ua is an LWP::UserAgent (via ua() accessor)' => sub {
	my $meteo = Weather::Meteo->new();
	my $ua    = $meteo->ua();

	# POD says: "If not provided, a default user agent is created."
	ok(defined($ua),               'default ua is defined');
	ok($ua->can('get'),            'default ua can perform GET');
	ok($ua->isa('LWP::UserAgent'), 'default ua is LWP::UserAgent');

	diag('default ua ok') if $ENV{TEST_VERBOSE};
};

# Purpose: a custom ua passed to new() must be accessible through ua().
subtest 'new() -- custom ua is stored and returned by ua()' => sub {
	my $custom_ua = LWP::UserAgent->new();
	my $meteo     = Weather::Meteo->new(ua => $custom_ua);

	# POD says the ua option is honoured
	is($meteo->ua(), $custom_ua, 'custom ua accessible via ua()');

	diag('custom ua stored ok') if $ENV{TEST_VERBOSE};
};

# Purpose: a custom host must be used in subsequent requests.
subtest 'new() -- custom host appears in the request URL' => sub {
	my $captured_url = '';
	_mock_ok_ua(\$captured_url);

	# Create with a custom host and make one weather() request to observe it
	my $meteo = Weather::Meteo->new(
		host  => $config{custom_host},
		cache => _fresh_cache(),
	);
	$meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	like($captured_url, qr/\Q$config{custom_host}\E/, 'custom host appears in request URL');

	restore_all();
	diag("url=$captured_url") if $ENV{TEST_VERBOSE};
};

# Purpose: when no host is given the default host must be used.
subtest 'new() -- default host is archive-api.open-meteo.com' => sub {
	my $captured_url = '';
	_mock_ok_ua(\$captured_url);

	my $meteo = Weather::Meteo->new(cache => _fresh_cache());
	$meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	like($captured_url, qr/\Q$DEFAULT_HOST\E/, 'default host in request URL');

	restore_all();
	diag("url=$captured_url") if $ENV{TEST_VERBOSE};
};

# Purpose: calling new() on an existing instance must return a clone.
subtest 'new() -- cloning an instance returns another Weather::Meteo' => sub {
	my $orig  = Weather::Meteo->new(ua => LWP::UserAgent->new());
	my $clone = $orig->new();

	isa_ok($clone, 'Weather::Meteo', 'clone is a Weather::Meteo');

	# The clone must be a separate object reference
	isnt($clone, $orig, 'clone is a distinct object');

	diag('clone ok') if $ENV{TEST_VERBOSE};
};

# Purpose: a clone with an override must use the overridden ua.
subtest 'new() -- clone with override uses the new ua' => sub {
	my $orig_ua = LWP::UserAgent->new();
	my $new_ua  = LWP::UserAgent->new();

	my $orig     = Weather::Meteo->new(ua => $orig_ua);
	my $override = $orig->new(ua => $new_ua);

	is($override->ua(), $new_ua, 'override ua takes precedence in clone');

	diag('clone override ok') if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# POD-documented behaviour: ua()
# ===========================================================================

# Purpose: getter form -- ua() with no args must return the current UA.
subtest 'ua() -- getter returns an object that can get()' => sub {
	my $meteo = Weather::Meteo->new();
	my $ua    = $meteo->ua();

	# POD: "Accessor method to get and set UserAgent object used internally."
	ok(defined($ua),  'ua() returns a defined value');
	ok($ua->can('get'), 'returned ua can get()');
	returns_ok($ua, { type => 'object' }, 'ua() return satisfies object schema');

	diag('ua getter ok') if $ENV{TEST_VERBOSE};
};

# Purpose: setter form -- ua($new) must store and then return the new UA.
subtest 'ua() -- setter stores the new UA and getter reflects it' => sub {
	my $meteo  = Weather::Meteo->new();
	my $new_ua = LWP::UserAgent->new();

	# After setting, the getter must return what was set
	$meteo->ua($new_ua);
	is($meteo->ua(), $new_ua, 'getter returns the newly set UA');

	diag('ua setter ok') if $ENV{TEST_VERBOSE};
};

# Purpose: ua() must croak when given an object that lacks get().
subtest 'ua() -- croaks if argument cannot get()' => sub {
	my $meteo  = Weather::Meteo->new();
	my $bad_ua = bless {}, 'NoGetUA';

	# POD (API spec): ua must be an object that can 'get'
	eval { $meteo->ua($bad_ua) };
	ok($@, 'ua() dies on invalid argument');

	diag("error: $@") if $ENV{TEST_VERBOSE};
};

# Purpose: the croak message must contain the documented error text.
subtest 'ua() -- croak message names the required method' => sub {
	my $meteo  = Weather::Meteo->new();
	my $bad_ua = bless {}, 'NoGetUA2';

	throws_ok { $meteo->ua($bad_ua) }
		qr/\Q$ERR_BAD_UA\E/,
		'error text mentions "get method"';

	diag("err_fragment=$ERR_BAD_UA") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# POD-documented behaviour: weather() -- argument forms
# ===========================================================================

# Purpose: hashref form -- the canonical documented call form.
subtest 'weather() -- hashref args return a hashref with hourly key' => sub {
	_mock_ok_ua();
	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	# POD: returns weather data as a hashref
	ok(defined($result),            'hashref args: result defined');
	returns_ok($result, { type => 'hashref' }, 'result is a hashref');
	ok(exists($result->{'hourly'}), 'result contains hourly key');

	restore_all();
	diag('hashref args ok') if $ENV{TEST_VERBOSE};
};

# Purpose: flat key/value form is documented as equivalent to hashref form.
subtest 'weather() -- flat list args work the same as hashref' => sub {
	_mock_ok_ua();
	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $result = $meteo->weather(latitude => $LAT, longitude => $LON, date => $DATE);

	ok(defined($result),            'flat args: result defined');
	ok(exists($result->{'hourly'}), 'flat args: hourly key present');

	restore_all();
	diag('flat args ok') if $ENV{TEST_VERBOSE};
};

# Purpose: (Geo::Location::Point, date) form as documented in the POD.
subtest 'weather() -- (location_obj, date) positional form' => sub {
	_mock_ok_ua();

	# Build a minimal stand-in for Geo::Location::Point
	my $loc = bless {}, 'FakePoint';
	mock 'FakePoint::latitude'  => sub { $LAT };
	mock 'FakePoint::longitude' => sub { $LON };

	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $result = $meteo->weather($loc, $DATE);

	ok(defined($result),            'location+date: result defined');
	ok(exists($result->{'hourly'}), 'location+date: hourly key present');

	restore_all();
	diag('positional form ok') if $ENV{TEST_VERBOSE};
};

# Purpose: { location => $obj, date => $d } named form also in the POD.
subtest 'weather() -- named location => $obj form' => sub {
	_mock_ok_ua();

	my $loc = bless {}, 'FakePoint2';
	mock 'FakePoint2::latitude'  => sub { $LAT };
	mock 'FakePoint2::longitude' => sub { $LON };

	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $result = $meteo->weather({ location => $loc, date => $DATE });

	ok(defined($result),            'named location: result defined');
	ok(exists($result->{'hourly'}), 'named location: hourly key present');

	restore_all();
	diag('named location ok') if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# POD-documented behaviour: weather() -- date handling
# ===========================================================================

# Purpose: POD says dates before 1940 return undef.
subtest 'weather() -- pre-1940 date returns undef without warning' => sub {
	my $meteo   = Weather::Meteo->new();
	my $warned  = 0;
	local $SIG{__WARN__} = sub { $warned++ };

	my $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $PRE_1940 });

	# Must be silent -- no carp, no croak
	ok(!defined($result),    'pre-1940 returns undef');
	cmp_ok($warned, '==', 0, 'pre-1940 emits no warning');

	diag("warned=$warned") if $ENV{TEST_VERBOSE};
};

# Purpose: an invalid date string must carp and return undef (documented).
subtest 'weather() -- invalid date string carps and returns undef' => sub {
	my $meteo  = Weather::Meteo->new();
	my $warned = 0;
	local $SIG{__WARN__} = sub { $warned++ };

	my $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $BAD_DATE });

	ok(!defined($result), 'bad date string: returns undef');
	ok($warned,           'bad date string: carp was emitted');

	diag("warned=$warned") if $ENV{TEST_VERBOSE};
};

# Purpose: the carp message must quote the bad value so the caller can diagnose it.
subtest 'weather() -- bad date warning quotes the invalid value' => sub {
	my $meteo = Weather::Meteo->new();
	warning_like { $meteo->weather({ latitude => $LAT, longitude => $LON, date => $BAD_DATE }) }
		qr/\Q$ERR_BAD_DATE\E/,
		"warning quotes '$BAD_DATE'";

	diag("expected: $ERR_BAD_DATE") if $ENV{TEST_VERBOSE};
};

# Purpose: POD says date can be an object that understands strftime.
subtest 'weather() -- strftime-capable date object is accepted' => sub {
	_mock_ok_ua();

	my $dt = bless {}, 'FakeDT';
	mock 'FakeDT::strftime' => sub { $DATE };

	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $dt });

	ok(defined($result),            'strftime date: result defined');
	ok(exists($result->{'hourly'}), 'strftime date: hourly key present');

	restore_all();
	diag('strftime date ok') if $ENV{TEST_VERBOSE};
};

# Purpose: if strftime returns a non-YYYY-MM-DD string the call must croak.
subtest 'weather() -- bad strftime result croaks with format message' => sub {
	my $dt = bless {}, 'BadFmtDT';
	mock 'BadFmtDT::strftime' => sub { '25/12/2022' };

	my $meteo = Weather::Meteo->new();
	throws_ok { $meteo->weather({ latitude => $LAT, longitude => $LON, date => $dt }) }
		qr/\Q$ERR_BAD_FMT\E/,
		'bad strftime: croak mentions expected format';

	restore_all();
	diag("err_fragment=$ERR_BAD_FMT") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# POD-documented behaviour: weather() -- required argument errors
# ===========================================================================

# Purpose: each missing required arg must croak with the usage string.
subtest 'weather() -- missing latitude croaks with usage text' => sub {
	my $meteo = Weather::Meteo->new();

	throws_ok { $meteo->weather({ longitude => $LON, date => $DATE }) }
		qr/\Q$ERR_USAGE\E/,
		'missing lat: croak contains usage string';

	diag("err_fragment=$ERR_USAGE") if $ENV{TEST_VERBOSE};
};

subtest 'weather() -- missing longitude croaks with usage text' => sub {
	my $meteo = Weather::Meteo->new();

	throws_ok { $meteo->weather({ latitude => $LAT, date => $DATE }) }
		qr/\Q$ERR_USAGE\E/,
		'missing lon: croak contains usage string';
};

subtest 'weather() -- missing date croaks with usage text' => sub {
	my $meteo = Weather::Meteo->new();

	throws_ok { $meteo->weather({ latitude => $LAT, longitude => $LON }) }
		qr/\Q$ERR_USAGE\E/,
		'missing date: croak contains usage string';
};

# Purpose: a non-numeric coordinate must croak with a format error.
subtest 'weather() -- non-numeric latitude croaks with coord message' => sub {
	my $meteo = Weather::Meteo->new();

	throws_ok { $meteo->weather({ latitude => 'abc', longitude => $LON, date => $DATE }) }
		qr/\Q$ERR_BAD_COORD\E/,
		'bad lat: croak names the format problem';

	diag("err_fragment=$ERR_BAD_COORD") if $ENV{TEST_VERBOSE};
};

subtest 'weather() -- non-numeric longitude croaks with coord message' => sub {
	my $meteo = Weather::Meteo->new();

	throws_ok { $meteo->weather({ latitude => $LAT, longitude => 'xyz', date => $DATE }) }
		qr/\Q$ERR_BAD_COORD\E/,
		'bad lon: croak names the format problem';
};

# ===========================================================================
# POD-documented behaviour: weather() -- response and error handling
# ===========================================================================

# Purpose: an HTTP error from the API must return undef.
subtest 'weather() -- HTTP error returns undef' => sub {
	mock 'LWP::UserAgent::get' => sub { HTTP::Response->new(500, 'Server Error') };

	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	ok(!defined($result), 'HTTP 500 returns undef');

	restore_all();
	diag('http error ok') if $ENV{TEST_VERBOSE};
};

# Purpose: unparseable JSON must return undef (POD: JSON parse error -> undef).
subtest 'weather() -- malformed JSON returns undef' => sub {
	mock 'LWP::UserAgent::get' => sub {
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{invalid_json});
		return $r;
	};

	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	ok(!defined($result), 'malformed JSON returns undef');

	restore_all();
	diag('bad json ok') if $ENV{TEST_VERBOSE};
};

# Purpose: malformed JSON must also emit a carp so the caller is notified.
subtest 'weather() -- malformed JSON carp identifies the failure' => sub {
	mock 'LWP::UserAgent::get' => sub {
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{invalid_json});
		return $r;
	};

	my $meteo = Weather::Meteo->new(cache => _fresh_cache());
	warning_like { $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE }) }
		qr/Failed to parse JSON response/,
		'JSON parse error warning says "Failed to parse JSON response"';

	restore_all();
	diag('json-parse warning ok') if $ENV{TEST_VERBOSE};
};

# Purpose: an API-level {"error":true} payload must return undef.
subtest 'weather() -- API error flag returns undef and carps the API reason' => sub {
	# The module now surfaces the API-provided reason via carp (resolved TODO).
	# warning_like captures the carp; $result is set via lexical capture.
	mock 'LWP::UserAgent::get' => sub {
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{api_error_json});
		return $r;
	};

	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $result;
	warning_like {
		$result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });
	} qr/API error/,
	'API error flag emits a carp mentioning "API error"';

	ok(!defined($result), 'API error flag returns undef');

	restore_all();
	diag('api error flag ok') if $ENV{TEST_VERBOSE};
};

# Purpose: a response lacking the hourly key must return undef.
subtest 'weather() -- response without hourly key returns undef' => sub {
	mock 'LWP::UserAgent::get' => sub {
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{no_hourly_json});
		return $r;
	};

	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	ok(!defined($result), 'missing hourly key returns undef');

	restore_all();
	diag('no hourly key ok') if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# POD-documented behaviour: weather() -- caching (documented feature)
# ===========================================================================

# Purpose: identical requests must be cached so the API is not called twice.
subtest 'weather() -- second identical call does not hit the network' => sub {
	my $cache    = _fresh_cache();
	my $ua_calls = 0;

	# Count each network call; after the first the cache should be used
	mock 'LWP::UserAgent::get' => sub {
		$ua_calls++;
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{hourly_json});
		return $r;
	};

	my $meteo = Weather::Meteo->new(cache => $cache);
	$meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });
	$meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	cmp_ok($ua_calls, '==', 1, 'UA called exactly once for two identical requests');

	restore_all();
	diag("ua_calls=$ua_calls") if $ENV{TEST_VERBOSE};
};

# Purpose: a cached result must be equal to the original response.
subtest 'weather() -- cached result matches original response' => sub {
	my $cache = _fresh_cache();
	_mock_ok_ua();

	my $meteo  = Weather::Meteo->new(cache => $cache);
	my $first  = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });
	my $second = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	# Both calls must return the same data
	is_deeply($second, $first, 'cached result is identical to first result');

	restore_all();
	diag('cached result eq original') if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# POD-documented behaviour: forecast()
# ===========================================================================

# Purpose: basic hashref call returns a defined hashref with hourly and daily.
subtest 'forecast() -- hashref args return a hashref with hourly and daily keys' => sub {
	mock 'LWP::UserAgent::get' => sub {
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{forecast_json});
		return $r;
	};

	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $result = $meteo->forecast({ latitude => $LAT, longitude => $LON });

	ok(defined($result),            'forecast() returns a defined value');
	ok(ref($result) eq 'HASH',      'result is a hashref');
	ok(exists($result->{'hourly'}), 'result contains hourly key');
	ok(exists($result->{'daily'}),  'result contains daily key');

	restore_all();
};

# Purpose: the request must target the forecast endpoint, not the archive.
subtest 'forecast() -- request targets api.open-meteo.com/v1/forecast' => sub {
	my $captured_url = '';
	mock 'LWP::UserAgent::get' => sub {
		my ($self_ua, $url) = @_;
		$captured_url = $url;
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{forecast_json});
		return $r;
	};

	my $meteo = Weather::Meteo->new(cache => _fresh_cache());
	$meteo->forecast({ latitude => $LAT, longitude => $LON });

	like($captured_url,   qr/api\.open-meteo\.com/, 'URL targets forecast host');
	like($captured_url,   qr|/v1/forecast|,         'URL uses /v1/forecast path');
	unlike($captured_url, qr/archive/,              'URL does not target archive host');

	restore_all();
	diag("url=$captured_url") if $ENV{TEST_VERBOSE};
};

# Purpose: the days parameter must flow through to forecast_days in the URL.
subtest 'forecast() -- days parameter flows into the URL as forecast_days' => sub {
	my $captured_url = '';
	mock 'LWP::UserAgent::get' => sub {
		my ($self_ua, $url) = @_;
		$captured_url = $url;
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{forecast_json});
		return $r;
	};

	my $meteo = Weather::Meteo->new(cache => _fresh_cache());
	$meteo->forecast({ latitude => $LAT, longitude => $LON, days => 3 });

	like($captured_url, qr/forecast_days=3/, 'URL contains forecast_days=3');

	restore_all();
	diag("url=$captured_url") if $ENV{TEST_VERBOSE};
};

# Purpose: missing latitude must croak with a usage message.
subtest 'forecast() -- missing latitude croaks with usage text' => sub {
	my $meteo = Weather::Meteo->new(cache => _fresh_cache());

	throws_ok { $meteo->forecast({ longitude => $LON }) }
		qr/Usage: forecast/,
		'missing latitude causes croak with usage text';
};

# Purpose: an out-of-range days value must carp and fall back to 7.
subtest 'forecast() -- out-of-range days carps and defaults to 7' => sub {
	my $captured_url = '';
	mock 'LWP::UserAgent::get' => sub {
		my ($self_ua, $url) = @_;
		$captured_url = $url;
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{forecast_json});
		return $r;
	};

	my $warned = 0;
	local $SIG{__WARN__} = sub { $warned++ };

	my $meteo = Weather::Meteo->new(cache => _fresh_cache());
	$meteo->forecast({ latitude => $LAT, longitude => $LON, days => 99 });

	ok($warned,                               'out-of-range days emits a carp warning');
	like($captured_url, qr/forecast_days=7/, 'URL defaults to forecast_days=7');

	restore_all();
};

# Purpose: a second identical call must use the cache, not the UA.
subtest 'forecast() -- second identical call uses cache, not UA' => sub {
	my $ua_calls = 0;
	mock 'LWP::UserAgent::get' => sub {
		$ua_calls++;
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{forecast_json});
		return $r;
	};

	my $meteo = Weather::Meteo->new(cache => _fresh_cache());
	$meteo->forecast({ latitude => $LAT, longitude => $LON });
	$meteo->forecast({ latitude => $LAT, longitude => $LON });

	cmp_ok($ua_calls, '==', 1, 'UA called exactly once for two identical forecast requests');

	restore_all();
	diag("ua_calls=$ua_calls") if $ENV{TEST_VERBOSE};
};

# Purpose: the daily section must contain sunrise and sunset strings.
subtest 'forecast() -- daily data contains sunrise and sunset' => sub {
	mock 'LWP::UserAgent::get' => sub {
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{forecast_json});
		return $r;
	};

	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $result = $meteo->forecast({ latitude => $LAT, longitude => $LON });

	my $daily = $result->{'daily'};
	ok(exists($daily->{'sunrise'}), 'daily contains sunrise');
	ok(exists($daily->{'sunset'}),  'daily contains sunset');
	like($daily->{'sunrise'}[0], qr/T\d{2}:\d{2}/, 'sunrise is an ISO-8601 datetime');
	like($daily->{'sunset'}[0],  qr/T\d{2}:\d{2}/, 'sunset is an ISO-8601 datetime');

	restore_all();
};

# ===========================================================================
# POD-documented behaviour: sunrise_sunset()
# ===========================================================================

# Purpose: a historical date returns a hashref with sunrise and sunset keys.
subtest 'sunrise_sunset() -- historical date returns { sunrise, sunset }' => sub {
	mock 'LWP::UserAgent::get' => sub {
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{sunrise_json});
		return $r;
	};

	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $result = $meteo->sunrise_sunset({ latitude => $LAT, longitude => $LON, date => $DATE });

	ok(defined($result),             'sunrise_sunset() returns a defined value');
	ok(ref($result) eq 'HASH',       'result is a hashref');
	ok(exists($result->{'sunrise'}), 'result has sunrise key');
	ok(exists($result->{'sunset'}),  'result has sunset key');

	restore_all();
	diag("sunrise=$result->{sunrise} sunset=$result->{sunset}") if $ENV{TEST_VERBOSE};
};

# Purpose: a historical date must use the archive endpoint, not the forecast one.
subtest 'sunrise_sunset() -- historical date targets archive endpoint' => sub {
	my $captured_url = '';
	mock 'LWP::UserAgent::get' => sub {
		my ($self_ua, $url) = @_;
		$captured_url = $url;
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{sunrise_json});
		return $r;
	};

	my $meteo = Weather::Meteo->new(cache => _fresh_cache());
	$meteo->sunrise_sunset({ latitude => $LAT, longitude => $LON, date => $DATE });

	like($captured_url, qr/archive-api\.open-meteo\.com/, 'historical date uses archive host');
	like($captured_url, qr/daily=sunrise%2Csunset|daily=sunrise,sunset/, 'URL requests only sunrise and sunset');

	restore_all();
	diag("url=$captured_url") if $ENV{TEST_VERBOSE};
};

# Purpose: missing latitude must croak with a usage message.
subtest 'sunrise_sunset() -- missing latitude croaks with usage text' => sub {
	my $meteo = Weather::Meteo->new(cache => _fresh_cache());

	throws_ok { $meteo->sunrise_sunset({ longitude => $LON }) }
		qr/Usage: sunrise_sunset/,
		'missing latitude causes croak with usage text';
};

# Purpose: an invalid date string must carp and return undef.
subtest 'sunrise_sunset() -- invalid date format carps and returns undef' => sub {
	my $warned = 0;
	local $SIG{__WARN__} = sub { $warned++ };

	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $result = $meteo->sunrise_sunset({ latitude => $LAT, longitude => $LON, date => 'not-a-date' });

	ok(!defined($result), 'invalid date returns undef');
	ok($warned,           'invalid date emits a carp warning');
};

# Purpose: a second identical call must use the cache, not the UA.
subtest 'sunrise_sunset() -- second identical call uses cache, not UA' => sub {
	my $ua_calls = 0;
	mock 'LWP::UserAgent::get' => sub {
		$ua_calls++;
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{sunrise_json});
		return $r;
	};

	my $meteo = Weather::Meteo->new(cache => _fresh_cache());
	$meteo->sunrise_sunset({ latitude => $LAT, longitude => $LON, date => $DATE });
	$meteo->sunrise_sunset({ latitude => $LAT, longitude => $LON, date => $DATE });

	cmp_ok($ua_calls, '==', 1, 'UA called exactly once for two identical sunrise_sunset requests');

	restore_all();
	diag("ua_calls=$ua_calls") if $ENV{TEST_VERBOSE};
};

done_testing();
