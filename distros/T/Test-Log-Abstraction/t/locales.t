use strict;
use warnings;

use Test::Most;
use Errno qw(ENOENT);
use Test::Log::Abstraction;

# Locale handling: the language of the module's own messages, chosen by
# country (geographic) or by the POSIX locale variables (system), and the
# capture of operating-system error text, which is locale-dependent.

$ENV{'TEST_VERBOSE'} = 0;
$ENV{'VERBOSE'} = 0;

my $class = 'Test::Log::Abstraction';

# Expected language per country, and a fragment of each language's
# "needs a pattern" message to prove the catalogue really switched
my %COUNTRY = (GB => 'en', US => 'en', FR => 'fr', DE => 'de', CN => 'zh');
my %NEEDS_PATTERN = (
	en => qr/like\(\) needs a pattern/,
	fr => qr/like\(\) n\x{e9}cessite un motif/,
	de => qr/like\(\) ben\x{f6}tigt ein Muster/,
	zh => qr/like\(\) \x{9700}\x{8981}\x{4e00}\x{4e2a}\x{6a21}\x{5f0f}/,
);

# ---------------------------------------------------------------------------
# Geographic
# ---------------------------------------------------------------------------

# Everything below depends on this mapping; if it has drifted, the rest of
# the file would only report confusing failures
subtest 'sanity: country to language mapping' => sub {
	foreach my $country (sort keys %COUNTRY) {
		my $lang = $class->new(country => $country)->lang();
		is($lang, $COUNTRY{$country}, "$country maps to $COUNTRY{$country}")
			or BAIL_OUT("country mapping drifted: $country gave $lang");
	}

	# When a GeoIP database is installed, check that it still resolves a
	# long-stable address, so that callers feeding it into country => are
	# warned of drift
	SKIP: {
		my $geoip = eval { require Geo::IP; Geo::IP->new() };
		skip('Geo::IP and its database are not installed', 2) if(!$geoip);
		my $country = $geoip->country_code_by_addr('8.8.8.8');
		is($country, 'US', 'GeoIP still places 8.8.8.8 in the US')
			or BAIL_OUT('GeoIP database drifted: 8.8.8.8 gave ' . (defined($country) ? $country : 'undef'));
		is($class->new(country => $country)->lang(), 'en', 'GeoIP country selects English');
	}
};

subtest 'country selects the message language' => sub {
	foreach my $country (sort keys %COUNTRY) {
		my $logger = $class->new(country => $country, diag => 'none');
		throws_ok { $logger->like() } $NEEDS_PATTERN{$COUNTRY{$country}}, "$country error is in $COUNTRY{$country}";
	}
};

subtest 'country codes are case-insensitive' => sub {
	foreach my $country (sort keys %COUNTRY) {
		foreach my $spelling (lc($country), ucfirst(lc($country)), $country) {
			is($class->new(country => $spelling)->lang(), $COUNTRY{$country}, "'$spelling' maps to $COUNTRY{$country}");
		}
	}
};

subtest 'unknown country and precedence' => sub {
	is($class->new(country => 'JP')->lang(), 'en', 'unmapped country falls back to English');
	is($class->new(country => 'DE', lang => 'fr')->lang(), 'fr', 'explicit lang beats country');
	is($class->new(country => 'DE', lang => 'auto')->lang(), 'de', "country beats lang => 'auto'");
	throws_ok { $class->new(country => 'D') } qr/invalid argument/, 'one-letter country rejected';
};

subtest 'concurrent instances keep their own language' => sub {
	my %loggers = map { $_ => $class->new(country => $_, diag => 'none') } sort keys %COUNTRY;

	# Interleave the calls, twice, to catch any shared or cached state
	foreach my $round (1, 2) {
		foreach my $country (sort keys %COUNTRY) {
			throws_ok { $loggers{$country}->like() } $NEEDS_PATTERN{$COUNTRY{$country}}, "round $round: $country still $COUNTRY{$country}";
		}
	}
	is($Test::Log::Abstraction::config{'lang'}, 'en', 'no instance changed the global default');
	throws_ok { $class->new(diag => 'none')->like() } $NEEDS_PATTERN{'en'}, 'a new default logger is still English';
};

# ---------------------------------------------------------------------------
# System (POSIX)
# ---------------------------------------------------------------------------

my %LOCALE = (
	'en_US.UTF-8' => 'en',
	'de_DE.UTF-8' => 'de',
	'zh_CN.UTF-8' => 'zh',
);

foreach my $locale (sort keys %LOCALE) {
	my $lang = $LOCALE{$locale};

	subtest "LC_ALL=$locale" => sub {
		local $ENV{'LC_ALL'} = $locale;
		local $ENV{'LC_MESSAGES'};
		local $ENV{'LANG'};

		my $logger = $class->new(lang => 'auto', diag => 'none');
		is($logger->lang(), $lang, "lang => 'auto' reads $lang from LC_ALL");

		# Take the OS error text from Perl's own $! layer, as the code under
		# test would see it, rather than from POSIX::strerror
		local $! = ENOENT;
		my $os_error = "$!";
		ok(length($os_error), 'the OS supplied an error string');

		$logger->error("cannot open /nonexistent: $os_error");
		is($logger->messages()->[0]->{'message'}, "cannot open /nonexistent: $os_error", 'OS error text captured verbatim');
		is($! + 0, ENOENT, '$! survives the log call');
		ok($logger->like(qr/\Q$os_error\E/, 'OS error text is matchable'), 'like() matches it');

		# Errors are thrown, and in the locale's language
		throws_ok { $logger->like() } $NEEDS_PATTERN{$lang}, "missing pattern croaks in $lang";

		# OS text passes through an error message unharmed
		throws_ok { $class->new(lang => 'auto', diag => $os_error) } qr/\Q$os_error\E/, 'OS text interpolated into a croak intact';
	};
}

subtest 'POSIX variable precedence' => sub {
	{
		local $ENV{'LC_ALL'} = 'de_DE.UTF-8';
		local $ENV{'LC_MESSAGES'} = 'fr_FR.UTF-8';
		local $ENV{'LANG'} = 'zh_CN.UTF-8';
		is($class->new(lang => 'auto')->lang(), 'de', 'LC_ALL beats LC_MESSAGES and LANG');
	}
	{
		local $ENV{'LC_ALL'} = '';
		local $ENV{'LC_MESSAGES'} = 'fr_FR.UTF-8';
		local $ENV{'LANG'} = 'zh_CN.UTF-8';
		is($class->new(lang => 'auto')->lang(), 'fr', 'empty LC_ALL is skipped; LC_MESSAGES beats LANG');
	}
	{
		local $ENV{'LC_ALL'};
		local $ENV{'LC_MESSAGES'};
		local $ENV{'LANG'} = 'C';
		is($class->new(lang => 'auto')->lang(), 'en', 'the C locale is English');
	}
	{
		local $ENV{'LC_ALL'} = 'de_DE.UTF-8';
		is($class->new()->lang(), 'en', "the environment is ignored unless lang => 'auto'");
	}
};

done_testing();
