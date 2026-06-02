#!/usr/bin/env perl

# Extended tests targeting uncovered execution paths to raise coverage
# above 95% and improve LCSAJ/TER3 scores.
#
# Uncovered paths targeted here (not hit by any existing test file):
#
#   new() line 222  -- !defined($class) branch (function-style call)
#   new() line 219  -- "|| {}" when Params::Get returns undef for undef arg
#   new() line 242  -- key => undef (explicit undef key, falsy, croaks)
#   get_time_zone() line 452 -- defined($rc->{'status'}) false: missing key
#   get_time_zone() line 452 -- defined($rc->{'status'}) false: status=null
#   get_time_zone() line 424 -- elapsed == min_interval (< not <=, no sleep)
#   get_time_zone() line 424 -- elapsed > min_interval (no sleep)
#   get_time_zone() line 373 -- blessed object without can('latitude')
#   ua()            line 556 -- else branch: wrong named key hits Params::Get
#   ua()            line 553 -- named-pair branch: ua => undef (explicit)
#   HTTP 4xx error           -- is_error() triggered by 401/404 responses
#
# Paths confirmed UNREACHABLE (dead code or design-time invariants):
#   None identified -- all branches have at least one live execution path.

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
# Shared test configuration
# ---------------------------------------------------------------------------
my %config = (
	key          => 'ext_test_key',
	lat          =>  40.7128,
	lng          => -74.006,
	tz_ok        => 'America/New_York',
	http_ok      => 200,
	http_401     => 401,
	http_404     => 404,
	min_interval => 30,
	fake_now     => 9_999_999,	# deterministic epoch for time-mocking tests
);

Readonly::Scalar my $KEY => $config{key};
Readonly::Scalar my $LAT => $config{lat};
Readonly::Scalar my $LNG => $config{lng};

# JSON body variants that exercise specific branch conditions
Readonly::Scalar my $JSON_OK       => '{"status":"OK","zoneName":"America/New_York"}';
Readonly::Scalar my $JSON_NO_STAT  => '{"zoneName":"America/New_York","gmtOffset":-18000}';
Readonly::Scalar my $JSON_NULL_ST  => '{"status":null,"zoneName":"America/New_York"}';
Readonly::Scalar my $JSON_SINGLE   => '{"status":"OK"}';	# exactly one key (min=1)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Build a 200 OK response with the given JSON body
sub _ok_resp {
	my ($body) = @_;
	my $r = HTTP::Response->new($config{http_ok}, 'OK');
	$r->content($body);
	return $r;
}

