#!/usr/bin/env perl

# edge_cases.t -- destructive and pathological boundary tests for Weather::Meteo
#
# Strategy: pass every kind of broken, empty, extreme, or unexpected value into
# each public method and verify the module handles it safely.  Where the code
# SHOULD die/croak, verify the exact error fragment.  Where it SHOULD survive,
# verify no unhandled exception escapes and the return value contract is met.

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
# Constants -- baseline valid values used to isolate each broken dimension
# ---------------------------------------------------------------------------
Readonly my $LAT          => '51.34';
Readonly my $LON          => '1.42';
Readonly my $DATE         => '2022-12-25';
Readonly my $DEFAULT_HOST => 'archive-api.open-meteo.com';
Readonly my $FIRST_YEAR   => 1940;

# Exact error fragments tested via throws_ok / warning_like
Readonly my $ERR_USAGE     => 'Usage: weather(latitude';
Readonly my $ERR_BAD_COORD => 'Invalid latitude/longitude format';
Readonly my $ERR_BAD_FMT   => 'Invalid date format. Expected YYYY-MM-DD';
Readonly my $ERR_UA_UNDEF  => 'requires a defined value';
Readonly my $ERR_UA_GETMETHOD => 'must be an object that understands the get method';
Readonly my $ERR_BAD_RESP  => 'did not return a valid HTTP response';

# ---------------------------------------------------------------------------
# %config -- everything that is not a constant
# ---------------------------------------------------------------------------
my %config = (
	# Minimal valid JSON that makes weather() return a defined hashref
	ok_json      => '{"hourly":{"temperature_2m":[1,2,3],"rain":[0,0,0],'
	             .  '"snowfall":[0,0,0],"weathercode":[1,1,1]}}',

	# Huge string used to bomb-test coordinate and date parsing
	long_string  => ('x' x 1_000),

	custom_host  => 'edge.example.com',
);

# ---------------------------------------------------------------------------
# _fresh_cache -- isolated non-global cache; prevents cross-subtest leakage
# ---------------------------------------------------------------------------
sub _fresh_cache {
	return CHI->new(driver => 'Memory', global => 0, expires_in => '1 hour');
}

# ---------------------------------------------------------------------------
# _mock_ok -- makes LWP::UserAgent::get return a valid response with ok_json.
# Always call restore_all() at the end of the subtest that uses this.
# ---------------------------------------------------------------------------
sub _mock_ok {
	mock 'LWP::UserAgent::get' => sub {
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{ok_json});
		return $r;
	};
}

# ---------------------------------------------------------------------------
# _mock_return -- makes LWP::UserAgent::get return an arbitrary value.
# Used to test how the module handles pathological UA responses.
# ---------------------------------------------------------------------------
sub _mock_return {
	my ($val) = @_;
	mock 'LWP::UserAgent::get' => sub { $val };
}

# ---------------------------------------------------------------------------
# _mock_json -- makes UA::get return a 200 response with the given body.
# ---------------------------------------------------------------------------
sub _mock_json {
	my ($body) = @_;
	mock 'LWP::UserAgent::get' => sub {
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($body) if defined $body;
		return $r;
	};
}

# ===========================================================================
# new() -- edge cases for constructor arguments
# ===========================================================================

# Purpose: host='' (empty string) must fall back to the documented default.
subtest 'new(host => "") falls back to default host' => sub {
	_mock_ok();
	my $captured = '';
	mock 'LWP::UserAgent::get' => sub {
		my ($self_ua, $url) = @_;
		$captured = $url;
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{ok_json});
		return $r;
	};

	my $meteo = Weather::Meteo->new(host => '', cache => _fresh_cache());
	$meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	like($captured, qr/\Q$DEFAULT_HOST\E/, 'empty host falls back to default');
	restore_all();
	diag("url=$captured") if $ENV{TEST_VERBOSE};
};

# Purpose: host=0 (numeric zero, false in boolean context) must also fall back.
subtest 'new(host => 0) falls back to default host' => sub {
	my $captured = '';
	mock 'LWP::UserAgent::get' => sub {
		my ($self_ua, $url) = @_;
		$captured = $url;
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{ok_json});
		return $r;
	};

	my $meteo = Weather::Meteo->new(host => 0, cache => _fresh_cache());
	$meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	like($captured, qr/\Q$DEFAULT_HOST\E/, 'zero host falls back to default');
	restore_all();
};

