#!/usr/bin/env perl

# Black-box unit tests for TimeZone::TimeZoneDB.
# Each test validates observable behaviour as promised by the POD.
# Internals are never inspected directly; all external I/O is mocked.

use strict;
use warnings;

use lib 'lib';
use lib "$ENV{HOME}/src/njh/Test-Mockingbird/lib";
use lib "$ENV{HOME}/src/njh/Test-Returns/lib";

use HTTP::Response;
use Readonly;
use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use Test::Warn;

use TimeZone::TimeZoneDB;

# ---------------------------------------------------------------------------
# Test configuration hash - single source of truth for all fixture values
# ---------------------------------------------------------------------------
my %config = (
	key_valid    => 'unit_test_api_key',
	host_default => 'api.timezonedb.com',
	host_custom  => 'custom.timezonedb.test',

	lat_nyc      => 40.7128,
	lng_nyc      => -74.006,
	tz_nyc       => 'America/New_York',

	lat_ramsgate => 51.34,
	lng_ramsgate => 1.42,
	tz_ramsgate  => 'Europe/London',

	lat_boundary_max =>  90,
	lat_boundary_min => -90,
	lng_boundary_max =>  180,
	lng_boundary_min => -180,

	http_ok    => 200,
	http_error => 500,

	rate_limit_large => 999,	# artificially large interval to force sleep
);

# Readonly scalars derived from config for convenient use in closures
Readonly::Scalar my $KEY      => $config{key_valid};
Readonly::Scalar my $LAT      => $config{lat_nyc};
Readonly::Scalar my $LNG      => $config{lng_nyc};
Readonly::Scalar my $TZ_NYC   => $config{tz_nyc};
Readonly::Scalar my $TZ_RAMS  => $config{tz_ramsgate};

# JSON payloads matching the real timezonedb.com API response format
Readonly::Scalar my $JSON_OK_NYC  => '{"status":"OK","zoneName":"America/New_York","gmtOffset":-18000}';
Readonly::Scalar my $JSON_OK_RAMS => '{"status":"OK","zoneName":"Europe/London","gmtOffset":0}';
Readonly::Scalar my $JSON_FAIL    => '{"status":"FAILED","message":"Invalid API key"}';
Readonly::Scalar my $JSON_BAD     => 'NOT { VALID } JSON <<<';

# ---------------------------------------------------------------------------
# Test-double packages - defined once here to avoid symbol-table pollution
# inside individual subtest closures
# ---------------------------------------------------------------------------

# StubUA: records calls and URLs; returns a single canned HTTP::Response
{
	package StubUA;
	sub new      { bless { resp => $_[1], calls => 0, last_url => undef }, $_[0] }
	sub get      { my ($s, $url) = @_; $s->{calls}++; $s->{last_url} = $url; return $s->{resp} }
	sub calls    { $_[0]->{calls} }
	sub last_url { $_[0]->{last_url} }
}

# StubLogger: captures warn/error messages for later assertion
{
	package StubLogger;
	sub new   { bless { warns => [], errors => [] }, $_[0] }
	sub warn  { push @{$_[0]->{warns}},  $_[1] }
	sub error { push @{$_[0]->{errors}}, $_[1] }
}

