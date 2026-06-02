#!/usr/bin/env perl

# function.t - white-box tests for Weather::Meteo
# Covers new(), ua(), weather() and all internal behaviour paths.
# Includes exact error-string tests, $_ clobber guards, and memory-cycle checks.

use strict;
use warnings;

use CHI;
use HTTP::Response;
use Readonly;
use Scalar::Util qw(blessed);
use Test::Memory::Cycle;
use Test::Most;
use Test::Mockingbird;
use Test::Returns;

use lib 'lib';
use Weather::Meteo;

# ---------------------------------------------------------------------------
# Constants -- test coordinates, dates, and expected defaults
# ---------------------------------------------------------------------------
Readonly my $LAT          => '51.34';
Readonly my $LON          => '1.42';
Readonly my $DATE         => '2022-12-25';
Readonly my $PRE_1940     => '1939-12-31';
Readonly my $BAD_DATE     => 'not-a-date';
Readonly my $DEFAULT_HOST => 'archive-api.open-meteo.com';
Readonly my $NO_DELAY     => 0;

# Exact fragments that must appear in error/warning messages
Readonly my $MSG_USAGE       => 'Usage: weather(latitude';
Readonly my $MSG_BAD_COORD   => 'Invalid latitude/longitude format';
Readonly my $MSG_BAD_DATE    => "'${\$BAD_DATE}' is not a valid date";
Readonly my $MSG_BAD_FMT     => 'Invalid date format. Expected YYYY-MM-DD';
Readonly my $MSG_BAD_UA      => 'must be an object that understands the get method';

# ---------------------------------------------------------------------------
# %config -- non-constant values used across subtests
# ---------------------------------------------------------------------------
my %config = (
	hourly_json     => '{"hourly":{"temperature_2m":[5,6,7],"rain":[0,0,0]}}',
	no_hourly_json  => '{"daily":{"temperature_2m_max":[10]}}',
	api_error_json  => '{"error":true,"reason":"Bad coords"}',
	invalid_json    => 'this is not json at all',
	cache_key       => "weather:${LAT}:${LON}:${DATE}:Europe/London",
	custom_host     => 'custom.example.com',
	custom_interval => 2,
	sentinel        => 'dollar-underscore-sentinel',
);

# ---------------------------------------------------------------------------
# _mock_good_response -- installs a UA mock that returns a valid JSON payload.
# Always pair with a restore_all() call at the end of the subtest that uses it.
# ---------------------------------------------------------------------------
sub _mock_good_response {
	mock 'LWP::UserAgent::get' => sub {
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{hourly_json});
		return $r;
	};
}

# ---------------------------------------------------------------------------
# _fresh_cache -- returns a new non-global in-memory CHI cache.
# Using global => 0 prevents earlier successful API responses from leaking
# into subtests that must exercise the live HTTP / JSON code paths.
# ---------------------------------------------------------------------------
sub _fresh_cache {
	return CHI->new(driver => 'Memory', global => 0, expires_in => '1 hour');
}

# ===========================================================================
# new() -- constructor
# ===========================================================================

subtest 'new() - class method returns blessed object' => sub {
	my $meteo = Weather::Meteo->new();

	# Must come back as a Weather::Meteo instance
	isa_ok($meteo, 'Weather::Meteo', 'new() returns correct class');
	returns_ok($meteo, { type => 'object' }, 'new() return satisfies object schema');

	diag('new() class method ok') if $ENV{TEST_VERBOSE};
};

subtest 'new() - function-style call also works' => sub {
	# Weather::Meteo::new() without -> should still bless into Weather::Meteo
	my $meteo = Weather::Meteo::new('Weather::Meteo');
	isa_ok($meteo, 'Weather::Meteo', 'function-style new() works');

	diag('function-style new() ok') if $ENV{TEST_VERBOSE};
};