# Purpose: host=undef must fall back silently to the default.
subtest 'new(host => undef) falls back to default host' => sub {
	my $captured = '';
	mock 'LWP::UserAgent::get' => sub {
		my ($self_ua, $url) = @_;
		$captured = $url;
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{ok_json});
		return $r;
	};

	my $meteo = Weather::Meteo->new(host => undef, cache => _fresh_cache());
	$meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	like($captured, qr/\Q$DEFAULT_HOST\E/, 'undef host falls back to default');
	restore_all();
};

# Purpose: negative min_interval is stored and must not trigger any sleep.
subtest 'new(min_interval => -1) does not cause sleep' => sub {
	_mock_ok();

	# A negative interval means elapsed will never be less than it
	my $meteo = Weather::Meteo->new(min_interval => -1, cache => _fresh_cache());
	isa_ok($meteo, 'Weather::Meteo', 'new() with min_interval=-1 succeeds');

	# Two calls should not invoke Time::HiRes::sleep
	my $slept = 0;
	mock 'Time::HiRes::sleep' => sub { $slept++ };
	$meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE        });
	$meteo->weather({ latitude => $LAT, longitude => $LON, date => '2022-12-26' });

	cmp_ok($slept, '==', 0, 'no sleep with min_interval=-1');
	restore_all();
};

# Purpose: min_interval=undef must be silently treated as 0 (no rate limiting).
subtest 'new(min_interval => undef) treated as 0' => sub {
	my $meteo = Weather::Meteo->new(min_interval => undef);
	isa_ok($meteo, 'Weather::Meteo', 'new() with min_interval=undef succeeds');
	diag('min_interval=undef ok') if $ENV{TEST_VERBOSE};
};

# Purpose: min_interval='' (empty string) must also be silently treated as 0.
subtest 'new(min_interval => "") treated as 0' => sub {
	my $meteo = Weather::Meteo->new(min_interval => '');
	isa_ok($meteo, 'Weather::Meteo', 'new() with min_interval="" succeeds');
};

# ===========================================================================
# weather() -- coordinate boundary and pathological values
# ===========================================================================

# Purpose: latitude=0 and longitude=0 (the null island) are valid coordinates.
# The module must proceed to the API, not croak.
subtest 'weather() -- lat=0, lon=0 (null island) is valid' => sub {
	_mock_ok();
	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $result = $meteo->weather({ latitude => 0, longitude => 0, date => $DATE });

	ok(defined($result), 'lat=0 lon=0: result defined');
	ok(exists($result->{'hourly'}), 'lat=0 lon=0: hourly key present');

	restore_all();
	diag('null island ok') if $ENV{TEST_VERBOSE};
};

# Purpose: string '0' coordinates must also be accepted (same boundary).
subtest 'weather() -- lat="0", lon="0" (string zeros) are valid' => sub {
	_mock_ok();
	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $result = $meteo->weather({ latitude => '0', longitude => '0', date => $DATE });

	ok(defined($result), 'string-zero lat/lon: result defined');
	restore_all();
};

# Purpose: '+51.34' (explicit plus sign) must croak -- the sign is not normalised.
subtest 'weather() -- lat="+51.34" croaks with coord message' => sub {
	my $meteo = Weather::Meteo->new();

	throws_ok { $meteo->weather({ latitude => '+51.34', longitude => $LON, date => $DATE }) }
		qr/\Q$ERR_BAD_COORD\E/,
		'plus-sign latitude: croak contains coord message';

	diag("err fragment: $ERR_BAD_COORD") if $ENV{TEST_VERBOSE};
};

# Purpose: a leading space makes the coordinate non-numeric -- must croak.
subtest 'weather() -- lat=" 51.34" (leading space) croaks' => sub {
	my $meteo = Weather::Meteo->new();

	throws_ok { $meteo->weather({ latitude => ' 51.34', longitude => $LON, date => $DATE }) }
		qr/\Q$ERR_BAD_COORD\E/,
		'leading-space latitude: croak contains coord message';
};

# Purpose: scientific notation '1e5' is rejected -- the format only allows plain decimal.
subtest 'weather() -- lat="1e5" (scientific notation) croaks' => sub {
	my $meteo = Weather::Meteo->new();

	throws_ok { $meteo->weather({ latitude => '1e5', longitude => $LON, date => $DATE }) }
		qr/\Q$ERR_BAD_COORD\E/,
		'scientific-notation latitude: croak contains coord message';
};

