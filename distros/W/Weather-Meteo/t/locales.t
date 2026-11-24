#!/usr/bin/env perl

# t/locales.t -- locale-safety tests for Weather::Meteo
#
# Section 1 -- Geographic: verify the module accepts coordinates from major
# world regions (GB, US, FR, DE, CN) and returns the expected structure.
# A sanity subtest runs first; BAIL_OUT fires if the coordinate table is broken.
#
# Section 2 -- POSIX system locale: verify that all carp/croak messages from
# the module are English by default, and exactly the caller's translation when
# one is supplied through the 'messages' option, regardless of LC_ALL.  errno strings ($!) are
# sourced directly from Perl's own layer (local $! = ENOENT; my $msg = "$!")
# to avoid divergence between POSIX::strerror and the C library.

use strict;
use warnings;
use utf8;

use CHI;
use HTTP::Response;
use POSIX qw(ENOENT);
use Readonly;
use Test::Most;
use Test::Mockingbird;

use lib 'lib';
use Weather::Meteo;

# ---------------------------------------------------------------------------
# Geographic coordinate fixtures -- spot-checked against maps
# ---------------------------------------------------------------------------
Readonly my %COORDS => (
	GB => { lat => '51.5074',  lon => '-0.1278',   name => 'London'   },
	US => { lat => '40.7128',  lon => '-74.0060',  name => 'New York' },
	FR => { lat => '48.8566',  lon => '2.3522',    name => 'Paris'    },
	DE => { lat => '52.5200',  lon => '13.4050',   name => 'Berlin'   },
	CN => { lat => '39.9042',  lon => '116.4074',  name => 'Beijing'  },
);

Readonly my $DATE => '2022-06-21';

my %config = (
	# Minimal valid response used for all geographic tests
	hourly_json => '{"hourly":{"temperature_2m":[20,21,22],"rain":[0,0,0],'
	            . '"snowfall":[0,0,0],"weathercode":[1,1,1]},'
	            . '"daily":{"time":["2022-06-21"],'
	            . '"sunrise":["2022-06-21T04:00"],"sunset":["2022-06-21T20:00"],'
	            . '"weathercode":[1],"temperature_2m_max":[25.0],'
	            . '"temperature_2m_min":[15.0],"rain_sum":[0.0],'
	            . '"snowfall_sum":[0.0],"precipitation_hours":[0.0],'
	            . '"windspeed_10m_max":[10.0],"windgusts_10m_max":[18.0]}}',
);

sub _fresh_cache {
	return CHI->new(driver => 'Memory', global => 0, expires_in => '1 hour');
}

# Helper: returns 1 if the given locale name is accepted by POSIX::setlocale
sub _locale_available {
	my ($locale) = @_;
	require POSIX;
	my $saved = POSIX::setlocale(POSIX::LC_ALL());
	my $got   = POSIX::setlocale(POSIX::LC_ALL(), $locale);
	POSIX::setlocale(POSIX::LC_ALL(), $saved);
	return defined($got) && length($got);
}

# ===========================================================================
# SECTION 1: Geographic locale
# ===========================================================================

# Sanity-check the coordinate table before running any geographic tests.
# BAIL_OUT if the table is incomplete or contains non-numeric entries so
# that individual country subtests do not produce misleading failures.
subtest 'geographic sanity: coordinate table is complete and plausible' => sub {
	for my $code (sort keys %COORDS) {
		my $c = $COORDS{$code};
		ok(defined($c->{lat}),                    "$code: lat defined");
		ok(defined($c->{lon}),                    "$code: lon defined");
		ok(defined($c->{name}),                   "$code: name defined");
		like($c->{lat}, qr/^-?\d+(\.\d+)?$/,     "$code: lat is numeric");
		like($c->{lon}, qr/^-?\d+(\.\d+)?$/,     "$code: lon is numeric");
	}
} or BAIL_OUT('coordinate table is broken -- geographic tests aborted');

# Verify that weather() succeeds for each major geographic region.
for my $code (sort keys %COORDS) {
	my $city = $COORDS{$code};
	subtest "geographic [$code] $city->{name}: weather() accepts coordinates" => sub {
		mock 'LWP::UserAgent::get' => sub {
			my $r = HTTP::Response->new(200, 'OK');
			$r->content($config{hourly_json});
			return $r;
		};

		my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
		my $result = $meteo->weather({
			latitude  => $city->{lat},
			longitude => $city->{lon},
			date      => $DATE,
		});

		ok(defined($result),            "$code: weather() returns a defined value");
		ok(ref($result) eq 'HASH',      "$code: result is a hashref");
		ok(exists($result->{'hourly'}), "$code: result has hourly key");

		restore_all();
		diag("$code [$city->{name}] ok") if $ENV{TEST_VERBOSE};
	};
}