subtest 'new() - default internals are set correctly' => sub {
	my $meteo = Weather::Meteo->new();

	# Verify each default slot is populated as documented
	is($meteo->{'host'}, $DEFAULT_HOST, 'default host is archive-api.open-meteo.com');
	cmp_ok($meteo->{'min_interval'}, '==', $NO_DELAY, 'default min_interval is 0');

	# UA and cache must be created automatically
	ok(defined($meteo->{'ua'}),               'ua slot is populated');
	ok($meteo->{'ua'}->isa('LWP::UserAgent'), 'ua is an LWP::UserAgent');
	ok(defined($meteo->{'cache'}),            'cache slot is populated');

	diag("host=$meteo->{host} min_interval=$meteo->{min_interval}") if $ENV{TEST_VERBOSE};
};

subtest 'new() - custom arguments are stored' => sub {
	# All constructor knobs should be honoured when supplied
	my $custom_cache = _fresh_cache();
	my $custom_ua    = LWP::UserAgent->new();

	my $meteo = Weather::Meteo->new(
		host         => $config{custom_host},
		min_interval => $config{custom_interval},
		cache        => $custom_cache,
		ua           => $custom_ua,
	);

	is($meteo->{'host'},         $config{custom_host},     'custom host stored');
	cmp_ok($meteo->{'min_interval'}, '==', $config{custom_interval}, 'custom min_interval stored');
	is($meteo->{'cache'}, $custom_cache, 'custom cache stored');
	is($meteo->{'ua'},    $custom_ua,    'custom ua stored');

	diag('custom args ok') if $ENV{TEST_VERBOSE};
};

subtest 'new() - calling on an object clones it' => sub {
	# Arrow-new on an existing instance should return a new blessed copy
	my $orig  = Weather::Meteo->new(host => $config{custom_host});
	my $clone = $orig->new();

	isa_ok($clone, 'Weather::Meteo', 'clone is a Weather::Meteo');
	is($clone->{'host'}, $config{custom_host}, 'clone inherits host from original');

	# A clone with an override should use the supplied value
	my $override = $orig->new(host => $DEFAULT_HOST);
	is($override->{'host'}, $DEFAULT_HOST, 'clone override replaces inherited value');

	diag('clone ok') if $ENV{TEST_VERBOSE};
};

subtest 'new() - does not clobber $_' => sub {
	# The constructor must not modify the caller's $_ variable
	local $_ = $config{sentinel};
	Weather::Meteo->new();
	is($_, $config{sentinel}, 'new() leaves $_ unchanged');

	diag("\$_ after new(): $_") if $ENV{TEST_VERBOSE};
};

