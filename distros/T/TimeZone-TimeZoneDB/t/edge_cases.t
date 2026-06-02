#!/usr/bin/env perl

# Destructive, pathological, boundary-condition and security tests.
# Goal: actively try to break the module with undef, 0, empty strings,
# enormous values, wrong reference types, injection attempts, and
# context confusion.  All external I/O is mocked at the HTTP layer.

use strict;
use warnings;

use lib 'lib';
use lib "$ENV{HOME}/src/njh/Test-Mockingbird/lib";
use lib "$ENV{HOME}/src/njh/Test-Returns/lib";

use HTTP::Response;
use Readonly;
use Scalar::Util qw(blessed);
use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use Test::Warn;

use TimeZone::TimeZoneDB;

# ---------------------------------------------------------------------------
# Configuration -- every literal value lives here
# ---------------------------------------------------------------------------
my %config = (
	key_valid        => 'valid_api_key',
	key_empty        => '',
	key_zero         => '0',
	key_whitespace   => '   ',
	key_newline      => "key\ninjected",
	key_injection    => 'k&by=injected&format=xml',
	key_very_long    => 'X' x 10_000,
	key_unicode_like => "k\x{C3}\x{A9}y",   # UTF-8 bytes that sneak through

	host_empty       => '',
	host_zero        => '0',
	host_default     => 'api.timezonedb.com',
	host_ssrf_at     => 'legit.com@evil.com',

	lat_zero         =>  0,
	lng_zero         =>  0,
	lat_valid        =>  40.7128,
	lng_valid        => -74.006,

	min_interval_neg => -99,
	min_interval_big => 999_999,

	http_ok          => 200,
	http_err         => 500,
);

# Readonly scalars for use in closures
Readonly::Scalar my $KEY   => $config{key_valid};
Readonly::Scalar my $LAT   => $config{lat_valid};
Readonly::Scalar my $LNG   => $config{lng_valid};

# Canned JSON responses for various edge scenarios
Readonly::Scalar my $JSON_OK       => '{"status":"OK","zoneName":"America/New_York"}';
Readonly::Scalar my $JSON_OK_LC    => '{"status":"ok","zoneName":"America/New_York"}';  # lowercase
Readonly::Scalar my $JSON_FAIL     => '{"status":"FAILED","message":"bad key"}';
Readonly::Scalar my $JSON_EMPTY    => '{}';
Readonly::Scalar my $JSON_SINGLE   => '{"status":"OK"}';
Readonly::Scalar my $JSON_ARRAY    => '[{"status":"OK","zoneName":"Etc/UTC"}]';
Readonly::Scalar my $JSON_NULL     => 'null';
Readonly::Scalar my $JSON_FALSE    => 'false';
Readonly::Scalar my $JSON_TRUE     => 'true';
Readonly::Scalar my $JSON_ZERO     => '0';
Readonly::Scalar my $JSON_NESTED   => '{"status":"OK","data":' . ('{"x":' x 50) . '1' . ('}' x 50) . '}';

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Build a 200 OK response with the given body
sub _ok_resp {
	my ($body) = @_;
	my $r = HTTP::Response->new($config{http_ok}, 'OK');
	$r->content($body // '');
	return $r;
}

# Build a server-error response
sub _err_resp {
	return HTTP::Response->new($config{http_err}, 'Internal Server Error');
}

# Minimal UA stub that returns a single canned response and records the URL
{
	package StubUA;
	sub new      { bless { resp => $_[1], url => undef, calls => 0 }, $_[0] }
	sub get      { $_[0]->{calls}++; $_[0]->{url} = $_[1]; return $_[0]->{resp} }
	sub last_url { $_[0]->{url} }
	sub calls    { $_[0]->{calls} }
}

# Minimal object with ->get() for ua() setter tests
{
	package GoodUA;
	sub new { bless {}, $_[0] }
	sub get { return undef }
}

# Freeze Object::Configure for every test
mock 'Object::Configure::configure' => sub { $_[1] };

# ===========================================================================
# new() -- pathological key values
# ===========================================================================

subtest 'edge: new() with empty-string key croaks' => sub {
	# "" is falsy in Perl, so the "or croak" guard must fire
	throws_ok { TimeZone::TimeZoneDB->new(key => $config{key_empty}) }
		qr/'key' argument is required/, 'empty-string key croaks with exact message';
};

subtest 'edge: new() with key "0" croaks (falsy string)' => sub {
	# "0" is the only non-empty string that is falsy; the guard must still fire
	throws_ok { TimeZone::TimeZoneDB->new(key => $config{key_zero}) }
		qr/'key' argument is required/, '"0" key croaks because "0" is falsy in Perl';
};

subtest 'edge: new() with whitespace-only key is accepted (truthy)' => sub {
	# A key of "   " is truthy; the module accepts it and encodes it in the URL
	my $tzdb;
	lives_ok { $tzdb = TimeZone::TimeZoneDB->new(key => $config{key_whitespace}) }
		'whitespace key accepted (truthy non-empty string)';
	ok(defined $tzdb, 'object was created');
	diag("whitespace key stored: '$config{key_whitespace}'") if $ENV{TEST_VERBOSE};
};

subtest 'edge: new() with very long key accepted (no length limit)' => sub {
	# No length limit is imposed; the long key is passed through to the URL
	my $tzdb;
	lives_ok { $tzdb = TimeZone::TimeZoneDB->new(key => $config{key_very_long}) }
		'10 000-character key accepted';
	ok(defined $tzdb, 'object was created with very long key');
};

subtest 'edge: new() with key containing newline is accepted' => sub {
	# The module does not strip newlines from the key; it URL-encodes them
	my $tzdb;
	lives_ok { $tzdb = TimeZone::TimeZoneDB->new(key => $config{key_newline}) }
		'key with embedded newline accepted';
};

# ===========================================================================
# new() -- edge values for host
# ===========================================================================

subtest 'edge: new() empty host falls back to default host' => sub {
	# "" is falsy; the || in "my $host = $params->{host} || $config{host}" picks the default
	my $ua   = StubUA->new(_ok_resp($JSON_OK));
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY, host => $config{host_empty}, ua => $ua);
	$tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	like($ua->last_url(), qr{\Q$config{host_default}\E}, 'empty host falls back to api.timezonedb.com');
};

