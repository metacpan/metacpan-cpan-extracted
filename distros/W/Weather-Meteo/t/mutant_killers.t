#!/usr/bin/env perl

# mutant_killers.t -- tests designed to kill surviving mutants
#
# Each subtest is named after the mutant ID it targets (from xt/mutant_*.t).
# Mutants covered (most recent stub: xt/mutant_20260601_022906.t):
#   NUM_BOUNDARY_319_17_!=  -- == 2 flipped to != 2 in weather() arg check
#   COND_INV_325_3          -- if/unless flip on tz+TIMEZONEDB_KEY guard
#   COND_INV_344_3          -- if/unless flip on logger guard (missing-args path)
#   COND_INV_366_3          -- if/unless flip on logger guard (bad-coord path)
#   COND_INV_382_3          -- if/unless flip on logger guard (bad-date-fmt path)
#   BOOL_NEGATE_410_3       -- cached value negated (!$cached) on cache hit
#   RETURN_UNDEF_410_3      -- cached value replaced with undef
#   COND_INV_512_2          -- if/unless flip on ua() setter guard
#   BOOL_NEGATE_526_2       -- ua() return value negated (!$self->{ua})
#   RETURN_UNDEF_526_2      -- ua() return value replaced with undef

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
# TestUA -- controlled LWP::UserAgent subclass; no network access.
# Spy on TestUA::get to observe every URL requested.
# ===========================================================================
{
	package TestUA;
	use parent 'LWP::UserAgent';
	our $PAYLOAD = '{}';    # default empty response

	# Returns a 200 OK response with PAYLOAD as the body
	sub get {
		my ($self, $url) = @_;
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($TestUA::PAYLOAD);
		return $r;
	}
}

# ===========================================================================
# Constants -- coordinates, dates, and expected API behaviour
# ===========================================================================

Readonly my $LAT          => '51.34';
Readonly my $LON          => '1.42';
Readonly my $DATE         => '2022-12-25';
Readonly my $PRE_1940     => '1939-01-01';
Readonly my $ALT_TZ       => 'America/New_York';
Readonly my $DEFAULT_TZ   => 'Europe/London';

# URI encodes '/' as '%2F' in query parameter values; the code only un-encodes
# commas, so timezone slashes stay percent-encoded in the final URL.
Readonly my $ALT_TZ_URL     => 'timezone=America%2FNew_York';
Readonly my $DEFAULT_TZ_URL => 'timezone=Europe%2FLondon';
Readonly my $DEFAULT_HOST => 'archive-api.open-meteo.com';

# Error message fragments that the code must produce
Readonly my $ERR_USAGE    => 'Usage: weather(latitude';
Readonly my $ERR_BAD_COORD => 'Invalid latitude/longitude format';
Readonly my $ERR_BAD_FMT  => 'Invalid date format. Expected YYYY-MM-DD';
Readonly my $ERR_UA_UNDEF => 'ua() requires a defined value';

# ===========================================================================
# %config -- variable values used across subtests
# ===========================================================================

my %config = (
	# Minimal valid API response that weather() will accept and cache
	hourly_json => '{"hourly":{"temperature_2m":[5,6,7,8,9,10,11,12,13,14,'
	             . '15,14,13,12,11,10,9,8,7,6,5,4,3,2],'
	             . '"rain":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],'
	             . '"snowfall":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],'
	             . '"weathercode":[1,1,1,2,2,2,3,3,2,1,1,1,2,2,3,3,2,2,1,1,1,2,2,1]},'
	             . '"daily":{"time":["2022-12-25"],'
	             . '"weathercode":[3],"temperature_2m_max":[15.0],'
	             . '"temperature_2m_min":[2.0],"rain_sum":[0.0],'
	             . '"snowfall_sum":[0.0],"precipitation_hours":[0.0],'
	             . '"windspeed_10m_max":[12.0],"windgusts_10m_max":[20.0]}}',

	# Cache key for the primary test coordinates with the default timezone
	cache_key   => "weather:${LAT}:${LON}:${DATE}:${DEFAULT_TZ}",

	# Sentinel value stored in the cache to verify exact identity on retrieval
	sentinel    => { hourly => { temperature_2m => [42, 43, 44] }, _test => 'sentinel' },
);