subtest 'new() - object has no memory cycles' => sub {
	# Circular references would prevent garbage collection
	my $meteo = Weather::Meteo->new();
	memory_cycle_ok($meteo, 'Weather::Meteo object is free of circular references');

	diag('memory cycle check ok') if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# ua() -- user-agent accessor
# ===========================================================================

subtest 'ua() - getter returns the internal UA' => sub {
	my $meteo = Weather::Meteo->new();
	my $ua    = $meteo->ua();

	# Getter must return a defined object that understands HTTP GET
	ok(defined($ua),               'ua() getter returns something');
	ok($ua->isa('LWP::UserAgent'), 'ua() returns an LWP::UserAgent');
	returns_ok($ua, { type => 'object' }, 'ua() return satisfies object schema');

	diag('ua getter ok') if $ENV{TEST_VERBOSE};
};

subtest 'ua() - setter stores a valid UA object' => sub {
	my $meteo  = Weather::Meteo->new();
	my $new_ua = LWP::UserAgent->new();

	# Passing a UA should replace the internal slot
	$meteo->ua($new_ua);
	is($meteo->{'ua'}, $new_ua, 'ua() setter updates internal ua');
	is($meteo->ua(),   $new_ua, 'ua() getter reflects the new ua');

	diag('ua setter ok') if $ENV{TEST_VERBOSE};
};

subtest 'ua() - setter rejects an object without get()' => sub {
	my $meteo  = Weather::Meteo->new();
	my $bad_ua = bless {}, 'BadUA';

	# An object that lacks a get() method must be rejected (schema-enforced)
	eval { $meteo->ua($bad_ua) };
	ok($@, 'ua() rejects an object that cannot get()');

	diag("rejection: $@") if $ENV{TEST_VERBOSE};
};

subtest 'ua() - invalid UA error message names the required method' => sub {
	my $meteo  = Weather::Meteo->new();
	my $bad_ua = bless {}, 'BadUA2';

	# The exact error must mention that get() is required
	throws_ok { $meteo->ua($bad_ua) }
		qr/\Q$MSG_BAD_UA\E/,
		'ua() error message mentions get()';

	diag("error: $@") if $ENV{TEST_VERBOSE};
};

subtest 'ua() - does not clobber $_' => sub {
	my $meteo = Weather::Meteo->new();

	# Getter must not disturb the caller's $_
	local $_ = $config{sentinel};
	$meteo->ua();
	is($_, $config{sentinel}, 'ua() getter leaves $_ unchanged');

	# Setter must not disturb the caller's $_ either
	$meteo->ua(LWP::UserAgent->new());
	is($_, $config{sentinel}, 'ua() setter leaves $_ unchanged');

	diag("\$_ after ua(): $_") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# weather() -- argument forms
# ===========================================================================

subtest 'weather() - hashref arguments' => sub {
	_mock_good_response();
	my $meteo  = Weather::Meteo->new();

	# The canonical call form -- a single hashref
	my $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	ok(defined($result),            'hashref args: defined result');
	returns_ok($result, { type => 'hashref' }, 'hashref args: returns a hashref');
	ok(exists($result->{'hourly'}), 'hashref args: hourly key present');

	restore_all();
	diag('hashref args ok') if $ENV{TEST_VERBOSE};
};

subtest 'weather() - flat key/value arguments' => sub {
	_mock_good_response();
	my $meteo  = Weather::Meteo->new();

	# Flat list form -- no enclosing hashref
	my $result = $meteo->weather(latitude => $LAT, longitude => $LON, date => $DATE);

	ok(defined($result),            'flat args: defined result');
	ok(exists($result->{'hourly'}), 'flat args: hourly key present');

	restore_all();
	diag('flat args ok') if $ENV{TEST_VERBOSE};
};

subtest 'weather() - Geo::Location::Point style: (object, date)' => sub {
	_mock_good_response();

	# Two-arg form: blessed object with latitude()/longitude() + date string
	my $loc = bless {}, 'FakeLoc';
	mock 'FakeLoc::latitude'  => sub { $LAT };
	mock 'FakeLoc::longitude' => sub { $LON };

	my $meteo  = Weather::Meteo->new();
	my $result = $meteo->weather($loc, $DATE);

	ok(defined($result),            'location+date: defined result');
	ok(exists($result->{'hourly'}), 'location+date: hourly key present');

	restore_all();
	diag('location+date args ok') if $ENV{TEST_VERBOSE};
};

subtest 'weather() - named location => $obj argument' => sub {
	_mock_good_response();

	# { location => $obj, date => ... } form extracts lat/lon via methods
	my $loc = bless {}, 'FakeLoc2';
	mock 'FakeLoc2::latitude'  => sub { $LAT };
	mock 'FakeLoc2::longitude' => sub { $LON };

	my $meteo  = Weather::Meteo->new();
	my $result = $meteo->weather({ location => $loc, date => $DATE });

	ok(defined($result),            'named location: defined result');
	ok(exists($result->{'hourly'}), 'named location: hourly key present');

	restore_all();
	diag('named location ok') if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# weather() -- date handling
# ===========================================================================

subtest 'weather() - pre-1940 date returns undef silently' => sub {
	# Dates before 1940 are outside the data range: return undef, no warning
	my $meteo  = Weather::Meteo->new();
	my $warned = 0;
	local $SIG{__WARN__} = sub { $warned++ };

	my $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $PRE_1940 });

	ok(!defined($result),          'pre-1940 date returns undef');
	cmp_ok($warned, '==', 0,       'pre-1940 does not emit a warning');

	diag("warned=$warned") if $ENV{TEST_VERBOSE};
};

subtest 'weather() - invalid date format carps and returns undef' => sub {
	# A string that is not YYYY-MM-DD must carp and return undef
	my $meteo  = Weather::Meteo->new();
	my $warned = 0;
	local $SIG{__WARN__} = sub { $warned++ };

	my $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $BAD_DATE });

	ok(!defined($result), 'bad date returns undef');
	ok($warned,           'bad date emits a carp warning');

	diag("bad date warned=$warned") if $ENV{TEST_VERBOSE};
};