subtest 'edge: new() host "0" is falsy and falls back to default' => sub {
	# "0" is falsy; the || operator replaces it with the default host
	my $ua   = StubUA->new(_ok_resp($JSON_OK));
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY, host => $config{host_zero}, ua => $ua);
	$tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	like($ua->last_url(), qr{\Q$config{host_default}\E}, '"0" host falls back to default');
};

# ===========================================================================
# new() -- edge values for min_interval
# ===========================================================================

subtest 'edge: new() negative min_interval stored as-is' => sub {
	# No lower-bound validation on min_interval; negative means no sleep ever fires
	# (elapsed < -99 is always false for realistic time values)
	my $sleep_called = 0;
	{
		my $g = mock_scoped 'Time::HiRes::sleep' => sub { $sleep_called++ };
		my $ua   = StubUA->new(_ok_resp($JSON_OK));
		my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua,
			min_interval => $config{min_interval_neg});
		$tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	}
	is($sleep_called, 0, 'negative min_interval never triggers sleep');
};

subtest 'edge: new() very large min_interval stored without error' => sub {
	# The constructor accepts any numeric min_interval without croaking
	my $tzdb;
	lives_ok {
		$tzdb = TimeZone::TimeZoneDB->new(key => $KEY,
			min_interval => $config{min_interval_big});
	} 'very large min_interval accepted by constructor';
	ok(defined $tzdb, 'object created with very large min_interval');
};

# ===========================================================================
# new() -- clone path with invalid ua values (security: prevents bad state)
# ===========================================================================

subtest 'edge: clone with ua=>0 croaks (defined but invalid)' => sub {
	# A defined, non-object ua must be rejected even in the clone path.
	# Passing ua=>0 previously stored 0 silently, crashing the next API call.
	my $orig = TimeZone::TimeZoneDB->new(key => $KEY);
	throws_ok { $orig->new(ua => 0) }
		qr/get\(\) method/i, 'clone with ua=>0 croaks';
};

subtest 'edge: clone with ua=>"string" croaks' => sub {
	# A plain string is not a UA object; the clone path must reject it
	my $orig = TimeZone::TimeZoneDB->new(key => $KEY);
	throws_ok { $orig->new(ua => 'http://bad') }
		qr/get\(\) method/i, 'clone with ua string croaks';
};

subtest 'edge: clone with ua=>[] (unblessed ref) croaks' => sub {
	# An unblessed arrayref lacks the required ->get() method
	my $orig = TimeZone::TimeZoneDB->new(key => $KEY);
	throws_ok { $orig->new(ua => []) }
		qr/get\(\) method/i, 'clone with ua arrayref croaks';
};

