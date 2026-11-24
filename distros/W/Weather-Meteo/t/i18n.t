#!/usr/bin/env perl

# t/i18n.t -- tests for the message table, i18n(), and the behaviour changes
# made when the diagnostics were centralised and the helpers de-duplicated.

use strict;
use warnings;

use CHI;
use HTTP::Response;
use Test::Most;

use lib 'lib';
use Weather::Meteo;

my $JSON = '{"hourly":{"rain":[0]},"daily":{"sunrise":["2024-06-21T04:43"],"sunset":["2024-06-21T21:21"]}}';

# A UA that records its calls and answers from a queue, then with $JSON
{
	package Queue::UA;

	sub new {
		my ($class, @responses) = @_;
		return bless { queue => [@responses], urls => [] }, $class;
	}

	sub get {
		my ($self, $url) = @_;
		push @{$self->{urls}}, $url;
		return shift(@{$self->{queue}}) // _ok($JSON);
	}

	sub _ok {
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($_[0]);
		return $r;
	}
}

sub new_meteo {
	my (%args) = @_;
	return Weather::Meteo->new(
		cache       => CHI->new(driver => 'Memory', global => 0),
		retry_delay => 0,
		%args,
	);
}

# Collect warnings from a block
sub warnings_from(&) {
	my $code = shift;
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };
	$code->();
	return \@warnings;
}

# ---------------------------------------------------------------------------
subtest 'i18n: built-in English messages' => sub {
	my $meteo = new_meteo();

	is($meteo->i18n('invalid_date_format'), 'Invalid date format. Expected YYYY-MM-DD',
		'message without placeholders');
	is($meteo->i18n('not_a_date', { date => 'tomorrow' }), "'tomorrow' is not a valid date",
		'named placeholder is replaced');
	is($meteo->i18n('days_range', { min => 1, max => 16, default => 7 }),
		'days must be between 1 and 16; defaulting to 7', 'several placeholders');
	is(Weather::Meteo->i18n('invalid_host', { value => 'a b' }),
		"Invalid host 'a b': must be a plain hostname", 'works as a class method');
};

subtest 'i18n: placeholders' => sub {
	my $meteo = new_meteo(messages => { greet => 'Hello {name} {missing} {empty}' });

	is($meteo->i18n('greet', { name => 'World', empty => undef }), 'Hello World {missing} ',
		'unknown placeholder is left visible, undef becomes empty');
	is($meteo->i18n('greet', { name => '{name}' }), 'Hello {name} {missing} {empty}',
		'a value that looks like a placeholder is not substituted again');
};

subtest 'i18n: overrides' => sub {
	my $meteo = new_meteo(messages => { invalid_date_format => 'Datum ungueltig' });

	is($meteo->i18n('invalid_date_format'), 'Datum ungueltig', 'override wins');
	is($meteo->i18n('ua_undef'), 'ua() requires a defined value', 'other keys keep the default');
	is(new_meteo()->i18n('invalid_date_format'), 'Invalid date format. Expected YYYY-MM-DD',
		'override is per object');

	my $clone = $meteo->new(host => 'mock.example.com');
	is($clone->i18n('invalid_date_format'), 'Datum ungueltig', 'a clone keeps the overrides');
};

subtest 'i18n: plural and gender variants' => sub {
	my $meteo = new_meteo(messages => {
		days => { one => '{count} day', other => '{count} days' },
		host => {
			one     => 'one host',   one_f   => 'one lady host',
			other   => 'many hosts', other_f => 'many lady hosts',
		},
		only_other => { other => 'always {count}' },
	});

	is($meteo->i18n('days', { count => 1 }), '1 day',  'singular');
	is($meteo->i18n('days', { count => 0 }), '0 days', 'zero takes the plural');
	is($meteo->i18n('days', { count => 2 }), '2 days', 'plural');
	is($meteo->i18n('days'),                 '{count} days', 'no count takes the plural, and the placeholder stays visible');

	is($meteo->i18n('host', { count => 1, gender => 'f' }), 'one lady host',   'gendered singular');
	is($meteo->i18n('host', { count => 3, gender => 'f' }), 'many lady hosts', 'gendered plural');
	is($meteo->i18n('host', { count => 1, gender => 'm' }), 'one host',        'unknown gender falls back');
	is($meteo->i18n('only_other', { count => 1 }), 'always 1', 'falls back to other if one is missing');

	my $broken = new_meteo(messages => { bad => { one => 'x' } });
	throws_ok { $broken->i18n('bad', { count => 5 }) } qr/no 'other' variant/,
		'confesses if no variant fits';
};