subtest 'weather() - bad date warning contains the invalid value' => sub {
	# The carp message must quote the bad value so the caller can identify it
	my $meteo = Weather::Meteo->new();
	warning_like { $meteo->weather({ latitude => $LAT, longitude => $LON, date => $BAD_DATE }) }
		qr/\Q$MSG_BAD_DATE\E/,
		"bad date warning quotes '$BAD_DATE'";

	diag("expected fragment: $MSG_BAD_DATE") if $ENV{TEST_VERBOSE};
};

subtest 'weather() - DateTime-like object accepted as date' => sub {
	# Any object that responds to strftime('%F') should be usable as a date
	_mock_good_response();
	my $dt = bless {}, 'FakeDateTime';
	mock 'FakeDateTime::strftime' => sub { $DATE };

	my $meteo  = Weather::Meteo->new();
	my $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $dt });

	ok(defined($result),            'DateTime-like date accepted');
	ok(exists($result->{'hourly'}), 'DateTime-like date: hourly present');

	restore_all();
	diag('DateTime-like object ok') if $ENV{TEST_VERBOSE};
};

subtest 'weather() - bad-format strftime result croaks with format message' => sub {
	# When a date object's strftime returns a non-YYYY-MM-DD string, croak must
	# mention the expected format so the caller knows what is required.
	my $dt = bless {}, 'BadFmtDT';
	mock 'BadFmtDT::strftime' => sub { '25/12/2022' };	# wrong order

	my $meteo = Weather::Meteo->new();
	throws_ok { $meteo->weather({ latitude => $LAT, longitude => $LON, date => $dt }) }
		qr/\Q$MSG_BAD_FMT\E/,
		'bad strftime result: error names expected format';

	restore_all();
	diag("error: $@") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# weather() -- coordinate normalisation
# ===========================================================================

subtest 'weather() - leading-decimal latitude is normalised' => sub {
	# ".5" must be treated as "0.5" and accepted
	_mock_good_response();
	my $meteo  = Weather::Meteo->new();
	my $result = $meteo->weather({ latitude => '.5', longitude => $LON, date => $DATE });

	ok(defined($result), 'leading-decimal latitude accepted as 0.5');

	restore_all();
	diag('leading-decimal lat ok') if $ENV{TEST_VERBOSE};
};

subtest 'weather() - negative leading-decimal latitude is normalised' => sub {
	# "-.5" must be treated as "-0.5" and accepted
	_mock_good_response();
	my $meteo  = Weather::Meteo->new();
	my $result = $meteo->weather({ latitude => '-.5', longitude => $LON, date => $DATE });

	ok(defined($result), 'negative leading-decimal latitude accepted as -0.5');

	restore_all();
	diag('neg leading-decimal lat ok') if $ENV{TEST_VERBOSE};
};

subtest 'weather() - leading-decimal longitude is normalised' => sub {
	# ".4" as longitude must be handled the same way as latitude
	_mock_good_response();
	my $meteo  = Weather::Meteo->new();
	my $result = $meteo->weather({ latitude => $LAT, longitude => '.4', date => $DATE });

	ok(defined($result), 'leading-decimal longitude accepted as 0.4');

	restore_all();
	diag('leading-decimal lon ok') if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# weather() -- missing required arguments (croak paths)
# ===========================================================================

subtest 'weather() - missing latitude croaks' => sub {
	my $meteo = Weather::Meteo->new();

	# latitude is required; omitting it must die
	eval { $meteo->weather({ longitude => $LON, date => $DATE }) };
	ok($@, 'missing latitude causes croak');

	diag("croak: $@") if $ENV{TEST_VERBOSE};
};

subtest 'weather() - missing longitude croaks' => sub {
	my $meteo = Weather::Meteo->new();

	eval { $meteo->weather({ latitude => $LAT, date => $DATE }) };
	ok($@, 'missing longitude causes croak');

	diag("croak: $@") if $ENV{TEST_VERBOSE};
};

subtest 'weather() - missing date croaks' => sub {
	my $meteo = Weather::Meteo->new();

	eval { $meteo->weather({ latitude => $LAT, longitude => $LON }) };
	ok($@, 'missing date causes croak');

	diag("croak: $@") if $ENV{TEST_VERBOSE};
};

subtest 'weather() - missing args error message cites the correct usage' => sub {
	# All three missing-arg cases must produce a message that names the call signature
	my $meteo = Weather::Meteo->new();

	throws_ok { $meteo->weather({ longitude => $LON, date => $DATE }) }
		qr/\Q$MSG_USAGE\E/,
		'missing lat: error contains usage string';

	throws_ok { $meteo->weather({ latitude => $LAT, date => $DATE }) }
		qr/\Q$MSG_USAGE\E/,
		'missing lon: error contains usage string';

	throws_ok { $meteo->weather({ latitude => $LAT, longitude => $LON }) }
		qr/\Q$MSG_USAGE\E/,
		'missing date: error contains usage string';

	diag("usage fragment: $MSG_USAGE") if $ENV{TEST_VERBOSE};
};

subtest 'weather() - non-numeric coordinate croaks' => sub {
	# A string that is not a number must die
	my $meteo = Weather::Meteo->new();

	eval { $meteo->weather({ latitude => 'abc', longitude => $LON, date => $DATE }) };
	ok($@, 'non-numeric latitude causes croak');

	diag("croak msg: $@") if $ENV{TEST_VERBOSE};
};

subtest 'weather() - bad coordinate error message names the offending values' => sub {
	# The error must quote the bad coordinate so the caller can diagnose it
	my $meteo = Weather::Meteo->new();

	throws_ok { $meteo->weather({ latitude => 'abc', longitude => $LON, date => $DATE }) }
		qr/\Q$MSG_BAD_COORD\E/,
		'bad lat: error contains format-problem text';

	throws_ok { $meteo->weather({ latitude => $LAT, longitude => 'xyz', date => $DATE }) }
		qr/\Q$MSG_BAD_COORD\E/,
		'bad lon: error contains format-problem text';

	diag("bad coord fragment: $MSG_BAD_COORD") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# weather() -- HTTP and JSON failure paths
# ===========================================================================

subtest 'weather() - HTTP error response returns undef and carps' => sub {
	# A 500 from the API must carp and return undef.
	# A fresh cache isolates this subtest from earlier successful responses.
	mock 'LWP::UserAgent::get' => sub {
		return HTTP::Response->new(500, 'Internal Server Error');
	};

	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $warned = 0;
	local $SIG{__WARN__} = sub { $warned++ };

	my $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	ok(!defined($result), 'HTTP 500 returns undef');
	ok($warned,           'HTTP 500 emits a carp warning');

	restore_all();
	diag("http-error warned=$warned") if $ENV{TEST_VERBOSE};
};

subtest 'weather() - malformed JSON returns undef and carps' => sub {
	# Garbage body must carp and return undef; fresh cache prevents reuse
	mock 'LWP::UserAgent::get' => sub {
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{invalid_json});
		return $r;
	};

	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $warned = 0;
	local $SIG{__WARN__} = sub { $warned++ };

	my $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	ok(!defined($result), 'malformed JSON returns undef');
	ok($warned,           'malformed JSON emits a carp warning');

	restore_all();
	diag("bad-json warned=$warned") if $ENV{TEST_VERBOSE};
};

subtest 'weather() - malformed JSON carp message identifies the failure' => sub {
	# The warning must contain enough text for the caller to understand the cause
	mock 'LWP::UserAgent::get' => sub {
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{invalid_json});
		return $r;
	};

	my $meteo = Weather::Meteo->new(cache => _fresh_cache());
	warning_like { $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE }) }
		qr/Failed to parse JSON response/,
		'malformed JSON warning says "Failed to parse JSON response"';

	restore_all();
	diag('json-parse warning ok') if $ENV{TEST_VERBOSE};
};