# Verify that forecast() also accepts coordinates from all regions.
for my $code (sort keys %COORDS) {
	my $city = $COORDS{$code};
	subtest "geographic [$code] $city->{name}: forecast() accepts coordinates" => sub {
		mock 'LWP::UserAgent::get' => sub {
			my $r = HTTP::Response->new(200, 'OK');
			$r->content($config{hourly_json});
			return $r;
		};

		my $meteo  = Weather::Meteo->new(cache => _fresh_cache());
		my $result = $meteo->forecast({
			latitude  => $city->{lat},
			longitude => $city->{lon},
		});

		ok(defined($result),            "$code: forecast() returns a defined value");
		ok(exists($result->{'hourly'}), "$code: result has hourly key");

		restore_all();
	};
}

# Verify that concurrent instances for different countries do not share cache state.
subtest 'geographic: concurrent instances per country are independent (no cache leak)' => sub {
	my @codes    = sort keys %COORDS;
	my @meteos   = map { Weather::Meteo->new(cache => _fresh_cache()) } @codes;
	my $ua_calls = 0;

	mock 'LWP::UserAgent::get' => sub {
		$ua_calls++;
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{hourly_json});
		return $r;
	};

	for my $i (0 .. $#codes) {
		my $city = $COORDS{$codes[$i]};
		$meteos[$i]->weather({
			latitude  => $city->{lat},
			longitude => $city->{lon},
			date      => $DATE,
		});
	}

	# Each instance has its own cache so each must hit the network once
	cmp_ok($ua_calls, '==', scalar(@codes),
		'each country instance makes its own UA call (no cross-cache contamination)');

	restore_all();
	diag('concurrent independent instances ok') if $ENV{TEST_VERBOSE};
};

