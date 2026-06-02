#!/usr/bin/env perl

# White-box function-level tests for TimeZone::TimeZoneDB.
# Each public method (new, get_time_zone, ua) is exercised in isolation
# with all external dependencies controlled via Test::Mockingbird.

use strict;
use warnings;

use lib 'lib';
use lib "$ENV{HOME}/src/njh/Test-Mockingbird/lib";
use lib "$ENV{HOME}/src/njh/Test-Returns/lib";

use HTTP::Response;
use Readonly;
use Scalar::Util qw(blessed);
use Test::Memory::Cycle;
use Test::Mockingbird;
use Test::Most;
use Test::Returns;
use Test::Warn;

use TimeZone::TimeZoneDB;

# ---------------------------------------------------------------------------
# Constants - no magic strings or numbers in the test body
# ---------------------------------------------------------------------------
Readonly::Scalar my $DUMMY_KEY    => 'test_api_key_xyz';
Readonly::Scalar my $DEFAULT_HOST => 'api.timezonedb.com';
Readonly::Scalar my $CUSTOM_HOST  => 'mock.timezonedb.test';
Readonly::Scalar my $API_PATH     => 'v2.1/get-time-zone';

# Coordinate fixtures
Readonly::Scalar my $RAMSGATE_LAT => 51.34;
Readonly::Scalar my $RAMSGATE_LNG => 1.42;
Readonly::Scalar my $RAMSGATE_TZ  => 'Europe/London';
Readonly::Scalar my $NYC_LAT      => 40.7128;
Readonly::Scalar my $NYC_LNG      => -74.006;
Readonly::Scalar my $NYC_TZ       => 'America/New_York';

# Canned JSON payloads that match the real timezonedb.com API format
Readonly::Scalar my $OK_JSON_NYC  => '{"status":"OK","zoneName":"America/New_York"}';
Readonly::Scalar my $OK_JSON_RAMS => '{"status":"OK","zoneName":"Europe/London"}';
Readonly::Scalar my $FAIL_JSON    => '{"status":"FAILED","message":"Invalid key"}';
Readonly::Scalar my $BAD_JSON     => 'this is {{ not }} valid json';

# HTTP status codes used in tests
Readonly::Scalar my $HTTP_OK  => 200;
Readonly::Scalar my $HTTP_ERR => 500;

# ---------------------------------------------------------------------------
# Minimal test-double packages defined once at the top to avoid symbol-table
# pollution inside individual subtest closures
# ---------------------------------------------------------------------------

# MockUA: a bare UA whose response can be set per-instance
{
	package MockUA;
	sub new      { bless { _resp => $_[1] }, $_[0] }
	sub get      { $_[0]->{_resp} }
	sub set_resp { $_[0]->{_resp} = $_[1] }
}

# MockCache: a simple hash-backed CHI-compatible cache
{
	package MockCache;
	sub new { bless { _store => {} }, $_[0] }
	sub get { $_[0]->{_store}{ $_[1] } }
	sub set { $_[0]->{_store}{ $_[1] } = $_[2] }
}

# MockLogger: records warn/error calls for later inspection
{
	package MockLogger;
	sub new   { bless { warns => [], errors => [] }, $_[0] }
	sub warn  { push @{$_[0]->{warns}},  $_[1] }
	sub error { push @{$_[0]->{errors}}, $_[1] }
}