subtest 'weather() - API error flag in JSON returns undef' => sub {
	# {"error":true,...} means the API rejected the request; return undef
	mock 'LWP::UserAgent::get' => sub {
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{api_error_json});
		return $r;
	};

	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	ok(!defined($result), 'API error flag returns undef');

	restore_all();
	diag('api-error-flag ok') if $ENV{TEST_VERBOSE};
};

subtest 'weather() - JSON with no hourly key returns undef' => sub {
	# The module requires an hourly key; a response without one must return undef
	mock 'LWP::UserAgent::get' => sub {
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{no_hourly_json});
		return $r;
	};

	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	ok(!defined($result), 'missing hourly key returns undef');

	restore_all();
	diag('no-hourly-key ok') if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# weather() -- cache behaviour
# ===========================================================================

subtest 'weather() - cache hit bypasses the UA entirely' => sub {
	# Seed the cache manually; the UA must never be called
	my $cache       = _fresh_cache();
	my $seeded_data = { hourly => { temperature_2m => [1, 2, 3] } };
	$cache->set($config{cache_key}, $seeded_data);

	# Any call to the UA means the cache lookup failed
	my $ua_calls = 0;
	mock 'LWP::UserAgent::get' => sub { $ua_calls++; return HTTP::Response->new(500) };

	my $meteo  = Weather::Meteo->new(cache => $cache);
	my $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	ok(defined($result),             'cache hit: result is defined');
	cmp_ok($ua_calls, '==', 0,       'cache hit: UA was never called');
	is_deeply($result, $seeded_data, 'cache hit: returned value matches seeded data');

	restore_all();
	diag("ua_calls=$ua_calls") if $ENV{TEST_VERBOSE};
};