subtest 'i18n: sprintf' => sub {
	my $meteo = new_meteo(messages => { fmt => 'value %s of %d: {tag}' });

	is($meteo->i18n('fmt', { sprintf => ['abc', 7], tag => '100%' }), 'value abc of 7: 100%',
		'sprintf is applied first so % in a placeholder value is safe');
};

subtest 'i18n: unknown key confesses with a stack trace' => sub {
	throws_ok { new_meteo()->i18n('no_such_key') } qr/no message defined for key 'no_such_key'.*\n.*called at/s,
		'unknown key is fatal and has a backtrace';
};

subtest 'new(): messages must be a hashref' => sub {
	throws_ok { Weather::Meteo->new(messages => 'English') } qr/'messages' argument must be a hash reference/,
		'string rejected';
	throws_ok { Weather::Meteo->new(messages => []) } qr/'messages' argument must be a hash reference/,
		'arrayref rejected';
	lives_ok { Weather::Meteo->new(messages => {}) } 'empty hashref accepted';
};

# ---------------------------------------------------------------------------
subtest 'diagnostics use the message table' => sub {
	my $meteo = new_meteo(messages => {
		usage_weather       => 'WEATHER-USAGE',
		invalid_coordinates => 'BAD-COORDS {latitude}/{longitude}',
		invalid_date_format => 'BAD-DATE-FORMAT',
		not_a_date          => 'NOT-A-DATE {date}',
		days_range          => 'DAYS {min}-{max} ({default})',
		usage_forecast      => 'FORECAST-USAGE',
		usage_sunrise       => 'SUNRISE-USAGE',
	});

	throws_ok { $meteo->weather(date => '2024-01-01') } qr/WEATHER-USAGE/, 'usage croak';
	throws_ok { $meteo->weather(latitude => 'x', longitude => '.5', date => '2024-01-01') }
		qr{BAD-COORDS x/0\.5}, 'coordinate croak sees the normalised values';
	throws_ok { $meteo->weather(latitude => 1, longitude => 1, date => '2024-xx-01') }
		qr/BAD-DATE-FORMAT/, 'date format croak';
	throws_ok { $meteo->forecast(longitude => 1) } qr/FORECAST-USAGE/, 'forecast usage';
	throws_ok { $meteo->sunrise_sunset(longitude => 1) } qr/SUNRISE-USAGE/, 'sunrise usage';

	my $w = warnings_from { $meteo->weather(latitude => 1, longitude => 1, date => 'soon') };
	like($w->[0], qr/NOT-A-DATE soon/, 'not-a-date warning');

	$meteo->{ua} = Queue::UA->new();
	$w = warnings_from { $meteo->forecast(latitude => 1, longitude => 1, days => 99) };
	like($w->[0], qr/DAYS 1-16 \(7\)/, 'days_range warning is parameterised');
};

# ---------------------------------------------------------------------------
subtest 'logger: failures never turn into exceptions' => sub {
	# Object::Configure wraps whatever logger it is given in a
	# Log::Abstraction, whose error() dies.  That is exactly the case the eval
	# guard in _log_error() exists for.
	{
		package Dying::Logger;
		sub new   { return bless {}, shift }
		sub error { die "logger died\n" }
	}
	my $meteo = new_meteo(logger => Dying::Logger->new(), ua => Queue::UA->new(HTTP::Response->new(404, 'Not Found')));
	ok($meteo->{logger}, 'object has a logger');

	my $result = 'unset';
	my $w = warnings_from { $result = $meteo->weather(latitude => 1, longitude => 1, date => '2024-01-01') };
	is($result, undef, 'undef is still returned when the logger dies');
	like($w->[0], qr/API returned error: 404/, 'the warning was still issued');

	throws_ok { $meteo->weather(latitude => 1) } qr/Usage: weather/,
		'a usage croak is still a usage croak, not "logger died"';
};