# Purpose: a string with an embedded newline is not a valid coordinate.
subtest 'weather() -- lat with embedded newline croaks' => sub {
	my $meteo = Weather::Meteo->new();

	throws_ok { $meteo->weather({ latitude => "51\n.34", longitude => $LON, date => $DATE }) }
		qr/\Q$ERR_BAD_COORD\E/,
		'newline in latitude: croak contains coord message';
};

# Purpose: an extremely long string must croak, not hang or consume memory.
subtest 'weather() -- excessively long latitude string croaks' => sub {
	my $meteo = Weather::Meteo->new();

	throws_ok { $meteo->weather({ latitude => $config{long_string}, longitude => $LON, date => $DATE }) }
		qr/\Q$ERR_BAD_COORD\E/,
		'1000-char latitude: croak contains coord message';

	diag('long string ok') if $ENV{TEST_VERBOSE};
};

# Purpose: out-of-geographic-range but format-valid coordinate (99999) must proceed.
# Range validation is the API's responsibility, not the module's.
subtest 'weather() -- lat=99999 (out of range but valid format) proceeds to API' => sub {
	_mock_ok();
	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $result = $meteo->weather({ latitude => 99999, longitude => $LON, date => $DATE });

	ok(defined($result), 'out-of-range but format-valid lat proceeds');
	restore_all();
};

# ===========================================================================
# weather() -- date boundary and pathological values
# ===========================================================================

# Purpose: numeric 0 as a date must carp and return undef.
subtest 'weather() -- date=0 (numeric zero) carps and returns undef' => sub {
	my $meteo  = Weather::Meteo->new();
	my $warned = 0;
	local $SIG{__WARN__} = sub { $warned++ };

	my $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => 0 });

	ok(!defined($result), 'date=0: returns undef');
	ok($warned,           'date=0: carp was emitted');

	diag("warned=$warned") if $ENV{TEST_VERBOSE};
};

# Purpose: empty string as a date must carp and return undef.
subtest 'weather() -- date="" (empty string) carps and returns undef' => sub {
	my $meteo  = Weather::Meteo->new();
	my $warned = 0;
	local $SIG{__WARN__} = sub { $warned++ };

	my $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => '' });

	ok(!defined($result), 'date="": returns undef');
	ok($warned,           'date="": carp was emitted');
};

# Purpose: '1940-01-01' is the first valid year (FIRST_YEAR inclusive) -- must proceed.
subtest 'weather() -- date="1940-01-01" (boundary year, inclusive) proceeds' => sub {
	_mock_ok();
	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => '1940-01-01' });

	ok(defined($result), '1940-01-01: proceeds (boundary inclusive)');
	restore_all();
};

# Purpose: '1939-12-31' is one day before FIRST_YEAR -- must return undef silently.
subtest 'weather() -- date="1939-12-31" (one day before boundary) returns undef' => sub {
	my $meteo  = Weather::Meteo->new();
	my $warned = 0;
	local $SIG{__WARN__} = sub { $warned++ };

	my $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => '1939-12-31' });

	ok(!defined($result),    '1939-12-31: returns undef');
	cmp_ok($warned, '==', 0, '1939-12-31: no warning emitted');
};

# Purpose: year '0001' is well before FIRST_YEAR -- returns undef silently.
subtest 'weather() -- date="0001-01-01" (ancient) returns undef silently' => sub {
	my $meteo  = Weather::Meteo->new();
	my $warned = 0;
	local $SIG{__WARN__} = sub { $warned++ };

	my $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => '0001-01-01' });

	ok(!defined($result),    '0001-01-01: returns undef');
	cmp_ok($warned, '==', 0, '0001-01-01: silent (no warning)');
};

# Purpose: '9999-12-31' is a far-future date -- the format is valid so it must proceed.
subtest 'weather() -- date="9999-12-31" (far future, valid format) proceeds' => sub {
	_mock_ok();
	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => '9999-12-31' });

	ok(defined($result), '9999-12-31: proceeds to API (format valid)');
	restore_all();
};