# ---------------------------------------------------------------------------
# _fresh_cache -- isolated non-global CHI cache; prevents cross-test leakage
# ---------------------------------------------------------------------------
sub _fresh_cache {
	return CHI->new(driver => 'Memory', global => 0, expires_in => '1 hour');
}

# ---------------------------------------------------------------------------
# _ua_with_mock -- mocks LWP::UserAgent::get to return given JSON (or default)
# The caller is responsible for calling restore_all() when done.
# ---------------------------------------------------------------------------
sub _ua_with_mock {
	my ($json) = @_;
	$json //= $config{hourly_json};
	my $payload = $json;
	mock 'LWP::UserAgent::get' => sub {
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($payload);
		return $r;
	};
	return LWP::UserAgent->new();
}

# ---------------------------------------------------------------------------
# _meteo -- convenience: fresh Weather::Meteo with isolated cache and mock UA
# ---------------------------------------------------------------------------
sub _meteo {
	my ($json) = @_;
	_ua_with_mock($json);
	return Weather::Meteo->new(cache => _fresh_cache());
}

# ---------------------------------------------------------------------------
# Helper location class: has latitude, longitude, and optional tz method.
# Used to exercise the two-arg positional call form of weather().
# ---------------------------------------------------------------------------
{
	package MockLocation;

	sub new       { bless {}, shift }
	sub latitude  { $LAT }
	sub longitude { $LON }
	# tz() is deliberately absent here -- see MockLocationTZ for a version with it
}

# MockLocationTZ adds a tz() method so TIMEZONEDB_KEY-gated logic fires.
{
	package MockLocationTZ;

	sub new       { bless {}, shift }
	sub latitude  { $LAT }
	sub longitude { $LON }
	sub tz        { $ALT_TZ }
}

# ===========================================================================
# MUTANT: NUM_BOUNDARY_319_17_!= (HIGH)
# Source line 319: if((scalar(@_) == 2) && ...)
# Mutant: == 2 changed to != 2
#
# Kill strategy:
#   A) Two-arg form succeeds   -- original (== 2) enters location branch,
#      mutant (!= 2) misses it and falls to Params::Get which cannot extract
#      lat/lon/date from positional args -> croaks with "Usage:"
#   B) One-arg form croaks     -- original (== 2) does NOT enter location
#      branch (1 != 2), falls to Params::Get, which returns no lat/lon/date,
#      then croaks; mutant (!= 2) DOES enter location branch with $_ [1]
#      undefined, yielding a different croak or extracting undef date
#   C) Three-arg form croaks   -- original (== 2) skips location branch (3 != 2),
#      falls to Params::Get; mutant (!= 2) ENTERS location branch (3 != 2
#      is TRUE), extracting location from $_[0] which may succeed
# ===========================================================================

# Purpose: the 2-arg positional form must succeed -- kills == -> != mutant
subtest 'NUM_BOUNDARY_319_17_!= -- two-arg location form returns data' => sub {
	my $loc   = MockLocation->new();
	my $meteo = _meteo($config{hourly_json});

	# Call the documented two-arg positional form: weather($location, $date)
	my $result = $meteo->weather($loc, $DATE);

	ok(defined($result),              'two-arg form: result is defined');
	returns_ok($result, { type => 'hashref' }, 'two-arg form: returns a hashref');
	ok(exists($result->{'hourly'}),   'two-arg form: hourly key present');

	diag("two-arg result keys: " . join(', ', sort keys %{$result}))
		if $ENV{TEST_VERBOSE};

	restore_all();
};