# ---------------------------------------------------------------------------
subtest 'encapsulation' => sub {
	# Sub::Private and Sub::Protected switch their checks off under a test
	# harness (HARNESS_ACTIVE) so that white-box tests can reach the helpers.
	# Switch that off here, and only here, to test the enforcement itself.
	local $Sub::Private::config{harness_bypass}   = 0;
	local $Sub::Protected::config{harness_bypass} = 0;

	# Private (enforce mode): the sub exists, but only Weather::Meteo itself may call it
	throws_ok { Weather::Meteo::_build_url('example.com', '/', []) }          qr/private/i, '_build_url refuses an outside caller';
	throws_ok { Weather::Meteo::_normalise_coord('.5') }                      qr/private/i, '_normalise_coord refuses an outside caller';
	throws_ok { Weather::Meteo->new()->_untaint_param({ host => 'x' }, 'host') }           qr/private/i, 'private also holds for method-style calls';

	# Protected: this class and subclasses may call it, nobody else
	my $meteo = new_meteo(ua => Queue::UA->new());
	throws_ok { $meteo->_fetch_json('https://example.com/') } qr/protected method/, 'protected method refuses an outside caller';
	throws_ok { $meteo->_croak('ua_undef') }                  qr/protected method/, '_croak is protected too';
	is(scalar(@{$meteo->{ua}{urls}}), 0, 'and the refused call made no request');

	# A subclass is allowed to use protected methods, but not private ones
	{
		package Weather::Meteo::Sub;
		our @ISA = ('Weather::Meteo');
		sub probe_protected { return $_[0]->i18n('ua_undef') && $_[0]->_log_error('x') }
		sub probe_private   { return Weather::Meteo::_normalise_coord('.5') }
	}
	my $sub = Weather::Meteo::Sub->new(ua => Queue::UA->new());
	lives_ok  { $sub->probe_protected } 'subclass may call a protected method';
	throws_ok { $sub->probe_private }   qr/private/i, 'subclass may not call a private function';
};