subtest 'edge: clone with ua=>{} (unblessed hashref) croaks' => sub {
	# An unblessed hashref is not a valid UA
	my $orig = TimeZone::TimeZoneDB->new(key => $KEY);
	throws_ok { $orig->new(ua => {}) }
		qr/get\(\) method/i, 'clone with ua hashref croaks';
};

subtest 'edge: clone with ua=>undef still silently drops it' => sub {
	# The existing undef-drop behaviour must still work after the fix
	my $ua   = GoodUA->new();
	my $orig = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua);
	my $clone;
	lives_ok { $clone = $orig->new(ua => undef) }
		'clone with ua=>undef does not croak';
	is($clone->ua(), $ua, 'original ua inherited when ua=>undef given');
};

subtest 'edge: clone with valid ua object still works' => sub {
	# A proper UA object must still be accepted in the clone path
	my $old_ua = GoodUA->new();
	my $new_ua = GoodUA->new();
	my $orig   = TimeZone::TimeZoneDB->new(key => $KEY, ua => $old_ua);
	my $clone;
	lives_ok { $clone = $orig->new(ua => $new_ua) }
		'clone with valid ua does not croak';
	is($clone->ua(), $new_ua, 'new ua stored in clone');
};

# ===========================================================================
# get_time_zone() -- coordinate zero (falsy but valid)
# ===========================================================================

subtest 'edge: get_time_zone latitude=0 is valid (equator)' => sub {
	# 0 is a valid latitude (the equator); it must NOT be treated as missing
	my $ua   = StubUA->new(_ok_resp($JSON_OK));
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua);
	my $result;
	lives_ok { $result = $tzdb->get_time_zone(latitude => 0, longitude => 0) }
		'latitude=0 longitude=0 is valid';
	ok(defined $result, 'result defined for equator coordinates');
	like($ua->last_url(), qr{lat=0\b}, 'URL contains lat=0');
};

subtest 'edge: get_time_zone latitude=0.0 (floating zero) is valid' => sub {
	# 0.0 must not be treated differently from 0
	my $ua   = StubUA->new(_ok_resp($JSON_OK));
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua);
	lives_ok { $tzdb->get_time_zone(latitude => 0.0, longitude => 0.0) }
		'0.0 coordinates accepted';
};

# ===========================================================================
# get_time_zone() -- pathological coordinate types
# ===========================================================================

subtest 'edge: get_time_zone latitude=undef croaks' => sub {
	# undef latitude must not silently convert to 0 or empty string
	my $ua   = StubUA->new(_ok_resp($JSON_OK));
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua);
	throws_ok { $tzdb->get_time_zone(latitude => undef, longitude => $LNG) }
		qr/required parameter/i, 'undef latitude croaks';
};

subtest 'edge: get_time_zone longitude=undef croaks' => sub {
	my $ua   = StubUA->new(_ok_resp($JSON_OK));
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua);
	throws_ok { $tzdb->get_time_zone(latitude => $LAT, longitude => undef) }
		qr/required parameter/i, 'undef longitude croaks';
};

subtest 'edge: get_time_zone latitude="" (empty string) croaks' => sub {
	# An empty string is not a valid number; validate_strict must reject it
	my $ua   = StubUA->new(_ok_resp($JSON_OK));
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua);
	throws_ok { $tzdb->get_time_zone(latitude => '', longitude => $LNG) }
		qr//i, 'empty-string latitude croaks';
};

subtest 'edge: get_time_zone latitude="abc" (non-numeric string) croaks' => sub {
	# A non-numeric string must be rejected by type=number validation
	my $ua   = StubUA->new(_ok_resp($JSON_OK));
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua);
	throws_ok { $tzdb->get_time_zone(latitude => 'abc', longitude => $LNG) }
		qr//i, 'non-numeric latitude string croaks';
};

subtest 'edge: get_time_zone latitude=[] (arrayref) croaks' => sub {
	# Reference types must be rejected by type=number validation
	my $ua   = StubUA->new(_ok_resp($JSON_OK));
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua);
	throws_ok { $tzdb->get_time_zone(latitude => [], longitude => $LNG) }
		qr//i, 'arrayref latitude croaks';
};

subtest 'edge: get_time_zone latitude=sub{} (coderef) croaks' => sub {
	my $ua   = StubUA->new(_ok_resp($JSON_OK));
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua);
	throws_ok { $tzdb->get_time_zone(latitude => sub{}, longitude => $LNG) }
		qr//i, 'coderef latitude croaks';
};