# Purpose: one-arg form falls to Params::Get (not the 2-arg location branch)
# Original (== 2): 1 arg -> Params::Get croaks "Usage: Params::Get->..."
# Mutant  (!= 2): 1 arg -> enters location branch, date=undef -> OUR Usage croak
# Kill: assert the error comes from Params::Get, not from our code.
subtest 'NUM_BOUNDARY_319_17_!= -- one-arg form error comes from Params::Get' => sub {
	my $loc   = MockLocation->new();
	my $meteo = Weather::Meteo->new(cache => _fresh_cache());

	# Params::Get intercepts the odd-shaped arg list and throws its own usage error
	eval { $meteo->weather($loc) };
	my $err = $@;

	ok($err, 'one-arg form throws an error');
	like($err, qr/Params::Get/, 'error comes from Params::Get (not location branch)');

	diag("one-arg error: $err") if $ENV{TEST_VERBOSE};
};

# Purpose: three-arg form falls to Params::Get (not location branch)
# Original (== 2): 3 args -> Params::Get gets odd-shaped list, croaks
# Mutant  (!= 2): 3 args -> 3!=2 is TRUE, enters location branch, extracts
#                  valid lat/lon/date, then would SUCCEED (returns data)
# Kill: assert the error comes from Params::Get, not that the call succeeded.
subtest 'NUM_BOUNDARY_319_17_!= -- three-arg form falls to Params::Get' => sub {
	my $loc   = MockLocation->new();
	# No UA mock -- if the mutant tries to proceed it will make a real HTTP call
	# or fail at the UA level, not with a Params::Get error
	my $meteo = Weather::Meteo->new(cache => _fresh_cache());

	eval { $meteo->weather($loc, $DATE, 'extra_arg') };
	my $err = $@;

	ok($err, 'three positional args throws an error');
	like($err, qr/Params::Get/, 'three-arg error comes from Params::Get (not location branch)');

	diag("three-arg error: $err") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# MUTANT: COND_INV_325_3 (MEDIUM)
# Source line 325: if($_[0]->can('tz') && $ENV{'TIMEZONEDB_KEY'}) {
# Mutant: if changed to unless
#
# Kill strategy:
#   A) When location HAS tz() AND key is set: tz appears in URL (correct);
#      mutant would SKIP tz assignment -> URL uses default tz instead
#   B) When location lacks tz(), key set: tz NOT from location (correct);
#      mutant would TRY to call tz() -> "Can't locate object method 'tz'"
#   C) When location HAS tz(), key NOT set: tz NOT from location (correct);
#      mutant would ASSIGN tz from location even without the key
# ===========================================================================

# Purpose: tz from location is used when can('tz') && TIMEZONEDB_KEY are both true
subtest 'COND_INV_325_3 -- tz used from location when key set' => sub {
	my $loc       = MockLocationTZ->new();
	my $captured  = '';

	# Spy on the URL being requested so we can verify the timezone parameter
	mock 'LWP::UserAgent::get' => sub {
		my ($ua_self, $url) = @_;
		$captured = $url;
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{hourly_json});
		return $r;
	};

	my $meteo = Weather::Meteo->new(cache => _fresh_cache());

	# Set the key so the tz-from-location branch fires
	local $ENV{TIMEZONEDB_KEY} = 'test_key_12345';
	$meteo->weather($loc, $DATE);

	# URI encodes '/' as '%2F'; match the percent-encoded form in the URL
	like($captured, qr/\Q$ALT_TZ_URL\E/, 'tz from location appears in URL (percent-encoded)');
	unlike($captured, qr/\Q$DEFAULT_TZ_URL\E/, 'default tz not used when location tz active');

	diag("captured URL: $captured") if $ENV{TEST_VERBOSE};

	restore_all();
};