# StubLocation: Geo::Location::Point-compatible double
{
	package StubLocation;
	sub new       { bless { lat => $_[1], lng => $_[2] }, $_[0] }
	sub latitude  { $_[0]->{lat} }
	sub longitude { $_[0]->{lng} }
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Construct a 200 OK HTTP::Response with the given JSON body
sub _resp_ok {
	my $body = shift;
	my $r    = HTTP::Response->new($config{http_ok}, 'OK');
	$r->content($body);
	return $r;
}

# Construct an error HTTP::Response (default 500)
sub _resp_err {
	my ($code, $msg) = @_;
	return HTTP::Response->new($code // $config{http_error}, $msg // 'Internal Server Error');
}

# Build a TimeZone::TimeZoneDB backed by a StubUA with a canned response.
# Returns ($tzdb, $stub_ua) so callers can inspect call counts.
sub _tzdb_with {
	my ($resp) = @_;
	my $ua   = StubUA->new($resp);
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua);
	return ($tzdb, $ua);
}

# ---------------------------------------------------------------------------
# Freeze Object::Configure to prevent filesystem access during any new() call
# ---------------------------------------------------------------------------
mock 'Object::Configure::configure' => sub { $_[1] };

# ===========================================================================
# new()
# ===========================================================================

subtest 'new: POD - returns a TimeZone::TimeZoneDB object' => sub {
	# POD: "Creates and returns a new TimeZone::TimeZoneDB instance"
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	isa_ok($tzdb, 'TimeZone::TimeZoneDB', 'new() returns correct class');
	returns_ok($tzdb, { type => 'object' }, 'new() satisfies output schema');
	diag(ref $tzdb) if $ENV{TEST_VERBOSE};
};

subtest 'new: POD - croaks when key is absent' => sub {
	# POD: "Croaks if key is absent"
	# Error must mention the missing key
	throws_ok { TimeZone::TimeZoneDB->new() }
		qr/'key' argument is required/, 'exact croak message for missing key';
};

subtest 'new: POD - default UA is LWP::UserAgent with gzip,deflate' => sub {
	# POD: "Defaults to a plain LWP::UserAgent with gzip,deflate accepted"
	# Observable: the UA used is an LWP::UserAgent instance
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	isa_ok($tzdb->ua(), 'LWP::UserAgent', 'default ua is LWP::UserAgent');
};

subtest 'new: POD - custom ua is used for subsequent requests' => sub {
	# POD: "ua (optional) - An HTTP user-agent object"
	# Observable: requests go through the supplied object
	my ($tzdb, $ua) = _tzdb_with(_resp_ok($JSON_OK_NYC));
	$tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	is($ua->calls(), 1, 'custom ua received the HTTP call');
};

subtest 'new: POD - custom host appears in request URL' => sub {
	# POD: "host (optional) - Override the API hostname"
	# Observable: the URL sent to the UA contains the custom host
	my $custom = $config{host_custom};
	my $ua     = StubUA->new(_resp_ok($JSON_OK_NYC));
	my $tzdb   = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua, host => $custom);
	$tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	like($ua->last_url(), qr{\Q$custom\E}, 'custom host in request URL');
};

subtest 'new: POD - default host is api.timezonedb.com' => sub {
	# POD: "Defaults to api.timezonedb.com"
	my $ua   = StubUA->new(_resp_ok($JSON_OK_NYC));
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua);
	$tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	like($ua->last_url(), qr{\Q$config{host_default}\E}, 'default host in request URL');
};

subtest 'new: POD - custom cache receives the stored response' => sub {
	# POD: "cache (optional) - A CHI-compatible caching object"
	# Observable: a fresh response is written into the supplied cache object
	my $cache_store = {};
	my $cache = bless { s => $cache_store }, 'InspectCache';
	{
		no warnings 'once';
		*InspectCache::get = sub { $cache_store->{ $_[1] } };
		*InspectCache::set = sub { $cache_store->{ $_[1] } = $_[2] };
	}
	my ($tzdb, $ua) = (
		TimeZone::TimeZoneDB->new(key => $KEY, ua => StubUA->new(_resp_ok($JSON_OK_NYC)), cache => $cache),
		undef
	);
	$tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	ok(scalar keys %{$cache_store} > 0, 'custom cache has at least one entry after call');
};

subtest 'new: POD - min_interval 0 causes no sleep' => sub {
	# POD: "min_interval...Defaults to 0 (no enforced delay)"
	my $sleep_calls = 0;
	{
		my $g = mock_scoped 'Time::HiRes::sleep' => sub { $sleep_calls++ };
		my ($tzdb) = _tzdb_with(_resp_ok($JSON_OK_NYC));
		# min_interval defaults to 0 when not specified
		$tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	}
	is($sleep_calls, 0, 'no sleep when min_interval is 0 (default)');
};

