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

	# POD documents three public methods
	ok($meteo->can('new'),     'new() method available');
	ok($meteo->can('weather'), 'weather() method available');
	ok($meteo->can('ua'),      'ua() method available');

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
subtest 'weather() -- API error flag in response returns undef' => sub {
	mock 'LWP::UserAgent::get' => sub {
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{api_error_json});
		return $r;
	};

	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

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

done_testing();