# ===========================================================================
# get_time_zone() -- location object returning bad coordinates
# ===========================================================================

subtest 'edge: location object with latitude()=undef causes croak' => sub {
	# If a location object returns undef from latitude(), validate_strict must catch it
	my $bad_loc = bless {}, 'BadLoc';
	{
		no warnings 'once';
		*BadLoc::latitude  = sub { undef };
		*BadLoc::longitude = sub { $config{lng_valid} };
	}
	my $ua   = StubUA->new(_ok_resp($JSON_OK));
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua);
	throws_ok { $tzdb->get_time_zone($bad_loc) }
		qr/required parameter/i, 'location with undef latitude() croaks';
};

subtest 'edge: location object with latitude()="" causes croak' => sub {
	# An empty string from latitude() is an invalid number
	my $bad_loc = bless {}, 'EmptyLatLoc';
	{
		no warnings 'once';
		*EmptyLatLoc::latitude  = sub { '' };
		*EmptyLatLoc::longitude = sub { $config{lng_valid} };
	}
	my $ua   = StubUA->new(_ok_resp($JSON_OK));
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua);
	throws_ok { $tzdb->get_time_zone($bad_loc) }
		qr//i, 'location with empty-string latitude() croaks';
};

subtest 'edge: location object with latitude()=91 (out of range) croaks' => sub {
	# Out-of-range value from latitude() must be caught by range validation
	my $bad_loc = bless {}, 'OutOfRangeLoc';
	{
		no warnings 'once';
		*OutOfRangeLoc::latitude  = sub { 91 };
		*OutOfRangeLoc::longitude = sub { 0 };
	}
	my $ua   = StubUA->new(_ok_resp($JSON_OK));
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua);
	throws_ok { $tzdb->get_time_zone($bad_loc) }
		qr//i, 'location object with lat=91 croaks';
};

# ===========================================================================
# get_time_zone() -- upstream UA returning edge-case HTTP responses
# ===========================================================================

subtest 'edge: UA returns response with empty body (carp + undef)' => sub {
	# An empty body produces a JSON parse failure; must carp and return undef
	my $ua   = StubUA->new(_ok_resp(''));
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua);
	my $result;
	warning_like {
		$result = $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	} qr/failed to parse json/i, 'empty body produces carp';
	ok(!defined $result, 'empty body returns undef');
};

subtest 'edge: UA returns JSON null ("null") - not a hashref' => sub {
	# JSON "null" decodes to Perl undef; Return::Set min=>1 must reject it
	my $ua   = StubUA->new(_ok_resp($JSON_NULL));
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua);
	my $result;
	# "null" decodes to undef; the status check ($rc && ...) is false for undef
	# so the code falls through to Return::Set which sees undef/empty hashref
	eval { $result = $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG) };
	# Expected: either undef or croak from Return::Set; not a valid hashref
	ok(!defined $result || $@, 'JSON null does not return a valid hashref');
	diag("JSON null result: " . (defined $result ? ref($result) : 'undef')) if $ENV{TEST_VERBOSE};
};

subtest 'edge: UA returns JSON array instead of object' => sub {
	# An array as the top-level JSON value is not a hashref; Return::Set must reject it
	my $ua   = StubUA->new(_ok_resp($JSON_ARRAY));
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua);
	my $result;
	eval { $result = $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG) };
	ok(!defined $result || $@, 'JSON array does not return a valid hashref');
	diag("JSON array result: " . ($@ // (defined $result ? ref($result) : 'undef'))) if $ENV{TEST_VERBOSE};
};

subtest 'edge: UA returns JSON false -- status check skipped, Return::Set rejects' => sub {
	# JSON "false" -> JSON::false object (falsy bool); $rc && ... skips status check
	my $ua   = StubUA->new(_ok_resp($JSON_FALSE));
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua);
	my $result;
	eval { $result = $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG) };
	ok(!defined $result || $@, 'JSON false does not return a valid result');
};

subtest 'edge: status "ok" (lowercase) is treated as non-OK' => sub {
	# The comparison uses "ne 'OK'" which is case-sensitive; lowercase "ok" fails
	my $ua   = StubUA->new(_ok_resp($JSON_OK_LC));
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua);
	my $result = $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	ok(!defined $result, 'lowercase "ok" status treated as non-OK, returns undef');
	diag('Case-sensitive status check: "ok" != "OK"') if $ENV{TEST_VERBOSE};
};