subtest 'new: POD - clone returns a new object of the same class' => sub {
	# POD: "When invoked on an existing object...returns a shallow clone"
	my $orig  = TimeZone::TimeZoneDB->new(key => $KEY);
	my $clone = $orig->new();
	isa_ok($clone, 'TimeZone::TimeZoneDB', 'clone is correct class');
	isnt($clone, $orig, 'clone is a distinct reference');
};

subtest 'new: POD - clone with ua=>undef inherits original ua' => sub {
	# POD: "Passing ua=>undef in a clone call is silently ignored
	#       so that the original user-agent is inherited unchanged"
	# Observable: a call on the clone uses the original ua
	my $ua    = StubUA->new(_resp_ok($JSON_OK_NYC));
	my $orig  = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua);
	my $clone = $orig->new(ua => undef);
	$clone->get_time_zone(latitude => $LAT, longitude => $LNG);
	is($ua->calls(), 1, 'clone used original ua after ua=>undef');
};

subtest 'new: POD - clone can override a parameter' => sub {
	# POD: "shallow clone of that object with any supplied parameters merged in"
	my $custom = $config{host_custom};
	my $ua     = StubUA->new(_resp_ok($JSON_OK_NYC));
	my $orig   = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua);
	my $clone  = $orig->new(host => $custom);
	$clone->get_time_zone(latitude => $LAT, longitude => $LNG);
	like($ua->last_url(), qr{\Q$custom\E}, 'clone uses overridden host');
};

subtest 'new: POD - logger key passes through to the object' => sub {
	# POD NOTES: "An optional logger key may be passed"
	# Observable: if a logger is present, warnings/errors are sent to it
	my $logger = StubLogger->new();
	my $ua     = StubUA->new(_resp_ok($JSON_FAIL));
	my $tzdb   = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua, logger => $logger);
	$tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	is(scalar @{$logger->{warns}}, 1, 'logger received warning for non-OK API status');
};

# ===========================================================================
# get_time_zone()
# ===========================================================================

subtest 'get_time_zone: POD - croaks with no arguments' => sub {
	# POD: "Croaks on...invalid arguments"
	my ($tzdb) = _tzdb_with(_resp_ok($JSON_OK_NYC));
	throws_ok { $tzdb->get_time_zone() }
		qr/required parameter/i, 'croaks with no args';
};

subtest 'get_time_zone: POD - croaks with only latitude supplied' => sub {
	# longitude is also required; latitude alone must croak
	my ($tzdb) = _tzdb_with(_resp_ok($JSON_OK_NYC));
	throws_ok { $tzdb->get_time_zone(latitude => $LAT) }
		qr/required parameter/i, 'croaks with latitude only';
};

subtest 'get_time_zone: POD - croaks with only longitude supplied' => sub {
	# latitude is also required; longitude alone must croak
	my ($tzdb) = _tzdb_with(_resp_ok($JSON_OK_NYC));
	throws_ok { $tzdb->get_time_zone(longitude => $LNG) }
		qr/required parameter/i, 'croaks with longitude only';
};

subtest 'get_time_zone: POD - croaks when latitude > 90' => sub {
	# POD: "latitude...range -90 to +90"
	my ($tzdb) = _tzdb_with(_resp_ok($JSON_OK_NYC));
	throws_ok { $tzdb->get_time_zone(latitude => $config{lat_boundary_max} + 1, longitude => 0) }
		qr//i, 'croaks for lat > 90';
};

subtest 'get_time_zone: POD - croaks when latitude < -90' => sub {
	my ($tzdb) = _tzdb_with(_resp_ok($JSON_OK_NYC));
	throws_ok { $tzdb->get_time_zone(latitude => $config{lat_boundary_min} - 1, longitude => 0) }
		qr//i, 'croaks for lat < -90';
};

subtest 'get_time_zone: POD - croaks when longitude > 180' => sub {
	# POD: "longitude...range -180 to +180"
	my ($tzdb) = _tzdb_with(_resp_ok($JSON_OK_NYC));
	throws_ok { $tzdb->get_time_zone(latitude => 0, longitude => $config{lng_boundary_max} + 1) }
		qr//i, 'croaks for lng > 180';
};