# Purpose: ISO-8601 datetime with time component must croak (only date part is accepted).
subtest 'weather() -- date with time component croaks with format message' => sub {
	my $meteo = Weather::Meteo->new();

	throws_ok { $meteo->weather({ latitude => $LAT, longitude => $LON,
	                              date => '2022-12-25T00:00:00' }) }
		qr/\Q$ERR_BAD_FMT\E/,
		'datetime string: croak mentions expected format';

	diag("err fragment: $ERR_BAD_FMT") if $ENV{TEST_VERBOSE};
};

# Purpose: a year+hyphen-only string ('2022-') triggers the croak path.
subtest 'weather() -- date="2022-" (year+hyphen, no month/day) croaks' => sub {
	my $meteo = Weather::Meteo->new();

	throws_ok { $meteo->weather({ latitude => $LAT, longitude => $LON, date => '2022-' }) }
		qr/\Q$ERR_BAD_FMT\E/,
		'"2022-": croak mentions expected format';
};

# Purpose: single-digit month/day ('2022-1-1') starts with ^(\d{4})- so it
# enters the year-check branch, passes the year test, then fails the strict
# /^\d{4}-\d{2}-\d{2}$/ check and CROAKS (not carps) -- it looks like a date
# attempt in the wrong format, which is a harder error than "not a date at all".
subtest 'weather() -- date="2022-1-1" (non-padded) croaks with format message' => sub {
	my $meteo = Weather::Meteo->new();

	throws_ok { $meteo->weather({ latitude => $LAT, longitude => $LON, date => '2022-1-1' }) }
		qr/\Q$ERR_BAD_FMT\E/,
		'2022-1-1: croak mentions expected YYYY-MM-DD format';
};

# Purpose: '2022-13-45' has an impossible month/day but passes the YYYY-MM-DD
# regex -- the module must pass it to the API without croaking.
subtest 'weather() -- date="2022-13-45" (impossible m/d, valid format) proceeds' => sub {
	_mock_ok();
	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => '2022-13-45' });

	ok(defined($result), '2022-13-45: passes format check, proceeds to API');
	restore_all();
};

# Purpose: a coderef as date is not blessed with strftime -- must carp + undef.
subtest 'weather() -- date as coderef carps and returns undef' => sub {
	my $meteo  = Weather::Meteo->new();
	my @warns;
	local $SIG{__WARN__} = sub { push @warns, $_[0] };

	my $result = $meteo->weather({ latitude => $LAT, longitude => $LON,
	                               date => sub { 'bad' } });

	ok(!defined($result), 'coderef date: returns undef');
	ok(scalar(@warns),    'coderef date: warning emitted');

	# Warning must mention the stringified coderef (starts with CODE)
	like($warns[0], qr/CODE/, 'warning mentions CODE ref');
	diag("warn: $warns[0]") if $ENV{TEST_VERBOSE};
};

# Purpose: a hashref as date stringifies to HASH(0x...) and must carp + undef.
subtest 'weather() -- date as hashref carps and returns undef' => sub {
	my $meteo  = Weather::Meteo->new();
	my @warns;
	local $SIG{__WARN__} = sub { push @warns, $_[0] };

	my $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => {} });

	ok(!defined($result), 'hashref date: returns undef');
	ok(scalar(@warns),    'hashref date: warning emitted');
	like($warns[0], qr/HASH/, 'warning mentions HASH ref');
};

# Purpose: an unblessed arrayref as date stringifies to ARRAY(0x...) -- carp + undef.
subtest 'weather() -- date as arrayref carps and returns undef' => sub {
	my $meteo  = Weather::Meteo->new();
	my @warns;
	local $SIG{__WARN__} = sub { push @warns, $_[0] };

	my $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => [] });

	ok(!defined($result), 'arrayref date: returns undef');
	ok(scalar(@warns),    'arrayref date: warning emitted');
};

# ===========================================================================
# weather() -- pathological mock response edge cases
# ===========================================================================

# Purpose: when UA->get returns undef, weather() must carp and return undef.
# It must NOT propagate an unhandled "can't call method on undef" exception.
subtest 'weather() -- UA returns undef: carp + undef, no unhandled die' => sub {
	_mock_return(undef);
	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $warned = 0;
	local $SIG{__WARN__} = sub { $warned++ };

	my $result;
	lives_ok { $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE }) }
		'UA returns undef: no unhandled exception';
	ok(!defined($result), 'UA returns undef: result is undef');
	ok($warned,           'UA returns undef: carp was emitted');

	restore_all();
	diag("warned=$warned") if $ENV{TEST_VERBOSE};
};