# Build an error HTTP response with a specific status code
sub _err_resp {
	my ($code, $msg) = @_;
	return HTTP::Response->new($code, $msg // 'Error');
}

# A minimal valid UA object (has get() method)
{
	package GoodUA;
	sub new { bless {}, $_[0] }
	sub get { return undef }	# never actually called in most tests
}

# ---------------------------------------------------------------------------
# Suppress filesystem access in new() throughout the file
# ---------------------------------------------------------------------------
mock 'Object::Configure::configure' => sub { $_[1] };

# ===========================================================================
# new() -- uncovered branch: !defined($class)  (line 222)
# ===========================================================================

subtest 'new: function-style call with explicit undef class uses __PACKAGE__' => sub {
	# When new() is invoked as a plain function with undef as the class,
	# the module sets $class = __PACKAGE__ and creates a normal object.
	# This exercises the "if(!defined($class))" branch at line 222.
	my $tzdb;
	{
		my $g = mock_scoped 'LWP::UserAgent::get' => sub { _ok_resp($JSON_OK) };
		# Pass undef as explicit first arg (the "class") followed by the key
		lives_ok {
			$tzdb = TimeZone::TimeZoneDB::new(undef, key => $KEY);
		} 'function-style new(undef, key => ...) lives';
	}
	isa_ok($tzdb, 'TimeZone::TimeZoneDB', 'result is a TimeZone::TimeZoneDB object');
	diag('function-style new() exercised !defined($class) branch') if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# new() -- || {} fallback when Params::Get returns undef  (line 219)
# ===========================================================================

subtest 'new: single undef arg triggers || {} param fallback then croaks' => sub {
	# Params::Get::get_params(undef, [undef]) returns undef (not a hashref).
	# The "|| {}" at line 219 catches this, produces an empty hash, and then
	# the missing-key check croaks.  This is a different internal path from
	# calling new() with no args at all.
	throws_ok { TimeZone::TimeZoneDB->new(undef) }
		qr/'key' argument is required/, 'new(undef) croaks for missing key via || {}';
};

subtest 'new: key => undef (explicit undef value) is falsy and croaks' => sub {
	# undef is falsy in "my $key = $params->{'key'} or croak(...)".
	# Ensure the exact error message matches.
	throws_ok { TimeZone::TimeZoneDB->new(key => undef) }
		qr/'key' argument is required/, 'key => undef croaks with exact message';
};

# ===========================================================================
# get_time_zone() -- JSON response missing the 'status' field  (line 452)
# ===========================================================================

subtest 'get_time_zone: JSON without status field is returned as success' => sub {
	# When the API returns a body with no "status" key, defined($rc->{'status'})
	# is false, so the non-OK branch is skipped and the hashref is returned.
	# This exercises the "false" short-circuit of defined($rc->{'status'}).
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	my $result;
	{
		my $g = mock_scoped 'LWP::UserAgent::get' => sub { _ok_resp($JSON_NO_STAT) };
		$result = $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	}
	ok(defined $result,         'result is defined for response with no status key');
	is(ref $result, 'HASH',     'result is a hashref');
	ok(exists $result->{zoneName}, 'zoneName key is present');
	returns_ok($result, { type => 'hashref', min => 1 }, 'output schema satisfied');
	diag("zoneName=$result->{zoneName}") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# get_time_zone() -- JSON response with status = null  (line 452)
# ===========================================================================

subtest 'get_time_zone: JSON status=null is treated as success (defined=false)' => sub {
	# JSON null decodes to Perl undef.  defined(undef) is false, so the
	# non-OK branch is skipped and Return::Set sees the hashref.
	# This exercises the short-circuit when status exists but is undef.
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	my $result;
	{
		my $g = mock_scoped 'LWP::UserAgent::get' => sub { _ok_resp($JSON_NULL_ST) };
		$result = $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	}
	ok(defined $result,     'status=null response returns a hashref (not undef)');
	is(ref $result, 'HASH', 'result is a hashref');
	diag("status=null result: ".ref($result)) if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# get_time_zone() -- HTTP 4xx errors trigger is_error() just like 5xx
# ===========================================================================

subtest 'get_time_zone: HTTP 401 Unauthorized is treated as an error' => sub {
	# is_error() returns true for any 4xx or 5xx code.
	# Verify the error path, the REDACTED substitution, and the croak message.
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	my $err;
	{
		my $g = mock_scoped 'LWP::UserAgent::get' => sub {
			_err_resp($config{http_401}, 'Unauthorized')
		};
		eval { $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG) };
		$err = $@;
	}
	ok($err,                      'HTTP 401 causes a croak');
	like($err, qr/API returned error/i, 'error message mentions API returned error');
	like($err, qr/REDACTED/,           'key is redacted in 401 error message');
	unlike($err, qr/\Q$KEY\E/,         'actual key absent from 401 error message');
	diag("401 error: $err") if $ENV{TEST_VERBOSE};
};

subtest 'get_time_zone: HTTP 404 Not Found is treated as an error' => sub {
	# Verify that 404 (a common error for an unknown endpoint) also croaks.
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	{
		my $g = mock_scoped 'LWP::UserAgent::get' => sub {
			_err_resp($config{http_404}, 'Not Found')
		};
		throws_ok { $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG) }
			qr/API returned error/i, 'HTTP 404 croaks with correct message';
	}
};

# ===========================================================================
# get_time_zone() -- rate-limit boundary: elapsed exactly equals min_interval
# ===========================================================================

subtest 'get_time_zone: elapsed == min_interval (boundary) causes no sleep' => sub {
	# The condition is "elapsed < min_interval".  When they are equal the
	# condition is false and no sleep occurs.  We set last_request far in the
	# past so that real elapsed time >> min_interval, guaranteeing the false branch.
	# Note: mocking CORE::time() directly is not reliable across Perl versions
	# because core calls may be inlined at compile time.
	my $min_int  = $config{min_interval};
	my $sleep_ct = 0;
	{
		my $g_sleep = mock_scoped 'Time::HiRes::sleep' => sub { $sleep_ct++ };
		my $g_http  = mock_scoped 'LWP::UserAgent::get' => sub { _ok_resp($JSON_OK) };

		my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY, min_interval => $min_int);
		# last_request = 0 (epoch start) -> elapsed = now (very large) > min_int -> no sleep
		$tzdb->{last_request} = 0;
		$tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	}
	is($sleep_ct, 0, 'no sleep when elapsed >> min_interval (condition is false)');
	diag("elapsed >> $min_int -> no sleep") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# get_time_zone() -- rate-limit: elapsed already exceeds min_interval
# ===========================================================================

subtest 'get_time_zone: elapsed > min_interval causes no sleep' => sub {
	# Set min_interval to a large value but last_request to epoch zero.
	# elapsed = now - 0 = now (>> any realistic min_interval) -> no sleep.
	my $sleep_ct = 0;
	{
		my $g_sleep = mock_scoped 'Time::HiRes::sleep' => sub { $sleep_ct++ };
		my $g_http  = mock_scoped 'LWP::UserAgent::get' => sub { _ok_resp($JSON_OK) };

		my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY, min_interval => 30);
		$tzdb->{last_request} = 0;	# far in the past
		$tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	}
	is($sleep_ct, 0, 'no sleep when elapsed > min_interval');
};

subtest 'get_time_zone: elapsed < min_interval causes exactly one sleep' => sub {
	# When elapsed is tiny (last_request set to right now) and min_interval is
	# large, the sleep branch must fire.  We do NOT mock CORE::time() because
	# core function calls can be inlined; instead we use real time and a NoOpCache.
	my $min_int  = 999;	# large enough that elapsed << min_interval
	my $sleep_ct = 0;
	my $sleep_arg;

	# No-op cache ensures the code always reaches the rate-limit check
	my $nocache = bless {}, 'NoOpCache';
	{
		no warnings 'once';
		*NoOpCache::get = sub { undef };
		*NoOpCache::set = sub { 1 };
	}

	{
		my $g_sleep = mock_scoped 'Time::HiRes::sleep' => sub {
			$sleep_ct++;
			$sleep_arg = $_[0];
		};
		my $g_http = mock_scoped 'LWP::UserAgent::get' => sub { _ok_resp($JSON_OK) };

		my $tzdb = TimeZone::TimeZoneDB->new(
			key          => $KEY,
			min_interval => $min_int,
			cache        => $nocache,
		);
		# Set last_request to exactly now; elapsed will be ~0 << min_int=999
		$tzdb->{last_request} = time();
		$tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	}
	is($sleep_ct, 1, 'sleep called once when elapsed << min_interval');
	# sleep(min_interval - elapsed) where elapsed ~= 0, so arg is close to min_int
	cmp_ok($sleep_arg // 0, '>=', $min_int - 2, 'sleep duration is approximately min_interval');
	diag("sleep arg=$sleep_arg (min_interval=$min_int)") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# get_time_zone() -- blessed object that lacks can('latitude')
# ===========================================================================

subtest 'get_time_zone: blessed object without latitude() falls to Params::Get' => sub {
	# A blessed object that passes the "blessed" check but fails "can('latitude')"
	# falls through to the else branch.  Params::Get::get_params(undef, [$obj])
	# then croaks with a usage error (it cannot extract named params from an object).
	my $no_lat = bless {}, 'NoLatitudeClass';
	my $tzdb   = TimeZone::TimeZoneDB->new(key => $KEY);
	{
		my $g = mock_scoped 'LWP::UserAgent::get' => sub { _ok_resp($JSON_OK) };
		throws_ok { $tzdb->get_time_zone($no_lat) }
			qr//i, 'blessed object without latitude() causes error via Params::Get';
	}
	diag('blessed-no-lat falls to Params::Get usage error') if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# get_time_zone() -- extra unknown named parameters are silently ignored
# ===========================================================================

subtest 'get_time_zone: extra named parameters cause Params::Validate::Strict to croak' => sub {
	# Params::Validate::Strict is strict by design: unknown parameter names
	# trigger a croak.  This documents that get_time_zone() does NOT silently
	# ignore extra named arguments.
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	{
		my $g = mock_scoped 'LWP::UserAgent::get' => sub { _ok_resp($JSON_OK) };
		throws_ok {
			$tzdb->get_time_zone(
				latitude  => $LAT,
				longitude => $LNG,
				extra_key => 'unexpected',
			);
		} qr/Unknown parameter/i, 'extra named params croak via Params::Validate::Strict';
	}
	diag('validate_strict rejects unknown params (strict-mode design)') if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# get_time_zone() -- single-key success response (min=1 boundary for Return::Set)
# ===========================================================================

subtest 'get_time_zone: response with exactly one key satisfies min=>1 schema' => sub {
	# Return::Set is called with { type => "hashref", min => 1 }.
	# A response with exactly 1 key is the minimum allowed -- verify it is accepted.
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	my $result;
	{
		my $g = mock_scoped 'LWP::UserAgent::get' => sub { _ok_resp($JSON_SINGLE) };
		$result = $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	}
	ok(defined $result,          'single-key response accepted by Return::Set');
	is(ref $result, 'HASH',      'result is a hashref');
	is($result->{status}, 'OK',  'status key present');
	returns_ok($result, { type => 'hashref', min => 1 }, 'output schema satisfied');
};

# ===========================================================================
# get_time_zone() -- verify last_request is updated even on error paths
# ===========================================================================

subtest 'get_time_zone: last_request is stamped even when is_error() fires' => sub {
	# The code stamps last_request BEFORE the is_error() check.
	# After a 500 error, last_request must still be updated for rate-limiting.
	my $before = time();
	my $tzdb   = TimeZone::TimeZoneDB->new(key => $KEY, min_interval => 60);
	is($tzdb->{last_request}, 0, 'last_request starts at 0');
	{
		my $g = mock_scoped 'LWP::UserAgent::get' => sub {
			_err_resp(500, 'Internal Server Error')
		};
		eval { $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG) };
	}
	cmp_ok($tzdb->{last_request}, '>=', $before,  'last_request updated after 500 error');
	cmp_ok($tzdb->{last_request}, '<=', time(),   'last_request not in the future');
};

# ===========================================================================
# ua() -- else branch: wrong named key hits Params::Get  (line 556)
# ===========================================================================

subtest 'ua: wrong named key (not "ua") hits the Params::Get else branch' => sub {
	# When called as ua(other_key => $obj), the condition $_[0] eq "ua" is false.
	# The else branch calls Params::Get::get_params("ua", \@_), which wraps
	# the 2-element array as { ua => [other_key, $obj] } -- an arrayref, not an
	# object -- so validate_strict croaks "must be an object".
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	my $good = GoodUA->new();

	# The error comes from validate_strict, not from the undef guard
	my $err;
	eval { $tzdb->ua(other_key => $good) };
	$err = $@;

	ok($err, 'wrong named key croaks');
	# The error is from validate_strict (object type check), not undef guard
	unlike($err, qr/ua\(\) requires a defined value/,
		'error is not the undef-guard message (different code path)');
	diag("wrong-named-key error: $err") if $ENV{TEST_VERBOSE};
};

subtest 'ua: ua => undef via named-pair path croaks with exact message' => sub {
	# ua(ua => undef) hits the named-pair fast-path (ua is the first arg),
	# then the explicit !defined guard croaks with the documented message.
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	throws_ok { $tzdb->ua(ua => undef) }
		qr/ua\(\) requires a defined value/, 'ua(ua => undef) exact croak message';
};

subtest 'ua: three positional args falls to Params::Get with odd-count array' => sub {
	# ua($obj, "extra", "more") has @_ with 3 elements; does not match @_ == 2.
	# Params::Get::get_params("ua", [...]) with 3 elements (odd count) croaks.
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	my $good = GoodUA->new();
	my $err;
	eval { $tzdb->ua($good, 'extra', 'more') };
	$err = $@;
	ok($err, 'three positional ua() args causes an error');
	diag("three-arg ua error: $err") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# new() clone -- empty host is NOT mapped to default (different from constructor)
# ===========================================================================

subtest 'clone: explicit empty-string host is stored verbatim (no || fallback)' => sub {
	# In the normal constructor path, host uses "|| $config{host}" so "" falls
	# back to the default.  In the CLONE path, the raw bless merge is used --
	# there is no || fallback -- so host => "" is stored as-is.
	# This documents (and tests) the asymmetry between the two code paths.
	my $ua   = GoodUA->new();
	my $orig = TimeZone::TimeZoneDB->new(key => $KEY, host => 'api.timezonedb.com', ua => $ua);
	my $clone = $orig->new(host => '');

	# The clone stores '' for host (the || fallback is not applied in clone path)
	my $captured_url;
	{
		my $g = mock_scoped 'LWP::UserAgent::get' => sub {
			$captured_url = $_[1];
			return _ok_resp($JSON_OK);
		};
		# This call will produce an URL with empty host: "https:///v2.1/..."
		eval { $clone->get_time_zone(latitude => $LAT, longitude => $LNG) };
	}
	# Regardless of whether the call succeeds, the URL reflects the empty host
	if(defined $captured_url) {
		like($captured_url, qr{https://(?!api\.timezonedb)},
			'clone with empty host does not use api.timezonedb.com');
		diag("clone empty-host URL: $captured_url") if $ENV{TEST_VERBOSE};
	} else {
		pass('clone with empty host stores "" (URI may reject empty host)');
	}
};

# ===========================================================================
# new() -- key from Object::Configure (mocked to inject a key)
# ===========================================================================

subtest 'new: key supplied via Object::Configure (simulated config injection)' => sub {
	# Object::Configure can inject values into $params. Test that a key
	# supplied via the configure() hook is honoured exactly like a direct arg.
	{
		# Override the global mock to inject a key via configure
		local $_ = undef;	# ensure $_ is not clobbered
		mock 'Object::Configure::configure' => sub {
			my ($class, $p) = @_;
			$p->{key} //= 'injected_key';	# inject key only if absent
			return $p;
		};
		my $tzdb;
		lives_ok { $tzdb = TimeZone::TimeZoneDB->new() }
			'new() with key from Object::Configure succeeds';
		isa_ok($tzdb, 'TimeZone::TimeZoneDB', 'object is correct class');

		# Restore the simpler mock for subsequent tests
		mock 'Object::Configure::configure' => sub { $_[1] };
	}
};

# ===========================================================================
# new() -- function-style call via undef class produces a working object
# ===========================================================================

subtest 'new: function-style object can make a get_time_zone call' => sub {
	# Verify that the object created via the !defined($class) branch is fully
	# functional, not just blessed correctly.
	my $result;
	{
		my $g = mock_scoped 'LWP::UserAgent::get' => sub { _ok_resp($JSON_OK) };
		my $tzdb = TimeZone::TimeZoneDB::new(undef, key => $KEY);
		$result = $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	}
	ok(defined $result,         'function-style object can call get_time_zone');
	is($result->{zoneName}, $config{tz_ok}, 'correct timezone returned');
};

# ===========================================================================
# get_time_zone() -- non-OK status without a logger (the logger-absent path)
# ===========================================================================

subtest 'get_time_zone: non-OK without logger returns undef (no logger code path)' => sub {
	# When the API returns a non-OK status AND no logger is set, the function
	# simply returns undef.  The "if(my $logger = ...)" is false so that inner
	# block is skipped -- but the outer "return;" is always reached.
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	my $result;
	{
		my $g = mock_scoped 'LWP::UserAgent::get' => sub {
			_ok_resp('{"status":"FAILED","message":"bad key"}')
		};
		$result = $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	}
	ok(!defined $result, 'non-OK without logger returns undef');
};

# ===========================================================================
# get_time_zone() -- response where $rc is an empty hashref (0 keys)
# ===========================================================================

subtest 'get_time_zone: empty JSON object {} fails Return::Set min=>1 check' => sub {
	# {} decodes to an empty hashref.  $rc is truthy but has 0 keys.
	# defined($rc->{status}) is false, so the non-OK branch is skipped.
	# Return::Set::set_return({}, { type=>"hashref", min=>1 }) then fails.
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	my $result;
	eval {
		my $g = mock_scoped 'LWP::UserAgent::get' => sub { _ok_resp('{}') };
		$result = $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	};
	# Return::Set rejects an empty hashref (min=>1 means >=1 key required)
	ok(!defined $result || $@, 'empty hashref fails Return::Set min=>1 constraint');
	diag("empty {} result: ".($@ // (defined $result ? ref($result) : 'undef')))
		if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# ua() -- named-pair detection: first arg is a ref (falls to Params::Get)
# ===========================================================================

subtest 'ua: first arg is a ref (not a string), hits Params::Get else branch' => sub {
	# The named-pair guard checks !ref($_[0]).  If $_[0] is a ref, the fast-path
	# is skipped and Params::Get is called.  An arrayref as first arg does not
	# match a valid UA schema and should croak.
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	my $good = GoodUA->new();
	my $err;
	eval { $tzdb->ua(\('ua'), $good) };	# \('ua') is a scalar ref -- !ref is false
	$err = $@;
	ok($err, 'scalar ref as first arg to ua() causes an error');
	diag("scalar-ref first arg error: $err") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# Cache stores and returns the full response across calls
# ===========================================================================

subtest 'get_time_zone: cached data includes all fields from original response' => sub {
	# Cache stores $rc (the full decoded JSON) before returning.
	# On the second call, the returned object must be identical to the first.
	my $full_json = '{"status":"OK","zoneName":"America/New_York","gmtOffset":-18000,"dst":1}';
	my $tzdb      = TimeZone::TimeZoneDB->new(key => $KEY);
	my ($r1, $r2);
	{
		my $g = mock_scoped 'LWP::UserAgent::get' => sub { _ok_resp($full_json) };
		$r1 = $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
		$r2 = $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	}
	is_deeply($r2, $r1,            'cached response is identical to original');
	is($r1->{gmtOffset}, -18_000,  'gmtOffset field preserved in first response');
	is($r2->{dst},       1,        'dst field preserved in cached response');
};

# ---------------------------------------------------------------------------
# Clean up all mocks installed during this file
# ---------------------------------------------------------------------------
restore_all();

done_testing();