subtest 'edge: deeply nested JSON response handled without stack overflow' => sub {
	# 50 levels of nesting must parse cleanly
	my $ua   = StubUA->new(_ok_resp($JSON_NESTED));
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua);
	my $result;
	lives_ok { $result = $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG) }
		'deeply nested JSON does not crash';
	ok(defined $result, 'deeply nested JSON returns a result');
};

subtest 'edge: UA get() returning undef dies with a method error' => sub {
	# LWP::UserAgent never returns undef, but a mocked UA that does should cause
	# an explicit, not-silently-ignored error (not corruption of state)
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	{
		my $g = mock_scoped 'LWP::UserAgent::get' => sub { undef };
		eval { $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG) };
		ok($@, 'undef response from UA propagates as an error');
		diag("undef-UA error: $@") if $ENV{TEST_VERBOSE};
	}
};

subtest 'edge: cache returning 0 (falsy) is treated as a cache miss' => sub {
	# The code uses "if(my $cached = cache->get(...))" which fails for falsy values.
	# A cache storing 0 would therefore be bypassed (treated as a miss).
	# Use StubUA (not LWP mock) because $tzdb->{ua} IS the StubUA, not LWP::UserAgent.
	my $fake_cache = bless {}, 'ZeroCache';
	{
		no warnings 'once';
		# Always return 0 from get() -- falsy, so cache miss branch is taken
		*ZeroCache::get = sub { 0 };
		*ZeroCache::set = sub {};
	}
	my $ua   = StubUA->new(_ok_resp($JSON_OK));
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua, cache => $fake_cache);
	$tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	$tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	is($ua->calls(), 2, 'falsy cache->get(0) treated as miss: StubUA called twice');
	diag('Falsy cache return bypasses the cache hit branch') if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# ua() -- every non-object type must croak
# ===========================================================================

subtest 'edge: ua(0) -- numeric zero croaks' => sub {
	# 0 is not an object; the validator must reject it
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	throws_ok { $tzdb->ua(0) }
		qr//i, 'ua(0) croaks';
};

subtest 'edge: ua("") -- empty string croaks' => sub {
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	throws_ok { $tzdb->ua('') }
		qr//i, 'ua("") croaks';
};

subtest 'edge: ua(1) -- non-zero number croaks' => sub {
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	throws_ok { $tzdb->ua(1) }
		qr//i, 'ua(1) croaks';
};

subtest 'edge: ua([]) -- unblessed arrayref croaks' => sub {
	# An unblessed arrayref cannot satisfy "can => get"
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	throws_ok { $tzdb->ua([]) }
		qr//i, 'ua([]) croaks';
};

subtest 'edge: ua({}) -- unblessed hashref croaks' => sub {
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	throws_ok { $tzdb->ua({}) }
		qr//i, 'ua({}) croaks';
};

subtest 'edge: ua(sub{}) -- coderef croaks' => sub {
	# A coderef cannot respond to ->get()
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	throws_ok { $tzdb->ua(sub{}) }
		qr//i, 'ua(sub{}) croaks';
};

subtest 'edge: ua(\*STDOUT) -- typeglob ref croaks' => sub {
	# A typeglob reference is not a valid UA
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	throws_ok { $tzdb->ua(\*STDOUT) }
		qr//i, 'ua(typeglob ref) croaks';
};

subtest 'edge: ua() state intact after every failed setter' => sub {
	# After each rejected value the original UA must remain accessible
	my $original = GoodUA->new();
	my $tzdb     = TimeZone::TimeZoneDB->new(key => $KEY, ua => $original);

	for my $bad (undef, 0, '', 1, [], {}, sub{}) {
		eval { $tzdb->ua($bad) };
		is($tzdb->ua(), $original, "original UA intact after ua(${\ref(\$bad) || (defined $bad ? $bad : 'undef')}) failed");
	}
};

# ===========================================================================
# Security: key injection via URL encoding
# ===========================================================================

subtest 'security: URL-injection chars in key are safely encoded' => sub {
	# "key&by=injected&format=xml" must appear URL-encoded, not as raw query params
	my $ua   = StubUA->new(_ok_resp($JSON_OK));
	my $tzdb = TimeZone::TimeZoneDB->new(key => $config{key_injection}, ua => $ua);
	$tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);

	my $url = $ua->last_url();
	# URI::query_form encodes & as %26 so injection chars never become separate params
	unlike($url, qr/by=injected/,   'injected "by" param not present as raw param');
	unlike($url, qr/format=xml/,    'injected "format=xml" not present as raw param');
	like($url,   qr/key=/,          'key param is present');
	diag("injection test URL: $url") if $ENV{TEST_VERBOSE};
};