# Purpose: UA returning numeric 0 (falsy) must be handled the same as undef.
subtest 'weather() -- UA returns 0: carp + undef, no unhandled die' => sub {
	_mock_return(0);
	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $warned = 0;
	local $SIG{__WARN__} = sub { $warned++ };

	my $result;
	lives_ok { $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE }) }
		'UA returns 0: no unhandled exception';
	ok(!defined($result), 'UA returns 0: result is undef');
	ok($warned,           'UA returns 0: carp was emitted');

	restore_all();
};

# Purpose: UA returning '' (empty string) must also be handled safely.
subtest 'weather() -- UA returns "": carp + undef, no unhandled die' => sub {
	_mock_return('');
	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $warned = 0;
	local $SIG{__WARN__} = sub { $warned++ };

	my $result;
	lives_ok { $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE }) }
		'UA returns "": no unhandled exception';
	ok(!defined($result), 'UA returns "": result is undef');
	ok($warned,           'UA returns "": carp was emitted');

	restore_all();
};

# Purpose: the exact carp message for a bad UA response must identify the problem.
subtest 'weather() -- UA returns undef: carp message is descriptive' => sub {
	_mock_return(undef);
	my $meteo = Weather::Meteo->new(cache => _fresh_cache());
	warning_like { $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE }) }
		qr/\Q$ERR_BAD_RESP\E/,
		'UA-undef carp mentions "did not return a valid HTTP response"';

	restore_all();
};

# Purpose: JSON body of 'null' decodes to undef; weather() must return undef.
subtest 'weather() -- JSON "null" body returns undef' => sub {
	_mock_json('null');
	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	ok(!defined($result), 'JSON null: returns undef');
	restore_all();
};

# Purpose: JSON response is an array ([...]) not an object -- must return undef
# without dying "Not a HASH reference".
subtest 'weather() -- JSON array "[...]" returns undef, does not die' => sub {
	_mock_json('[{"hourly":{"temperature_2m":[1]}}]');
	my $meteo = Weather::Meteo->new(cache => _fresh_cache());

	my $result;
	lives_ok { $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE }) }
		'JSON array: no unhandled exception';
	ok(!defined($result), 'JSON array: returns undef');

	restore_all();
	diag('JSON array ok') if $ENV{TEST_VERBOSE};
};

# Purpose: JSON response is '{}' (empty object with no hourly key) -- must return undef.
subtest 'weather() -- JSON "{}" (no hourly) returns undef' => sub {
	_mock_json('{}');
	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	ok(!defined($result), 'JSON {}: returns undef');
	restore_all();
};

# Purpose: JSON with {"hourly":null} has a defined 'hourly' key but the value is null.
# Since defined(null) is false, weather() must return undef.
subtest 'weather() -- JSON {"hourly":null} returns undef' => sub {
	_mock_json('{"hourly":null}');
	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	ok(!defined($result), 'JSON hourly=null: returns undef');
	restore_all();
};

# Purpose: {"hourly":{}} has a defined (but empty) hourly object -- should return it.
subtest 'weather() -- JSON {"hourly":{}} (empty hourly) returns the hashref' => sub {
	_mock_json('{"hourly":{}}');
	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	ok(defined($result),            'JSON hourly={}: result is defined');
	returns_ok($result, { type => 'hashref' }, 'JSON hourly={}: return is a hashref');
	ok(exists($result->{'hourly'}), 'JSON hourly={}: hourly key present');

	restore_all();
};

# Purpose: JSON {"error":true} with an hourly key present -- error flag wins.
subtest 'weather() -- JSON {"error":true} returns undef despite hourly key' => sub {
	_mock_json('{"error":true,"hourly":{"temperature_2m":[1]}}');
	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	ok(!defined($result), 'error=true: returns undef even when hourly present');
	restore_all();
};

# Purpose: empty response body ('') must carp "Failed to parse JSON" and return undef.
subtest 'weather() -- empty response body carps JSON-parse failure' => sub {
	_mock_json('');
	my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
	my $warned = 0;
	local $SIG{__WARN__} = sub { $warned++ };

	my $result = $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });

	ok(!defined($result), 'empty body: returns undef');
	ok($warned,           'empty body: carp emitted');

	restore_all();
	diag("warned=$warned") if $ENV{TEST_VERBOSE};
};

