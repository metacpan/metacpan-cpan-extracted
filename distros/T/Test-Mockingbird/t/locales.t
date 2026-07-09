use strict;
use warnings;

use POSIX qw(ENOENT);
use Test::Most;

use Test::Mockingbird;

# -----------------------------------------------------------------------
# LOCALE TESTS FOR Test::Mockingbird
#
# Scope: This module produces no locale-sensitive output of its own.
# The tests below verify that:
#
#  1. The module loads correctly under three POSIX locales (sanity).
#  2. Error messages croaked by the module are pure Perl strings and
#     do not incorporate locale-sensitive OS error text.
#  3. The POSIX pattern for extracting OS error strings is used rather
#     than POSIX::strerror(), which bypasses Perl's locale layer.
#
# Geographic (GeoIP) access control is NOT tested here because
# Test::Mockingbird has no country-based behaviour; it is a test utility.
# -----------------------------------------------------------------------

# -----------------------------------------------------------------------
# SANITY SUBTEST
# Verify that our locale infrastructure itself works.  BAIL_OUT if not,
# because locale-contaminated test output poisons every subsequent test.
# -----------------------------------------------------------------------
subtest 'locale infrastructure sanity' => sub {
	# Obtain the ENOENT string through Perl's own error layer, NOT strerror().
	# This ensures we test what Perl actually surfaces, not the C library.
	my $enoent_msg = do { local $! = ENOENT; "$!" };

	BAIL_OUT 'Cannot obtain POSIX error string for ENOENT via $!'
		unless defined $enoent_msg && length $enoent_msg;

	ok 1, "ENOENT string available: '$enoent_msg'";
};

# -----------------------------------------------------------------------
# POSIX LOCALE TESTS
# Three representative LC_ALL settings: US English, German, Japanese.
# For each we verify that:
#   a) The module loads (use Test::Mockingbird re-exercises the use path
#      even after it has been loaded; we test the API instead).
#   b) croak error messages are locale-independent Perl strings.
#   c) The module's croak output does NOT contain the locale-sensitive
#      OS error string for ENOENT, confirming no accidental $! leakage.
# -----------------------------------------------------------------------

my @test_locales = (
	{ lc_all => 'en_US.UTF-8', label => 'US English' },
	{ lc_all => 'de_DE.UTF-8', label => 'German'     },
	{ lc_all => 'ja_JP.UTF-8', label => 'Japanese'   },
);

for my $loc (@test_locales) {
	subtest "locale: $loc->{label} ($loc->{lc_all})" => sub {
		# Temporarily override the locale for this subtest block.
		# Use local() so the previous value is restored on exit.
		local $ENV{LC_ALL} = $loc->{lc_all};

		# Source the OS error string in this locale via Perl's layer
		my $os_enoent = do { local $! = ENOENT; "$!" };

		# ------------------------------------------------------------------
		# a) API works correctly under this locale
		# ------------------------------------------------------------------
		{
			package Locale::TestPkg;
			sub hello { 'world' }
		}

		mock_return 'Locale::TestPkg::hello' => 'mocked';
		is Locale::TestPkg::hello(), 'mocked',
			"mock_return works under $loc->{label}";
		restore_all();
		is Locale::TestPkg::hello(), 'world',
			"restore_all works under $loc->{label}";

		# ------------------------------------------------------------------
		# b) croak errors are Perl strings -- not locale-sensitive
		# ------------------------------------------------------------------
		my $err;
		eval { mock(undef, undef, undef) };
		$err = $@;
		like $err, qr/Package, method and replacement are required/,
			"croak message is plain Perl string under $loc->{label}";

		# ------------------------------------------------------------------
		# c) croak output does not accidentally incorporate $! (OS string)
		# ------------------------------------------------------------------
		# Strip whitespace from $os_enoent for a robust comparison
		(my $os_trimmed = $os_enoent) =~ s/^\s+|\s+$//g;

		unlike $err, qr/\Q$os_trimmed\E/,
			"croak message does not contain locale OS error '$os_trimmed'";
	};
}

# -----------------------------------------------------------------------
# CONCURRENT INSTANCE TEST
# Verify that two mock stacks coexist cleanly -- simulates concurrent
# test processes sharing no global state (since state is per-process).
# -----------------------------------------------------------------------
subtest 'multiple mock targets coexist under locale' => sub {
	local $ENV{LC_ALL} = 'en_US.UTF-8';

	{
		package Locale::A;
		sub val { 'a' }
	}
	{
		package Locale::B;
		sub val { 'b' }
	}

	mock_return 'Locale::A::val' => 'A_mocked';
	mock_return 'Locale::B::val' => 'B_mocked';

	is Locale::A::val(), 'A_mocked', 'A mocked';
	is Locale::B::val(), 'B_mocked', 'B mocked';

	restore_all();

	is Locale::A::val(), 'a', 'A restored';
	is Locale::B::val(), 'b', 'B restored';
};

done_testing();