# Purpose: location without tz() must not crash when key is set
subtest 'COND_INV_325_3 -- no tz method on location: falls back to default tz' => sub {
	my $loc      = MockLocation->new();
	my $captured = '';

	mock 'LWP::UserAgent::get' => sub {
		my ($ua_self, $url) = @_;
		$captured = $url;
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{hourly_json});
		return $r;
	};

	my $meteo = Weather::Meteo->new(cache => _fresh_cache());

	# Key is set, but location has no tz() -- must silently use default tz
	local $ENV{TIMEZONEDB_KEY} = 'test_key_12345';
	my $result = $meteo->weather($loc, $DATE);

	ok(defined($result), 'result defined when location has no tz method');
	like($captured, qr/\Q$DEFAULT_TZ_URL\E/, 'default tz used when location lacks tz() (percent-encoded)');

	diag("captured URL: $captured") if $ENV{TEST_VERBOSE};

	restore_all();
};

# Purpose: tz() present but no TIMEZONEDB_KEY -- default tz is used
subtest 'COND_INV_325_3 -- tz ignored when TIMEZONEDB_KEY not set' => sub {
	my $loc      = MockLocationTZ->new();
	my $captured = '';

	mock 'LWP::UserAgent::get' => sub {
		my ($ua_self, $url) = @_;
		$captured = $url;
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{hourly_json});
		return $r;
	};

	my $meteo = Weather::Meteo->new(cache => _fresh_cache());

	# Ensure key is absent
	local $ENV{TIMEZONEDB_KEY} = undef;
	delete $ENV{TIMEZONEDB_KEY};
	$meteo->weather($loc, $DATE);

	unlike($captured, qr/\Q$ALT_TZ_URL\E/, 'location tz not in URL when TIMEZONEDB_KEY absent');
	like($captured, qr/\Q$DEFAULT_TZ_URL\E/, 'default tz in URL when TIMEZONEDB_KEY absent (percent-encoded)');

	diag("captured URL: $captured") if $ENV{TEST_VERBOSE};

	restore_all();
};

# ===========================================================================
# MUTANT: COND_INV_344_3 (MEDIUM)
# Source line 344: if(my $logger = $self->{'logger'}) {
# Context: missing-args croak path in weather()
# Mutant: if changed to unless
#
# Kill strategy: the mutant would call $logger->error() when logger IS UNDEF
# (no logger case), causing "Can't call method 'error' on an undefined value"
# instead of the documented "Usage:" croak.  We verify the correct error.
# ===========================================================================

# Purpose: without a logger the Usage croak still fires correctly
subtest 'COND_INV_344_3 -- missing args croak correct without logger' => sub {
	# Construct without any logger -- $self->{logger} will be undef
	my $meteo = Weather::Meteo->new(cache => _fresh_cache());

	# Missing latitude/longitude/date must produce the Usage croak
	throws_ok(
		sub { $meteo->weather({ latitude => $LAT }) },
		qr/\Q$ERR_USAGE\E/,
		'missing-args croak produces correct Usage message (no logger)',
	);

	diag("missing-args croak ok without logger") if $ENV{TEST_VERBOSE};
};