# Purpose: the JSON-parse carp must mention "Failed to parse JSON response".
subtest 'weather() -- bad JSON carp message identifies the failure' => sub {
	_mock_json('this is not json');
	my $meteo = Weather::Meteo->new(cache => _fresh_cache());

	warning_like { $meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE }) }
		qr/Failed to parse JSON response/,
		'bad JSON: warning says "Failed to parse JSON response"';

	restore_all();
};

# ===========================================================================
# ua() -- setter edge cases
# ===========================================================================

# Purpose: ua(undef) must croak -- silently setting ua to undef would corrupt state.
subtest 'ua(undef) croaks with descriptive message' => sub {
	my $meteo = Weather::Meteo->new();

	throws_ok { $meteo->ua(undef) }
		qr/\Q$ERR_UA_UNDEF\E/,
		'ua(undef) croak mentions "requires a defined value"';

	# Verify the internal ua was NOT corrupted
	ok(defined($meteo->ua()), 'ua is still defined after the failed setter call');

	diag("err fragment: $ERR_UA_UNDEF") if $ENV{TEST_VERBOSE};
};

# Purpose: ua(0) is not an object at all -- the type check fires before the
# can-check, so the error says "must be an object" (not "get method").
subtest 'ua(0) croaks (not a valid object)' => sub {
	my $meteo = Weather::Meteo->new();

	throws_ok { $meteo->ua(0) }
		qr/must be an object/,
		'ua(0) croak says "must be an object"';
};

# Purpose: ua('') is an empty string, not a valid object -- must croak.
subtest 'ua("") croaks (not a valid object)' => sub {
	my $meteo = Weather::Meteo->new();

	# Empty string triggers a different validation path but must still die
	eval { $meteo->ua('') };
	ok($@, 'ua("") causes croak');

	diag("error: $@") if $ENV{TEST_VERBOSE};
};

# Purpose: ua([]) is an unblessed arrayref -- Params::Get rejects the call form.
subtest 'ua([]) croaks (unblessed arrayref)' => sub {
	my $meteo = Weather::Meteo->new();

	eval { $meteo->ua([]) };
	ok($@, 'ua([]) causes croak');
};

# Purpose: ua({}) is an unblessed hashref -- Params::Validate should reject it.
subtest 'ua({}) croaks (unblessed hashref)' => sub {
	my $meteo = Weather::Meteo->new();

	eval { $meteo->ua({}) };
	ok($@, 'ua({}) causes croak');
};

# Purpose: ua(sub{}) is a coderef -- must be rejected as "not an object".
subtest 'ua(sub{}) croaks (coderef is not an object)' => sub {
	my $meteo = Weather::Meteo->new();

	eval { $meteo->ua(sub {}) };
	ok($@, 'ua(sub{}) causes croak');
};

# Purpose: ua($obj) where $obj is blessed but lacks get() must croak with exact message.
subtest 'ua(blessed-no-get) croaks with "get method" message' => sub {
	my $meteo  = Weather::Meteo->new();
	my $bad_ua = bless {}, 'NoGetMethod';

	throws_ok { $meteo->ua($bad_ua) }
		qr/\Q$ERR_UA_GETMETHOD\E/,
		'blessed-no-get: croak says "get method"';
};

# ===========================================================================
# $_ global variable clobber checks
# ===========================================================================

# Purpose: none of the public methods should modify the caller's $_ variable.
# The module's internal regex operations must all bind to named variables.
subtest 'no public method clobbers $_' => sub {
	_mock_ok();

	# Test new()
	local $_ = 'sentinel';
	Weather::Meteo->new();
	is($_, 'sentinel', 'new() leaves $_ unchanged');

	# Test ua() getter
	my $meteo = Weather::Meteo->new();
	local $_ = 'sentinel';
	$meteo->ua();
	is($_, 'sentinel', 'ua() getter leaves $_ unchanged');

	# Test ua() setter
	$meteo->ua(LWP::UserAgent->new());
	is($_, 'sentinel', 'ua() setter leaves $_ unchanged');

	# Test weather()
	local $_ = 'sentinel';
	$meteo->weather({ latitude => $LAT, longitude => $LON, date => $DATE });
	is($_, 'sentinel', 'weather() leaves $_ unchanged');

	restore_all();
	diag("\$_ after all calls: $_") if $ENV{TEST_VERBOSE};
};

done_testing();