# Verify case-sensitivity: the timezone string is passed verbatim to the API.
# 'Europe/London' (the documented default) must appear in the URL.
subtest 'geographic: default timezone Europe/London appears in request URL' => sub {
	my $captured_url = '';
	mock 'LWP::UserAgent::get' => sub {
		my ($self_ua, $url) = @_;
		$captured_url = $url;
		my $r = HTTP::Response->new(200, 'OK');
		$r->content($config{hourly_json});
		return $r;
	};

	my $meteo = Weather::Meteo->new(cache => _fresh_cache());
	$meteo->weather({ latitude => $COORDS{GB}{lat}, longitude => $COORDS{GB}{lon}, date => $DATE });

	like($captured_url, qr/Europe%2FLondon|Europe\/London/, 'default timezone in URL');

	restore_all();
	diag("url=$captured_url") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# SECTION 2: POSIX system locale
# ===========================================================================

# Sanity-check that Perl's $! mechanism produces a non-empty string for ENOENT.
# We source the string from Perl itself (not POSIX::strerror) to avoid C-library
# divergence.  This subtest does NOT bail out -- it is informational.
subtest 'POSIX sanity: Perl $! gives a non-empty errno string for ENOENT' => sub {
	local $! = ENOENT;
	my $msg = "$!";
	ok(length($msg) > 0, "ENOENT via \$! is non-empty: '$msg'");
	diag("ENOENT in default locale: $msg") if $ENV{TEST_VERBOSE};
};

# For each target locale, verify:
#   (a) A bad date warning from weather() is in English.
#   (b) A missing-lat croak from weather() is in English.
#   (c) The errno string sourced through Perl's $! layer is non-empty.
my @locales = ('en_US.UTF-8', 'de_DE.UTF-8', 'zh_CN.UTF-8', 'ja_JP.UTF-8');

for my $locale (@locales) {

	subtest "POSIX [$locale]: weather() invalid-date warning is English" => sub {
		unless(_locale_available($locale)) {
			plan skip_all => "locale '$locale' not available on this system";
			return;
		}

		my @warnings;
		{
			local $ENV{LC_ALL} = $locale;
			local $SIG{__WARN__} = sub { push @warnings, $_[0] };
			my $meteo = Weather::Meteo->new(cache => _fresh_cache());
			$meteo->weather({ latitude => '51.5', longitude => '-0.1', date => 'not-a-date' });
		}

		ok(scalar(@warnings) > 0,              "[$locale] warning was emitted");
		like($warnings[0], qr/is not a valid date/,
			"[$locale] warning text is English regardless of locale");

		diag("[$locale] warning: $warnings[0]") if $ENV{TEST_VERBOSE};
	};

	subtest "POSIX [$locale]: weather() missing-lat croak is English" => sub {
		unless(_locale_available($locale)) {
			plan skip_all => "locale '$locale' not available on this system";
			return;
		}

		my $error;
		{
			local $ENV{LC_ALL} = $locale;
			my $meteo = Weather::Meteo->new(cache => _fresh_cache());
			eval { $meteo->weather({ longitude => '-0.1', date => $DATE }) };
			$error = $@;
		}

		ok($error,                         "[$locale] croak was thrown");
		like($error, qr/Usage: weather/,   "[$locale] croak text is English");

		diag("[$locale] croak: $error") if $ENV{TEST_VERBOSE};
	};

	subtest "POSIX [$locale]: translated messages are used verbatim" => sub {
		unless(_locale_available($locale)) {
			plan skip_all => "locale '$locale' not available on this system";
			return;
		}

		# Non-ASCII text in three scripts: the module must neither mangle it
		# nor depend on the process locale to choose it.
		my %translation = (
			usage_weather => 'Verwendung: weather(latitude => ..., longitude => ..., date => ...) äöü',
			not_a_date    => '「{date}」は有効な日付ではありません',
			ua_undef      => '必须提供有效的 ua',
		);
		my ($usage, @warnings, $ua_error);
		{
			local $ENV{LC_ALL} = $locale;
			local $SIG{__WARN__} = sub { push @warnings, $_[0] };
			my $meteo = Weather::Meteo->new(cache => _fresh_cache(), messages => \%translation);

			eval { $meteo->weather({ longitude => '-0.1', date => $DATE }) };
			$usage = $@;
			$meteo->weather({ latitude => '51.5', longitude => '-0.1', date => 'kein-datum' });
			eval { $meteo->ua(undef) };
			$ua_error = $@;
		}

		like($usage,       qr/\AVerwendung: weather\(.*äöü/, "[$locale] usage croak is the translation");
		# Look for our warning rather than assuming it is the first: a
		# configured logger (Log4perl, say) may emit warnings of its own, such as
		# "Wide character in print", when it is handed non-ASCII text.
		my ($warned) = grep { /「kein-datum」/ } @warnings;
		like($warned // '', qr/\A「kein-datum」は有効な日付ではありません/, "[$locale] warning is the translation, placeholder filled");
		unlike($usage . join('', @warnings), qr/Usage:|is not a valid date/,   "[$locale] no English leaks through");
		ok(length($ua_error),                                                  "[$locale] ua(undef) still throws");

		diag("[$locale] translated usage: $usage") if $ENV{TEST_VERBOSE};
	};

	subtest "POSIX [$locale]: errno string sourced via Perl \$! layer is non-empty" => sub {
		unless(_locale_available($locale)) {
			plan skip_all => "locale '$locale' not available on this system";
			return;
		}

		my $msg;
		{
			local $ENV{LC_ALL} = $locale;
			local $! = ENOENT;
			$msg = "$!";
		}

		ok(length($msg) > 0, "[$locale] ENOENT string is non-empty: '$msg'");
		diag("[$locale] ENOENT: $msg") if $ENV{TEST_VERBOSE};
	};
}

# The module never calls setlocale(), so LC_ALL must not matter even when the
# named locale is not installed.  This runs everywhere, unlike the subtests
# above that skip when the locale is missing.
subtest 'LC_ALL has no effect on messages, installed or not' => sub {
	my %translation = (ua_undef => '必须提供有效的 ua', usage_forecast => 'Utilisation : forecast(latitude, longitude)');
	my %seen;

	for my $locale (@locales, 'C', 'xx_XX.UTF-8') {
		local $ENV{LC_ALL} = $locale;
		my $english    = Weather::Meteo->new(cache => _fresh_cache());
		my $translated = Weather::Meteo->new(cache => _fresh_cache(), messages => \%translation);

		$seen{english}{ $english->i18n('ua_undef') }++;
		$seen{translated}{ $translated->i18n('ua_undef') }++;

		throws_ok { $english->forecast(longitude => 1) } qr/\AUsage: forecast/,
			"[$locale] English croak";
		throws_ok { $translated->forecast(longitude => 1) } qr/\AUtilisation : forecast/,
			"[$locale] translated croak";
	}

	is_deeply([ keys %{ $seen{english} } ],    ['ua() requires a defined value'], 'one English text for every locale');
	is_deeply([ keys %{ $seen{translated} } ], ['必须提供有效的 ua'],             'one translated text for every locale');
};

done_testing();