# FakeLocation: minimal Geo::Location::Point-compatible object
{
	package FakeLocation;
	sub new       { bless { lat => $_[1], lng => $_[2] }, $_[0] }
	sub latitude  { $_[0]->{lat} }
	sub longitude { $_[0]->{lng} }
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Build a 200 OK HTTP::Response containing the supplied JSON string
sub _ok_resp {
	my $json = shift;
	my $r    = HTTP::Response->new($HTTP_OK, 'OK');
	$r->content($json);
	return $r;
}

# Build an error HTTP::Response (default: 500 Internal Server Error)
sub _err_resp {
	my ($code, $msg) = @_;
	return HTTP::Response->new($code // $HTTP_ERR, $msg // 'Internal Server Error');
}

# Construct a TimeZone::TimeZoneDB with sensible test defaults.
# Any key in %opts overrides the default; ua and cache default to mocks.
sub _make_tzdb {
	my (%opts) = @_;
	$opts{key}   //= $DUMMY_KEY;
	$opts{cache} //= MockCache->new();
	$opts{ua}    //= MockUA->new(_ok_resp($OK_JSON_NYC));
	return TimeZone::TimeZoneDB->new(%opts);
}

# ---------------------------------------------------------------------------
# Freeze Object::Configure so new() never touches the filesystem.
# This mock is in place for the entire file; restore_all() clears it at end.
# ---------------------------------------------------------------------------
mock 'Object::Configure::configure' => sub { $_[1] };

# ===========================================================================
# new()
# ===========================================================================

subtest 'new() croaks when key is missing' => sub {
	# The key argument is mandatory; its absence must produce a croak
	throws_ok { TimeZone::TimeZoneDB->new() }
		qr/key.*required/i, 'croaks with no key argument';
};

subtest 'new() returns a blessed object' => sub {
	# Basic construction should produce a TimeZone::TimeZoneDB instance
	my $tzdb = _make_tzdb();
	isa_ok($tzdb, 'TimeZone::TimeZoneDB', 'returns blessed object');
	ok(defined $tzdb, 'object is defined');
};

subtest 'new() stores the key' => sub {
	# The API key must be retained for use in HTTP requests
	my $tzdb = _make_tzdb(key => $DUMMY_KEY);
	is($tzdb->{key}, $DUMMY_KEY, 'key stored correctly');
};

subtest 'new() default host is api.timezonedb.com' => sub {
	# Without an explicit host, the well-known hostname must be used
	my $tzdb = _make_tzdb();
	is($tzdb->{host}, $DEFAULT_HOST, 'default host is correct');
};

subtest 'new() custom host overrides default' => sub {
	# Callers may point the module at a test or proxy server
	my $tzdb = _make_tzdb(host => $CUSTOM_HOST);
	is($tzdb->{host}, $CUSTOM_HOST, 'custom host stored');
};

subtest 'new() custom ua is stored verbatim' => sub {
	# A caller-supplied ua must not be wrapped or replaced
	my $ua   = MockUA->new(_ok_resp($OK_JSON_NYC));
	my $tzdb = _make_tzdb(ua => $ua);
	is($tzdb->{ua}, $ua, 'custom ua stored as-is');
};

subtest 'new() default ua is LWP::UserAgent' => sub {
	# When no ua is provided, a plain LWP::UserAgent must be created
	my $tzdb = TimeZone::TimeZoneDB->new(key => $DUMMY_KEY);
	isa_ok($tzdb->{ua}, 'LWP::UserAgent', 'default ua class');
	can_ok($tzdb->{ua}, 'get');
};

subtest 'new() min_interval defaults to 0' => sub {
	# Rate-limiting is off by default
	my $tzdb = _make_tzdb();
	is($tzdb->{min_interval}, 0, 'min_interval defaults to 0');
};

subtest 'new() explicit min_interval 0 is preserved' => sub {
	# Use // not || so that 0 is not treated as false and replaced
	my $tzdb = _make_tzdb(min_interval => 0);
	is($tzdb->{min_interval}, 0, 'explicit 0 is not overwritten');
};

subtest 'new() custom min_interval stored' => sub {
	# Non-zero rate-limit intervals must be stored accurately
	my $tzdb = _make_tzdb(min_interval => 2);
	is($tzdb->{min_interval}, 2, 'min_interval 2 stored');
};

subtest 'new() last_request initialised to 0' => sub {
	# Epoch zero means "no prior request"; rate-limiting uses this
	my $tzdb = _make_tzdb();
	is($tzdb->{last_request}, 0, 'last_request starts at 0');
};

subtest 'new() custom cache stored' => sub {
	# A caller-supplied cache must replace the default CHI::Memory cache
	my $cache = MockCache->new();
	my $tzdb  = _make_tzdb(cache => $cache);
	is($tzdb->{cache}, $cache, 'custom cache stored');
};

subtest 'new() logger passed through via extra key' => sub {
	# Extra keys (e.g. logger) must survive the %{$params} spread
	my $logger = MockLogger->new();
	my $tzdb   = _make_tzdb(logger => $logger);
	is($tzdb->{logger}, $logger, 'logger key passes through new()');
};

subtest 'new() clone returns a new object' => sub {
	# Calling new() on an instance produces a distinct blessed clone
	my $orig  = _make_tzdb();
	my $clone = $orig->new();
	isa_ok($clone, 'TimeZone::TimeZoneDB', 'clone is correct class');
	isnt($clone, $orig, 'clone is a different reference');
	is($clone->{key}, $DUMMY_KEY, 'clone inherits key');
};

subtest 'new() clone inherits ua from original' => sub {
	# A no-arg clone must keep the parent ua
	my $ua    = MockUA->new(_ok_resp($OK_JSON_NYC));
	my $orig  = _make_tzdb(ua => $ua);
	my $clone = $orig->new();
	is($clone->{ua}, $ua, 'clone inherits ua');
};

subtest 'new() clone with ua => undef keeps original ua' => sub {
	# Passing ua => undef in a clone call must be a no-op for ua
	my $ua    = MockUA->new(_ok_resp($OK_JSON_NYC));
	my $orig  = _make_tzdb(ua => $ua);
	my $clone = $orig->new(ua => undef);
	is($clone->{ua}, $ua, 'ua => undef clone keeps original ua');
};

subtest 'new() clone can override host' => sub {
	# A cloned object may be redirected to a different host
	my $orig  = _make_tzdb();
	my $clone = $orig->new(host => $CUSTOM_HOST);
	is($clone->{host},   $CUSTOM_HOST,  'clone has new host');
	is($orig->{host},    $DEFAULT_HOST, 'original host unchanged');
};

subtest 'new() does not clobber $_' => sub {
	# $_ in the calling scope must survive the constructor call
	local $_ = 'sentinel_new';
	_make_tzdb();
	is($_, 'sentinel_new', '$_ unchanged after new()');
};

subtest 'new() no memory cycles' => sub {
	# The constructed object must be cleanly collectable
	my $tzdb = _make_tzdb();
	memory_cycle_ok($tzdb, 'new() result has no memory cycles');
};

# ===========================================================================
# get_time_zone()
# ===========================================================================

subtest 'get_time_zone() croaks with no arguments' => sub {
	# Both latitude and longitude are required
	my $tzdb = _make_tzdb();
	throws_ok { $tzdb->get_time_zone() }
		qr/required parameter/i, 'croaks with no coords';
};

subtest 'get_time_zone() croaks with latitude only' => sub {
	# Longitude is required even when latitude is present
	my $tzdb = _make_tzdb();
	throws_ok { $tzdb->get_time_zone(latitude => $RAMSGATE_LAT) }
		qr/required parameter/i, 'croaks with latitude-only';
};

subtest 'get_time_zone() croaks with longitude only' => sub {
	# Latitude is required even when longitude is present
	my $tzdb = _make_tzdb();
	throws_ok { $tzdb->get_time_zone(longitude => $RAMSGATE_LNG) }
		qr/required parameter/i, 'croaks with longitude-only';
};

subtest 'get_time_zone() croaks with latitude out of range' => sub {
	# WGS-84 limits: latitude must be in [-90, 90]
	my $tzdb = _make_tzdb();
	throws_ok { $tzdb->get_time_zone(latitude =>  91, longitude => 0) }
		qr//i, 'croaks with lat > 90';
	throws_ok { $tzdb->get_time_zone(latitude => -91, longitude => 0) }
		qr//i, 'croaks with lat < -90';
};

subtest 'get_time_zone() croaks with longitude out of range' => sub {
	# WGS-84 limits: longitude must be in [-180, 180]
	my $tzdb = _make_tzdb();
	throws_ok { $tzdb->get_time_zone(latitude => 0, longitude =>  181) }
		qr//i, 'croaks with lng > 180';
	throws_ok { $tzdb->get_time_zone(latitude => 0, longitude => -181) }
		qr//i, 'croaks with lng < -180';
};

subtest 'get_time_zone() returns hashref with zoneName on success' => sub {
	# A 200 OK response with valid JSON must produce a non-empty hashref
	my $tzdb   = _make_tzdb(ua => MockUA->new(_ok_resp($OK_JSON_NYC)));
	my $result = $tzdb->get_time_zone(latitude => $NYC_LAT, longitude => $NYC_LNG);

	ok(defined $result,         'result is defined');
	is(ref($result), 'HASH',    'result is a hashref');
	is($result->{zoneName}, $NYC_TZ, 'zoneName is correct');

	# Verify the return value satisfies the declared output schema
	returns_ok($result, { type => 'hashref', min => 1 }, 'output schema satisfied');
	diag("zoneName: $result->{zoneName}") if $ENV{TEST_VERBOSE};
};

subtest 'get_time_zone() accepts hashref argument style' => sub {
	# { latitude => ..., longitude => ... } must work alongside named pairs
	my $tzdb   = _make_tzdb(ua => MockUA->new(_ok_resp($OK_JSON_NYC)));
	my $result = $tzdb->get_time_zone({ latitude => $NYC_LAT, longitude => $NYC_LNG });
	is($result->{zoneName}, $NYC_TZ, 'hashref calling convention works');
};

subtest 'get_time_zone() accepts a location object' => sub {
	# Any object implementing latitude() and longitude() must be accepted
	my $loc  = FakeLocation->new($RAMSGATE_LAT, $RAMSGATE_LNG);
	my $tzdb = _make_tzdb(ua => MockUA->new(_ok_resp($OK_JSON_RAMS)));

	my $result = $tzdb->get_time_zone($loc);
	is($result->{zoneName}, $RAMSGATE_TZ, 'location object accepted');
};

subtest 'get_time_zone() returns undef for non-OK API status' => sub {
	# A non-OK status from the API is a soft failure - undef, not croak
	my $tzdb   = _make_tzdb(ua => MockUA->new(_ok_resp($FAIL_JSON)));
	my $result = $tzdb->get_time_zone(latitude => $NYC_LAT, longitude => $NYC_LNG);
	ok(!defined $result, 'returns undef for non-OK status');
};

subtest 'get_time_zone() croaks on HTTP error with key redacted' => sub {
	# An HTTP 5xx must croak; the API key must NOT appear in the error
	my $tzdb = _make_tzdb(ua => MockUA->new(_err_resp($HTTP_ERR)));
	my $err;
	eval { $tzdb->get_time_zone(latitude => $NYC_LAT, longitude => $NYC_LNG) };
	$err = $@;

	ok($err, 'an error was thrown');
	like($err,   qr/API returned error/i, 'error mentions "API returned error"');
	like($err,   qr/REDACTED/,            'URL in error has key=REDACTED');
	unlike($err, qr/\Q$DUMMY_KEY\E/,      'actual API key not in error message');
	diag("error: $err") if $ENV{TEST_VERBOSE};
};

subtest 'get_time_zone() carps on invalid JSON and returns undef' => sub {
	# A 200 OK with a malformed body is a soft failure: carp + return undef
	my $tzdb   = _make_tzdb(ua => MockUA->new(_ok_resp($BAD_JSON)));
	my $result;
	warning_like {
		$result = $tzdb->get_time_zone(latitude => $NYC_LAT, longitude => $NYC_LNG);
	} qr/failed to parse json/i, 'carps on invalid JSON';
	ok(!defined $result, 'returns undef after JSON parse failure');
};

subtest 'get_time_zone() serves cache hit without HTTP call' => sub {
	# A pre-populated cache must be served without touching the UA
	my $cache_key = sprintf('tz:%.6f:%.6f', $NYC_LAT, $NYC_LNG);
	my $cache     = MockCache->new();
	my $cached    = { status => 'OK', zoneName => $NYC_TZ };
	$cache->set($cache_key, $cached);

	# UA that fails noisily if ever called
	my $call_count = 0;
	my $never_ua   = bless {}, 'NeverCalledUA';
	{
		no warnings 'once';
		*NeverCalledUA::get = sub { $call_count++; return _err_resp() };
	}

	my $tzdb   = _make_tzdb(cache => $cache, ua => $never_ua);
	my $result = $tzdb->get_time_zone(latitude => $NYC_LAT, longitude => $NYC_LNG);

	is($call_count,         0,      'UA not called on cache hit');
	is($result->{zoneName}, $NYC_TZ, 'cache hit value returned');
};

subtest 'get_time_zone() populates cache after API call' => sub {
	# A fresh (non-cached) response must be written to the cache
	my $cache     = MockCache->new();
	my $cache_key = sprintf('tz:%.6f:%.6f', $NYC_LAT, $NYC_LNG);
	my $tzdb      = _make_tzdb(ua => MockUA->new(_ok_resp($OK_JSON_NYC)), cache => $cache);

	$tzdb->get_time_zone(latitude => $NYC_LAT, longitude => $NYC_LNG);

	my $stored = $cache->get($cache_key);
	ok(defined $stored, 'result was written to cache');
	is($stored->{zoneName}, $NYC_TZ, 'cached value is correct');
};

subtest 'get_time_zone() updates last_request after API call' => sub {
	# The wall-clock time of the most recent request must be recorded
	my $tzdb   = _make_tzdb();
	my $before = time();

	is($tzdb->{last_request}, 0, 'last_request starts at 0');
	$tzdb->get_time_zone(latitude => $NYC_LAT, longitude => $NYC_LNG);

	cmp_ok($tzdb->{last_request}, '>=', $before, 'last_request >= call start');
	cmp_ok($tzdb->{last_request}, '<=', time(),  'last_request <= now');
};

subtest 'get_time_zone() calls Time::HiRes::sleep when within interval' => sub {
	# When elapsed < min_interval, a fractional sleep must be issued
	my $sleep_calls = 0;
	my $sleep_arg;
	{
		# Scoped mock: restored automatically when $g goes out of scope
		my $g = mock_scoped 'Time::HiRes::sleep' => sub {
			$sleep_calls++;
			$sleep_arg = $_[0];
		};

		# last_request = now, min_interval = large => elapsed ~0 < interval
		my $tzdb = _make_tzdb(min_interval => 999);
		$tzdb->{last_request} = time();
		$tzdb->get_time_zone(latitude => $NYC_LAT, longitude => $NYC_LNG);
	}

	is($sleep_calls, 1,       'Time::HiRes::sleep called once');
	cmp_ok($sleep_arg, '>', 0, 'sleep argument is positive');
	diag("sleep arg: $sleep_arg") if $ENV{TEST_VERBOSE};
};

subtest 'get_time_zone() skips sleep when min_interval is 0' => sub {
	# Disabled rate-limiting must not produce any sleep calls
	my $sleep_calls = 0;
	{
		my $g = mock_scoped 'Time::HiRes::sleep' => sub { $sleep_calls++ };
		my $tzdb = _make_tzdb(min_interval => 0);
		$tzdb->get_time_zone(latitude => $NYC_LAT, longitude => $NYC_LNG);
	}
	is($sleep_calls, 0, 'sleep not called when min_interval is 0');
};

subtest 'get_time_zone() constructs correct API URL' => sub {
	# The URL sent to the UA must include host, version, endpoint, and params
	my $captured_url;
	my $capturing_ua = bless {}, 'CapturingUA';
	{
		no warnings 'once';
		*CapturingUA::get = sub { $captured_url = $_[1]; return _ok_resp($OK_JSON_NYC) };
	}

	my $tzdb = _make_tzdb(ua => $capturing_ua);
	$tzdb->get_time_zone(latitude => $NYC_LAT, longitude => $NYC_LNG);

	like($captured_url, qr{\Q$DEFAULT_HOST\E}, 'URL contains correct host');
	like($captured_url, qr{v2\.1/get-time-zone}, 'URL has API version and endpoint');
	like($captured_url, qr{by=position},          'URL has by=position');
	like($captured_url, qr{format=json},          'URL has format=json');
	like($captured_url, qr{key=\Q$DUMMY_KEY\E},   'URL contains API key');
	diag("URL: $captured_url") if $ENV{TEST_VERBOSE};
};

subtest 'get_time_zone() logger warned for non-OK status, key redacted' => sub {
	# When a logger is present, warn() must be called and key must be hidden
	my $logger = MockLogger->new();
	my $tzdb   = _make_tzdb(ua => MockUA->new(_ok_resp($FAIL_JSON)), logger => $logger);

	$tzdb->get_time_zone(latitude => $NYC_LAT, longitude => $NYC_LNG);

	is(scalar @{$logger->{warns}}, 1, 'logger->warn called once');
	unlike($logger->{warns}[0], qr/\Q$DUMMY_KEY\E/, 'API key redacted in logger warn');
	diag("logger warn: $logger->{warns}[0]") if $ENV{TEST_VERBOSE};
};

subtest 'get_time_zone() does not clobber $_' => sub {
	# External $_ must survive the method call unchanged
	my $tzdb = _make_tzdb();
	local $_ = 'sentinel_gtz';
	$tzdb->get_time_zone(latitude => $NYC_LAT, longitude => $NYC_LNG);
	is($_, 'sentinel_gtz', '$_ not clobbered by get_time_zone()');
};

subtest 'get_time_zone() no memory cycles after call' => sub {
	# After a successful call the object must still be cleanly collectable
	my $tzdb = _make_tzdb();
	$tzdb->get_time_zone(latitude => $NYC_LAT, longitude => $NYC_LNG);
	memory_cycle_ok($tzdb, 'get_time_zone() leaves no memory cycles');
};

# ===========================================================================
# ua()
# ===========================================================================

subtest 'ua() getter returns stored ua' => sub {
	# With no argument, the currently stored ua must be returned unchanged
	my $ua   = MockUA->new(_ok_resp($OK_JSON_NYC));
	my $tzdb = _make_tzdb(ua => $ua);

	my $ret = $tzdb->ua();
	is($ret, $ua, 'getter returns stored ua');
	returns_ok($ret, { type => 'object' }, 'ua() getter output schema');
};

subtest 'ua() setter stores new ua' => sub {
	# After setting, the new ua must be retrievable via the getter
	my $old_ua = MockUA->new(_ok_resp($OK_JSON_NYC));
	my $new_ua = MockUA->new(_ok_resp($OK_JSON_RAMS));
	my $tzdb   = _make_tzdb(ua => $old_ua);

	$tzdb->ua($new_ua);
	is($tzdb->ua(), $new_ua, 'setter stores the new ua');
};

subtest 'ua() setter returns the new ua, not $self' => sub {
	# Return value must be the ua itself, matching LWP::UserAgent convention
	my $old_ua = MockUA->new(_ok_resp($OK_JSON_NYC));
	my $new_ua = MockUA->new(_ok_resp($OK_JSON_RAMS));
	my $tzdb   = _make_tzdb(ua => $old_ua);

	my $ret = $tzdb->ua($new_ua);
	is($ret,    $new_ua, 'setter returns the new ua');
	isnt($ret,  $tzdb,   'setter does not return $self');
};

subtest 'ua() named-parameter form ua => $obj works' => sub {
	# ua(ua => $obj) must behave identically to ua($obj)
	my $old_ua = MockUA->new(_ok_resp($OK_JSON_NYC));
	my $new_ua = MockUA->new(_ok_resp($OK_JSON_RAMS));
	my $tzdb   = _make_tzdb(ua => $old_ua);

	my $ret = $tzdb->ua(ua => $new_ua);
	is($ret, $new_ua, 'named convention ua => $obj works');
};

subtest 'ua() croaks when given undef' => sub {
	# undef is explicitly forbidden to prevent silent corruption of $self->{ua}
	my $tzdb = _make_tzdb();
	throws_ok { $tzdb->ua(undef) }
		qr/requires a defined value/i, 'croaks on undef';
};

subtest 'ua() croaks when given object without get()' => sub {
	# The ua must respond to get(); any non-conforming object must be rejected
	my $tzdb    = _make_tzdb();
	my $bad_obj = bless {}, 'NoGetMethod';
	throws_ok { $tzdb->ua($bad_obj) }
		qr//i, 'croaks for ua without get()';
};

subtest 'ua() croaks when given a plain scalar' => sub {
	# A bare string is not a valid user-agent
	my $tzdb = _make_tzdb();
	throws_ok { $tzdb->ua('http://example.com') }
		qr//i, 'croaks for string argument';
};

subtest 'ua() logs error via logger when given undef' => sub {
	# With a logger installed, the error channel must receive a message
	my $logger = MockLogger->new();
	my $tzdb   = _make_tzdb(logger => $logger);

	eval { $tzdb->ua(undef) };

	is(scalar @{$logger->{errors}}, 1, 'logger->error called once');
	diag("logger error: $logger->{errors}[0]") if $ENV{TEST_VERBOSE};
};

subtest 'ua() does not clobber $_' => sub {
	# The setter must not disturb $_ in the calling scope
	my $ua   = MockUA->new(_ok_resp($OK_JSON_NYC));
	my $tzdb = _make_tzdb();
	local $_ = 'sentinel_ua';
	$tzdb->ua($ua);
	is($_, 'sentinel_ua', '$_ not clobbered by ua()');
};

subtest 'ua() no memory cycles after setter call' => sub {
	# Replacing the ua must not introduce circular references
	my $ua   = MockUA->new(_ok_resp($OK_JSON_NYC));
	my $tzdb = _make_tzdb();
	$tzdb->ua($ua);
	memory_cycle_ok($tzdb, 'ua() setter leaves no memory cycles');
};

# ---------------------------------------------------------------------------
# Tear down all mocks installed during this file (including the global
# Object::Configure freeze at the top)
# ---------------------------------------------------------------------------
restore_all();

done_testing();