subtest 'get_time_zone: POD - croaks when longitude < -180' => sub {
	my ($tzdb) = _tzdb_with(_resp_ok($JSON_OK_NYC));
	throws_ok { $tzdb->get_time_zone(latitude => 0, longitude => $config{lng_boundary_min} - 1) }
		qr//i, 'croaks for lng < -180';
};

subtest 'get_time_zone: POD - boundary value +90/+180 is accepted' => sub {
	# The boundary itself must not croak (range is inclusive)
	my ($tzdb) = _tzdb_with(_resp_ok($JSON_OK_NYC));
	lives_ok {
		$tzdb->get_time_zone(latitude  => $config{lat_boundary_max},
		                     longitude => $config{lng_boundary_max})
	} 'lat=90 lng=180 accepted';
};

subtest 'get_time_zone: POD - boundary value -90/-180 is accepted' => sub {
	my ($tzdb) = _tzdb_with(_resp_ok($JSON_OK_NYC));
	lives_ok {
		$tzdb->get_time_zone(latitude  => $config{lat_boundary_min},
		                     longitude => $config{lng_boundary_min})
	} 'lat=-90 lng=-180 accepted';
};

subtest 'get_time_zone: POD - returns a non-empty hashref on success' => sub {
	# POD RETURNS: "A hashref containing at least zoneName on success"
	my ($tzdb) = _tzdb_with(_resp_ok($JSON_OK_NYC));
	my $result  = $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);

	ok(defined $result,            'result is defined');
	is(ref $result, 'HASH',        'result is a hashref');
	ok(exists $result->{zoneName}, 'result contains zoneName');
	is($result->{zoneName}, $TZ_NYC, 'zoneName value is correct');

	# Verify the Return::Set output contract from the POD API SPEC
	returns_ok($result, { type => 'hashref', min => 1 }, 'output satisfies API schema');
	diag("zoneName: $result->{zoneName}") if $ENV{TEST_VERBOSE};
};

subtest 'get_time_zone: POD - accepts hashref argument style' => sub {
	# POD shows { latitude => ..., longitude => ... } calling form
	my ($tzdb) = _tzdb_with(_resp_ok($JSON_OK_NYC));
	my $result = $tzdb->get_time_zone({ latitude => $LAT, longitude => $LNG });
	is($result->{zoneName}, $TZ_NYC, 'hashref arg style returns correct timezone');
};

subtest 'get_time_zone: POD - accepts a Geo::Location::Point-compatible object' => sub {
	# POD: "a single Geo::Location::Point-compatible object may be passed"
	my ($tzdb) = _tzdb_with(_resp_ok($JSON_OK_RAMS));
	my $loc     = StubLocation->new($config{lat_ramsgate}, $config{lng_ramsgate});
	my $result  = $tzdb->get_time_zone($loc);
	is($result->{zoneName}, $TZ_RAMS, 'location object yields correct timezone');
};

subtest 'get_time_zone: POD - returns undef for non-OK API status' => sub {
	# POD RETURNS: "Returns undef when the API responds with a non-OK status"
	my ($tzdb) = _tzdb_with(_resp_ok($JSON_FAIL));
	my $result = $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	ok(!defined $result, 'undef returned for FAILED status');
};

subtest 'get_time_zone: POD - croaks on HTTP error' => sub {
	# POD RETURNS: "Croaks on HTTP errors"
	my ($tzdb) = _tzdb_with(_resp_err($config{http_error}));
	throws_ok { $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG) }
		qr/API returned error/i, 'croaks on 5xx response';
};

subtest 'get_time_zone: POD - API key redacted from HTTP error message' => sub {
	# POD NOTES: "The key is redacted from all error and warning messages"
	my ($tzdb) = _tzdb_with(_resp_err($config{http_error}));
	my $err;
	eval { $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG) };
	$err = $@;
	like($err,   qr/REDACTED/,   'error message contains REDACTED placeholder');
	unlike($err, qr/\Q$KEY\E/,   'actual API key absent from error message');
	diag("redacted error: $err") if $ENV{TEST_VERBOSE};
};