# ---------------------------------------------------------------------------
subtest 'weather(): date handling' => sub {
	my $ua    = Queue::UA->new();
	my $meteo = new_meteo(ua => $ua);

	# A strftime object before 1940 used to slip past the year check and be sent to the API
	{
		package Fake::Date;
		sub new { my ($c, $s) = @_; return bless { s => $s }, $c }
		sub strftime { return $_[0]{s} }
	}
	my $result;
	my $w = warnings_from { $result = $meteo->weather(latitude => 1, longitude => 1, date => Fake::Date->new('1704-11-14')) };
	is($result, undef, 'object dated before 1940 returns undef');
	is(scalar(@{$w}), 0, '... silently');
	is(scalar(@{$ua->{urls}}), 0, '... without a request');

	$w = warnings_from { $result = $meteo->weather(latitude => 1, longitude => 1, date => '1704-11-14') };
	is($result, undef, 'string dated before 1940 returns undef');
	is(scalar(@{$w}), 0, '... silently');

	# $ used to match before a trailing newline, so "2024-01-01\n" was accepted
	throws_ok { $meteo->weather(latitude => 1, longitude => 1, date => "2024-01-01\n") }
		qr/Invalid date format/, 'trailing newline is rejected';
	is(scalar(@{$ua->{urls}}), 0, '... before any request');

	ok(defined($meteo->weather(latitude => 1, longitude => 1, date => Fake::Date->new('2024-01-01'))),
		'object dated in range works');
	is(scalar(@{$ua->{urls}}), 1, 'one request made');
	like($ua->{urls}[0], qr{^https://archive-api\.open-meteo\.com/v1/archive\?latitude=1&longitude=1&start_date=2024-01-01&end_date=2024-01-01&hourly=temperature_2m,rain,snowfall,weathercode&daily=}, 'URL shape unchanged');
	like($ua->{urls}[0], qr/timezone=Europe%2FLondon&windspeed_unit=mph&precipitation_unit=inch\z/, 'units and timezone last');
};

subtest 'sunrise_sunset(): date handling and errors' => sub {
	my $ua    = Queue::UA->new();
	my $meteo = new_meteo(ua => $ua);

	my $w = warnings_from { $meteo->sunrise_sunset(latitude => 1, longitude => 1, date => "2024-06-21\n") };
	like($w->[0], qr/is not a valid date/, 'trailing newline is rejected');
	is(scalar(@{$ua->{urls}}), 0, '... before any request');

	my $times = $meteo->sunrise_sunset(latitude => 1, longitude => 1, date => '2024-06-21');
	is_deeply($times, { sunrise => '2024-06-21T04:43', sunset => '2024-06-21T21:21' }, 'times returned');
	like($ua->{urls}[0], qr{archive-api\.open-meteo\.com/v1/archive}, 'past date uses the archive');
	like($ua->{urls}[0], qr/daily=sunrise,sunset/, 'commas are not percent-encoded');

	# An error the API reports with HTTP 200 is now reported as it is for weather()
	$ua = Queue::UA->new(Queue::UA::_ok('{"error":true,"reason":"Too many requests"}'));
	$meteo = new_meteo(ua => $ua);
	my $result;
	$w = warnings_from { $result = $meteo->sunrise_sunset(latitude => 1, longitude => 1, date => '2024-06-21') };
	is($result, undef, 'API error gives undef');
	like($w->[0], qr/API error: Too many requests/, '... with the API reason as a warning');
};

subtest 'forecast(): API errors are reported' => sub {
	my $meteo = new_meteo(ua => Queue::UA->new(Queue::UA::_ok('{"error":true,"reason":"Bad thing"}')));
	my $result;
	my $w = warnings_from { $result = $meteo->forecast(latitude => 1, longitude => 1) };
	is($result, undef, 'API error gives undef');
	like($w->[0], qr/API error: Bad thing/, '... and a warning (it used to be silent)');

	foreach my $days (qw(0 17 abc -3 1.5)) {
		my $ua = Queue::UA->new();
		$w = warnings_from { new_meteo(ua => $ua)->forecast(latitude => 1, longitude => 1, days => $days) };
		like($w->[0], qr/days must be between 1 and 16; defaulting to 7/, "days=$days is corrected");
		like($ua->{urls}[0], qr/forecast_days=7\b/, "days=$days requests 7 days");
	}
	my $ua = Queue::UA->new();
	$w = warnings_from { new_meteo(ua => $ua)->forecast(latitude => 1, longitude => 1, days => 16) };
	is(scalar(@{$w}), 0, 'days=16 is fine');
	like($ua->{urls}[0], qr/forecast_days=16\b/, 'and is sent');
};

# ---------------------------------------------------------------------------
subtest 'JSON: UTF-8 bytes are decoded exactly once' => sub {
	my $r = HTTP::Response->new(200, 'OK');
	$r->content("{\"hourly\":{\"city\":[\"M\xc3\xbcnchen\"]}}");	# UTF-8 bytes for u-umlaut
	my $weather = new_meteo(ua => Queue::UA->new($r))->weather(latitude => 1, longitude => 1, date => '2024-01-01');

	is($weather->{hourly}{city}[0], "M\x{fc}nchen", 'non-ASCII text survives');
};

subtest 'rate limiting uses sub-second time' => sub {
	my @sleeps;
	no warnings 'redefine';
	local *Time::HiRes::sleep = sub { push @sleeps, $_[0] };

	my $meteo = new_meteo(ua => Queue::UA->new(), min_interval => 0.5);
	$meteo->weather(latitude => 1, longitude => 1, date => '2024-01-01');
	is(scalar(@sleeps), 0, 'first request does not wait');

	$meteo->weather(latitude => 2, longitude => 2, date => '2024-01-01');
	is(scalar(@sleeps), 1, 'an immediate second request waits');
	cmp_ok($sleeps[0], '>', 0.3, 'for most of the interval (whole-second time() would have waited 0.5 or 0)');
	cmp_ok($sleeps[0], '<=', 0.5, 'but never more than the interval');
};

done_testing();