subtest 'security: key with newline is URL-encoded, not split into headers' => sub {
	# A newline in the key must not become an HTTP header injection (it goes in the
	# query string which is URL-encoded by URI, not in headers)
	my $ua   = StubUA->new(_ok_resp($JSON_OK));
	my $tzdb = TimeZone::TimeZoneDB->new(key => $config{key_newline}, ua => $ua);
	$tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	my $url = $ua->last_url();
	# The raw newline should not appear in the URL string (URI encodes it as %0A)
	unlike($url, qr/\n/, 'newline in key not raw in URL');
	diag("newline key URL: $url") if $ENV{TEST_VERBOSE};
};

subtest 'security: HTTP error message exposes REDACTED not actual key' => sub {
	# Even with an injection-laden key, error messages must redact the key
	my $tzdb = TimeZone::TimeZoneDB->new(key => $config{key_injection});
	{
		my $g = mock_scoped 'LWP::UserAgent::get' => sub { _err_resp() };
		eval { $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG) };
	}
	my $err = $@;
	like($err,   qr/REDACTED/,                    'error contains REDACTED');
	unlike($err, qr/\Q$config{key_injection}\E/,  'injection key not in error');
	diag("security error: $err") if $ENV{TEST_VERBOSE};
};

subtest 'security: SSRF via @ in host is structurally possible (document behavior)' => sub {
	# A host of "legit.com@evil.com" makes URI build https://legit.com@evil.com/...
	# which HTTP clients interpret as user=legit.com connecting to evil.com.
	# This test documents that the module trusts the caller's host value.
	# Mitigating factor: the caller who supplies host already controls the API key.
	my $ua   = StubUA->new(_ok_resp($JSON_OK));
	my $tzdb = TimeZone::TimeZoneDB->new(
		key  => $KEY,
		host => $config{host_ssrf_at},
		ua   => $ua,
	);
	$tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	my $url = $ua->last_url();
	# Caller-supplied host with @ goes through unchanged -- trust the caller
	like($url, qr{\Q$config{host_ssrf_at}\E}, 'host with @ is passed through as-is');
	diag("SSRF-candidate URL: $url") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# Context sensitivity: list vs scalar context
# ===========================================================================

subtest 'edge: get_time_zone() in list context returns single hashref' => sub {
	# Capturing in list context: ($result) = $tzdb->get_time_zone(...) must work
	my $ua   = StubUA->new(_ok_resp($JSON_OK));
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua);
	my ($result) = $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	ok(defined $result,          'list-context result is defined');
	is(ref $result, 'HASH',      'list-context result is a hashref');
};

subtest 'edge: get_time_zone() on cache-miss non-OK status returns undef in list context' => sub {
	# "return;" in list context returns an empty list; ($x) = () gives undef
	my $ua   = StubUA->new(_ok_resp($JSON_FAIL));
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua);
	my ($result) = $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	ok(!defined $result, 'non-OK status returns undef even in list context');
};

subtest 'edge: ua() getter in list context returns single object' => sub {
	# List context must return the UA object, not explode the blessed hashref
	my $ua   = GoodUA->new();
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua);
	my ($got) = $tzdb->ua();
	is($got, $ua, 'list-context getter returns the UA');
};

# ===========================================================================
# $_ clobbering checks across all public methods
# ===========================================================================

subtest 'edge: new() does not clobber $_ in caller' => sub {
	local $_ = 'new_sentinel';
	TimeZone::TimeZoneDB->new(key => $KEY);
	is($_, 'new_sentinel', 'new() did not clobber $_');
};

subtest 'edge: get_time_zone() does not clobber $_ in caller' => sub {
	my $ua   = StubUA->new(_ok_resp($JSON_OK));
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua);
	local $_ = 'gtz_sentinel';
	$tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	is($_, 'gtz_sentinel', 'get_time_zone() did not clobber $_');
};

subtest 'edge: ua() setter/getter does not clobber $_ in caller' => sub {
	my $ua   = GoodUA->new();
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua);
	local $_ = 'ua_sentinel';
	$tzdb->ua();
	is($_, 'ua_sentinel', 'ua() getter did not clobber $_');
	$tzdb->ua(GoodUA->new());
	is($_, 'ua_sentinel', 'ua() setter did not clobber $_');
};

# ---------------------------------------------------------------------------
# Tear down all mocks
# ---------------------------------------------------------------------------
restore_all();

done_testing();