# Purpose: the croak message fragment must not be "on an undefined value"
subtest 'COND_INV_344_3 -- error is not a null-deref on undef logger' => sub {
	my $meteo = Weather::Meteo->new(cache => _fresh_cache());

	eval { $meteo->weather({ longitude => $LON, date => $DATE }) };
	my $err = $@;

	ok($err, 'weather() died as expected');
	unlike($err, qr/on an undefined value/i,
		'error is not a null-deref -- logger guard works correctly');
	like($err, qr/\Q$ERR_USAGE\E/, 'error contains correct Usage text');

	diag("error was: $err") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# MUTANT: COND_INV_366_3 (MEDIUM)
# Source line 366: if(my $logger = $self->{'logger'}) {
# Context: bad latitude/longitude format croak in weather()
# Mutant: if changed to unless
#
# Same kill strategy as COND_INV_344_3 but for the coord-validation path.
# ===========================================================================

# Purpose: bad coords croak produces correct message without null-deref
subtest 'COND_INV_366_3 -- bad-coord croak is correct (no logger)' => sub {
	my $meteo = Weather::Meteo->new(cache => _fresh_cache());

	# Non-numeric coordinate value triggers the coord validation error
	throws_ok(
		sub { $meteo->weather({ latitude => 'not_a_number', longitude => $LON, date => $DATE }) },
		qr/\Q$ERR_BAD_COORD\E/,
		'bad-coord croak produces correct message (no logger)',
	);

	diag("bad-coord croak ok") if $ENV{TEST_VERBOSE};
};

# Purpose: confirm bad-coord error is not a null-deref on undef logger
subtest 'COND_INV_366_3 -- bad-coord error is not a null-deref' => sub {
	my $meteo = Weather::Meteo->new(cache => _fresh_cache());

	eval { $meteo->weather({ latitude => 'bad!', longitude => $LON, date => $DATE }) };
	my $err = $@;

	ok($err, 'weather() died on bad coord');
	unlike($err, qr/on an undefined value/i, 'not a null-deref');
	like($err, qr/\Q$ERR_BAD_COORD\E/, 'contains bad-coord text');

	diag("error was: $err") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# MUTANT: COND_INV_382_3 (MEDIUM)
# Source line 382: if(my $logger = $self->{'logger'}) {
# Context: bad date format croak (after strftime or year prefix passes)
# Mutant: if changed to unless
#
# Same kill strategy, this time for the date-format validation path.
# A date like '2022-1-1' passes the /^\d{4}-/ test but fails
# /^\d{4}-\d{2}-\d{2}$/ -- that triggers the logger-guarded croak.
# ===========================================================================

# Purpose: malformed date croaks with correct message (not null-deref)
subtest 'COND_INV_382_3 -- bad-format date croak is correct (no logger)' => sub {
	my $meteo = Weather::Meteo->new(cache => _fresh_cache());

	# '2022-1-1' passes the year-prefix check but fails the strict format check
	throws_ok(
		sub { $meteo->weather({ latitude => $LAT, longitude => $LON, date => '2022-1-1' }) },
		qr/\Q$ERR_BAD_FMT\E/,
		'malformed date croaks with Expected YYYY-MM-DD (no logger)',
	);

	diag("bad-fmt croak ok") if $ENV{TEST_VERBOSE};
};

# Purpose: the bad-format croak must not be a null-deref on undef logger
subtest 'COND_INV_382_3 -- bad-format error is not a null-deref' => sub {
	my $meteo = Weather::Meteo->new(cache => _fresh_cache());

	eval { $meteo->weather({ latitude => $LAT, longitude => $LON, date => '2022-1-1' }) };
	my $err = $@;

	ok($err, 'weather() died on malformed date');
	unlike($err, qr/on an undefined value/i, 'not a null-deref');
	like($err, qr/\Q$ERR_BAD_FMT\E/, 'contains Expected YYYY-MM-DD text');

	diag("error was: $err") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# MUTANT: BOOL_NEGATE_410_3 (MEDIUM)  +  RETURN_UNDEF_410_3 (LOW)
# Source line 410: return $cached;
# Mutations: !$cached (negate boolean)  OR  undef (replace with undef)
#
# Kill strategy: pre-load an exact sentinel hashref into the cache, then call
# weather() and verify the returned value is the sentinel itself -- not its
# boolean negation ('') and not undef.
# ===========================================================================

# Purpose: the cached hashref is returned as-is -- not negated, not undef
subtest 'BOOL_NEGATE_410_3 / RETURN_UNDEF_410_3 -- cache hit returns exact data' => sub {
	my $cache = _fresh_cache();

	# Pre-load a sentinel value into the cache using the documented key format
	my $expected = { hourly => { temperature_2m => [99, 88, 77] }, _marker => 'kill_mutant' };
	$cache->set($config{cache_key}, $expected);

	my $meteo = Weather::Meteo->new(cache => $cache);

	# weather() must retrieve and return the cached value unchanged
	my $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	ok(defined($result), 'cache hit: result is not undef (kills RETURN_UNDEF)');
	is(ref($result), 'HASH', 'cache hit: result is a hashref');

	# Verify it is the actual cached data, not !$cached = ''
	isnt($result, '', 'cache hit: result is not negated boolean (kills BOOL_NEGATE)');
	is($result->{'_marker'}, 'kill_mutant',
		'cache hit: sentinel marker intact -- exact cached hashref returned');

	# Verify it contains the hourly data we stored
	is_deeply(
		$result->{'hourly'}{'temperature_2m'},
		[99, 88, 77],
		'cache hit: hourly data matches pre-loaded sentinel exactly',
	);

	returns_ok($result, { type => 'hashref' }, 'cache hit: return satisfies hashref schema');

	diag("cached result marker: " . ($result->{'_marker'} // 'undef')) if $ENV{TEST_VERBOSE};
};

# Purpose: a live (non-cached) call populates the cache for a subsequent hit
subtest 'BOOL_NEGATE_410_3 -- cache round-trip: store then return exact data' => sub {
	my $cache = _fresh_cache();
	_ua_with_mock($config{hourly_json});

	my $meteo = Weather::Meteo->new(cache => $cache);

	# First call -- goes to UA, populates cache
	my $first = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	ok(defined($first), 'first call returns defined value');
	returns_ok($first, { type => 'hashref' }, 'first call returns hashref');

	# Second call -- must hit cache and return same hashref content
	restore_all();    # Remove UA mock so any network attempt would die
	my $second = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	ok(defined($second), 'second call (cache hit) returns defined value (kills RETURN_UNDEF)');
	is_deeply($second, $first, 'second call returns same data as first (kills BOOL_NEGATE)');

	diag("round-trip ok") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# MUTANT: COND_INV_512_2 (MEDIUM)
# Source line 512: if (@_)  in ua()
# Mutant: if changed to unless
#
# Kill strategy:
#   Getter form ua() -- original skips setter block (no @_), returns ua;
#     mutant enters setter block (unless @_ when empty is TRUE), calls
#     Carp::croak('ua() requires a defined value') -> crashes on getter
#   Setter form ua($new_ua) -- original enters setter, updates $self->{ua};
#     mutant skips setter block, ua is not updated -> returns old ua
# ===========================================================================

# Purpose: ua() getter returns a valid object and does NOT croak
subtest 'COND_INV_512_2 -- ua() getter returns ua without croak' => sub {
	my $meteo = Weather::Meteo->new();

	# Getter must not throw "requires a defined value" (the mutant would throw it)
	my $ua;
	lives_ok(
		sub { $ua = $meteo->ua() },
		'ua() getter does not croak',
	);

	ok(defined($ua), 'ua() getter returns a defined value');
	ok(ref($ua),     'ua() getter returns a reference');
	ok($ua->can('get'), 'ua() getter returns object that can get()');

	returns_ok($ua, { type => 'object' }, 'ua() satisfies object schema');

	diag("ua class: " . ref($ua)) if $ENV{TEST_VERBOSE};
};

# Purpose: ua($new_ua) setter installs the new agent -- mutant skips the setter
subtest 'COND_INV_512_2 -- ua($new_ua) setter updates stored agent' => sub {
	my $meteo  = Weather::Meteo->new();
	my $old_ua = $meteo->ua();

	# Create a fresh LWP::UserAgent to replace the current one
	my $new_ua = LWP::UserAgent->new(agent => 'MutantKillerAgent/1.0');

	# Setter must store the new agent
	$meteo->ua($new_ua);
	my $stored = $meteo->ua();

	# The stored ua must be the new one, not the original
	isnt($stored, $old_ua, 'setter replaced the old ua');
	is($stored, $new_ua, 'ua() returns the new ua after setter call');

	diag("new ua agent: " . $new_ua->agent()) if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# MUTANT: BOOL_NEGATE_526_2 (from older stub mutant_20260601_014930.t)
# MUTANT: RETURN_UNDEF_526_2
# Source line 526: return $self->{ua};
# Mutations: !$self->{ua}  OR  undef
#
# Kill strategy: verify ua() returns the actual UA object, not its negation
# (which would be '' for any ref) and not undef.
# ===========================================================================

# Purpose: ua() return value is the actual object, not negated or undef
subtest 'BOOL_NEGATE_526_2 / RETURN_UNDEF_526_2 -- ua() returns actual object' => sub {
	my $meteo = Weather::Meteo->new();

	my $ua = $meteo->ua();

	# Negated ref gives ''; undef is undef -- both are wrong
	ok(defined($ua), 'ua() does not return undef (kills RETURN_UNDEF)');
	ok(ref($ua),     'ua() is a reference, not a negated empty string (kills BOOL_NEGATE)');
	ok($ua->can('get'), 'ua() return value understands get()');

	returns_ok($ua, { type => 'object' }, 'ua() satisfies object schema');

	diag("ua() returned: " . ref($ua)) if $ENV{TEST_VERBOSE};
};

# Purpose: after ua() setter, the getter returns that exact object (ref identity)
subtest 'BOOL_NEGATE_526_2 -- ua() returns identity of stored object' => sub {
	my $meteo   = Weather::Meteo->new();
	my $new_ua  = LWP::UserAgent->new(agent => 'IdentityCheckAgent/1.0');

	$meteo->ua($new_ua);
	my $returned = $meteo->ua();

	# The returned value must BE the object stored, not !$obj (which is '')
	is($returned, $new_ua, 'ua() returns exact stored object identity');
	isnt($returned, '', 'ua() return is not a negated boolean');

	returns_ok($returned, { type => 'object' }, 'returned value is an object');

	diag("returned identity ok") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# Additional mutant-killing tests derived from analysis of the source code
# ===========================================================================

# Purpose: two-arg form with a real location correctly extracts lat/lon
# This double-checks the boundary by asserting the URL contains the coordinates
subtest 'two-arg form embeds correct lat/lon in request URL' => sub {
	my $loc      = MockLocation->new();
	my $captured = '';

	mock 'LWP::UserAgent::get' => sub {
		my ($ua_self, $url) = @_;
		$captured = $url;
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{hourly_json});
		return $r;
	};

	my $meteo = Weather::Meteo->new(cache => _fresh_cache());
	$meteo->weather($loc, $DATE);

	like($captured, qr/latitude=\Q$LAT\E/,  'two-arg: correct latitude in URL');
	like($captured, qr/longitude=\Q$LON\E/, 'two-arg: correct longitude in URL');
	like($captured, qr/\Q$DATE\E/,          'two-arg: date appears in URL');

	diag("captured URL: $captured") if $ENV{TEST_VERBOSE};

	restore_all();
};

# Purpose: cache hit must not re-invoke the UA -- proves the cache return is real
subtest 'cache hit: UA is not called a second time' => sub {
	my $cache    = _fresh_cache();
	my $ua_calls = 0;

	mock 'LWP::UserAgent::get' => sub {
		$ua_calls++;
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{hourly_json});
		return $r;
	};

	my $meteo = Weather::Meteo->new(cache => $cache);

	# First call populates the cache
	$meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });
	my $after_first = $ua_calls;

	# Second call must hit cache; UA must not be called again
	my $result2 = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });
	my $after_second = $ua_calls;

	is($after_first, 1, 'UA called exactly once for first request');
	is($after_second, 1, 'UA not called again on cache hit');
	ok(defined($result2), 'cache hit returns defined result');

	restore_all();
};

# Purpose: getter/setter round-trip -- ua() setter stores, ua() getter retrieves
subtest 'ua() setter/getter round-trip is symmetric' => sub {
	my $meteo    = Weather::Meteo->new();
	my $custom   = LWP::UserAgent->new(agent => 'RoundTripUA/1.0');

	# Store and retrieve
	$meteo->ua($custom);
	my $retrieved = $meteo->ua();

	is($retrieved, $custom, 'ua() round-trip: retrieved same object as stored');
	ok($retrieved->can('get'), 'retrieved ua can get()');

	diag("round-trip agent: " . $retrieved->agent()) if $ENV{TEST_VERBOSE};
};

done_testing();