subtest 'get_time_zone: POD - carps (not croaks) on malformed JSON, returns undef' => sub {
	# The POD does not document invalid JSON explicitly, but the code chooses
	# a soft failure (carp + return undef) rather than croak.
	# Test that the published output schema (undef = no result) is honoured.
	my ($tzdb) = _tzdb_with(_resp_ok($JSON_BAD));
	my $result;
	warning_like {
		$result = $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG)
	} qr/failed to parse json/i, 'emits warning on malformed JSON';
	ok(!defined $result, 'returns undef after JSON parse failure');
};

subtest 'get_time_zone: POD - identical calls are served from cache' => sub {
	# POD: "Identical queries are served from cache without making a network request"
	# Observable: a StubUA that only handles one call but both calls succeed
	my ($tzdb, $ua) = _tzdb_with(_resp_ok($JSON_OK_NYC));
	my $r1 = $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	my $r2 = $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);

	is($ua->calls(), 1,        'UA called only once for two identical requests');
	is_deeply($r2, $r1,        'second call returns same data as first');
};

subtest 'get_time_zone: POD - coordinate normalisation (0.1 == 0.1000000)' => sub {
	# POD: "cache key is constructed from normalised coordinates (6 decimal places)
	#       so that 0.1 and 0.1000000 share the same cache entry"
	my ($tzdb, $ua) = _tzdb_with(_resp_ok($JSON_OK_NYC));
	$tzdb->get_time_zone(latitude => 0.1,       longitude => 0.2);
	$tzdb->get_time_zone(latitude => 0.1000000, longitude => 0.2000000);
	is($ua->calls(), 1, '0.1 and 0.1000000 share the same cache slot');
};

subtest 'get_time_zone: POD - last_request updated (rate-limit side-effect)' => sub {
	# POD SIDE EFFECTS: "Updates the internal response cache and the last_request timestamp"
	# Observable via rate-limiting: after one call the second call triggers sleep
	my $sleep_calls = 0;
	{
		my $g = mock_scoped 'Time::HiRes::sleep' => sub { $sleep_calls++ };
		my $ua   = StubUA->new(_resp_ok($JSON_OK_NYC));
		my $tzdb = TimeZone::TimeZoneDB->new(
			key          => $KEY,
			ua           => $ua,
			min_interval => $config{rate_limit_large},
		);
		# First call: last_request starts at 0, elapsed is very large, no sleep
		$tzdb->get_time_zone(latitude => $LAT,                  longitude => $LNG);
		# Second call: last_request just updated, elapsed ~0 < large, must sleep
		$tzdb->get_time_zone(latitude => $config{lat_ramsgate}, longitude => $config{lng_ramsgate});
	}
	is($sleep_calls, 1, 'sleep called for second request, confirming last_request was set');
};

subtest 'get_time_zone: POD - logger warned for non-OK status, key redacted' => sub {
	# POD NOTES: "key is redacted from all...warning messages"
	my $logger = StubLogger->new();
	my $ua     = StubUA->new(_resp_ok($JSON_FAIL));
	my $tzdb   = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua, logger => $logger);

	$tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);

	is(scalar @{$logger->{warns}}, 1,   'logger->warn called for non-OK status');
	unlike($logger->{warns}[0], qr/\Q$KEY\E/, 'logger message has key redacted');
	diag("logger warn: $logger->{warns}[0]") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# ua()
# ===========================================================================

subtest 'ua: POD - getter returns the current user-agent' => sub {
	# POD RETURNS: "the existing value when called as a getter"
	my $ua    = StubUA->new(_resp_ok($JSON_OK_NYC));
	my $tzdb  = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua);
	my $got   = $tzdb->ua();
	is($got, $ua, 'getter returns the stored UA');
	returns_ok($got, { type => 'object' }, 'getter satisfies output schema');
};