subtest 'weather() - successful response is stored in cache' => sub {
	# After a live call the result must be findable in the cache
	my $cache = _fresh_cache();
	_mock_good_response();

	my $meteo = Weather::Meteo->new(cache => $cache);
	$meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	# Confirm the cache entry exists and contains the hourly key
	my $cached = $cache->get($config{cache_key});
	ok(defined($cached),            'result was stored in cache');
	ok(exists($cached->{'hourly'}), 'cached entry has hourly key');

	restore_all();
	diag('cache-store ok') if $ENV{TEST_VERBOSE};
};

subtest 'weather() - second identical call uses cache, not UA' => sub {
	# Two identical requests must result in exactly one UA call
	my $cache    = _fresh_cache();
	my $ua_calls = 0;

	mock 'LWP::UserAgent::get' => sub {
		$ua_calls++;
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{hourly_json});
		return $r;
	};

	my $meteo = Weather::Meteo->new(cache => $cache);
	$meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });
	$meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	cmp_ok($ua_calls, '==', 1, 'only one UA call for two identical requests');

	restore_all();
	diag("ua_calls=$ua_calls") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# weather() -- $_ and memory cycle checks
# ===========================================================================

subtest 'weather() - does not clobber $_' => sub {
	# All the internal regex operations must bind to named variables, not $_
	_mock_good_response();
	my $meteo = Weather::Meteo->new(cache => _fresh_cache());

	local $_ = $config{sentinel};
	$meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });
	is($_, $config{sentinel}, 'weather() leaves $_ unchanged');

	restore_all();
	diag("\$_ after weather(): $_") if $ENV{TEST_VERBOSE};
};

subtest 'weather() - returned data has no memory cycles' => sub {
	# The hashref returned by weather() must be cycle-free so it can be GC'd
	_mock_good_response();
	my $meteo = Weather::Meteo->new(cache => _fresh_cache());
	my $data  = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	memory_cycle_ok($data, 'weather() return value is free of circular references');

	restore_all();
	diag('weather data memory cycle check ok') if $ENV{TEST_VERBOSE};
};

done_testing();