subtest 'ua: POD - setter makes subsequent calls use the new ua' => sub {
	# POD SIDE EFFECTS: "all subsequent API calls...use the new user-agent"
	my $old_ua = StubUA->new(_resp_ok($JSON_OK_NYC));
	my $new_ua = StubUA->new(_resp_ok($JSON_OK_RAMS));
	my $tzdb   = TimeZone::TimeZoneDB->new(key => $KEY, ua => $old_ua);

	$tzdb->ua($new_ua);
	$tzdb->get_time_zone(latitude => $config{lat_ramsgate}, longitude => $config{lng_ramsgate});

	is($new_ua->calls(), 1, 'new ua received the call after setter');
	is($old_ua->calls(), 0, 'old ua no longer used after setter');
};

subtest 'ua: POD - setter returns the new user-agent, not $self' => sub {
	# POD NOTES: "The accessor always returns the user-agent rather than $self"
	my $old_ua = StubUA->new(_resp_ok($JSON_OK_NYC));
	my $new_ua = StubUA->new(_resp_ok($JSON_OK_RAMS));
	my $tzdb   = TimeZone::TimeZoneDB->new(key => $KEY, ua => $old_ua);

	my $ret = $tzdb->ua($new_ua);
	is($ret,   $new_ua, 'setter returns the new UA');
	isnt($ret, $tzdb,   'setter does not return $self');
	returns_ok($ret, { type => 'object' }, 'setter satisfies output schema');
};

subtest 'ua: POD - getter return value supports chained method call' => sub {
	# POD example: $tzdb->ua()->env_proxy(1)
	# Observable: the return value is an object with callable methods
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	my $ua   = $tzdb->ua();
	can_ok($ua, 'get');
};

subtest 'ua: POD - croaks on undef with exact message' => sub {
	# POD RETURNS: "Croaks...if undef is explicitly passed"
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	throws_ok { $tzdb->ua(undef) }
		qr/ua\(\) requires a defined value/, 'exact croak message for undef';
};

subtest 'ua: POD - croaks when given an object without get()' => sub {
	# POD RETURNS: "Croaks if a defined but invalid object (no get() method)"
	my $tzdb   = TimeZone::TimeZoneDB->new(key => $KEY);
	my $bad_ua = bless {}, 'NoGetMethod';
	throws_ok { $tzdb->ua($bad_ua) }
		qr//i, 'croaks for object without get()';
};

subtest 'ua: POD - logger error called when given undef' => sub {
	# POD NOTES: logger must implement warn() and error()
	my $logger = StubLogger->new();
	my $tzdb   = TimeZone::TimeZoneDB->new(key => $KEY, logger => $logger);
	eval { $tzdb->ua(undef) };
	is(scalar @{$logger->{errors}}, 1, 'logger->error called once for undef');
	diag("logger error: $logger->{errors}[0]") if $ENV{TEST_VERBOSE};
};

subtest 'ua: POD - original ua unchanged after failed setter call' => sub {
	# A croak in the setter must not corrupt the previously stored UA
	my $orig_ua = StubUA->new(_resp_ok($JSON_OK_NYC));
	my $tzdb    = TimeZone::TimeZoneDB->new(key => $KEY, ua => $orig_ua);

	# This croak must not touch $self->{ua}
	eval { $tzdb->ua(undef) };

	my $result = $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	is($orig_ua->calls(), 1,    'original ua still used after failed setter');
	is($result->{zoneName}, $TZ_NYC, 'correct result from unmodified ua');
};

subtest 'ua: named-parameter form ua($obj) and ua(ua => $obj) are equivalent' => sub {
	# Both positional and named calling conventions must produce the same result
	my $ua1  = StubUA->new(_resp_ok($JSON_OK_NYC));
	my $ua2  = StubUA->new(_resp_ok($JSON_OK_NYC));
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua1);

	# Positional setter
	my $ret_pos = $tzdb->ua($ua2);
	is($ret_pos, $ua2, 'positional ua($obj) returns new ua');

	# Named setter - now test the named form
	my $ua3     = StubUA->new(_resp_ok($JSON_OK_NYC));
	my $ret_nam = $tzdb->ua(ua => $ua3);
	is($ret_nam, $ua3, 'named ua(ua => $obj) returns new ua');
};

# ---------------------------------------------------------------------------
# Restore all mocks installed during this file
# ---------------------------------------------------------------------------
restore_all();

done_testing();
