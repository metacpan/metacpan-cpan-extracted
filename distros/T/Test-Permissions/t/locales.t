#!/usr/bin/env perl

# Reasons embed the system's error text, which depends on the locale.
# Under several locales: the reason carries the errno text perl gives in
# that locale (sourced from "$!", not POSIX::strerror, which can differ
# from perl's own under a locale switch), croak texts stay intact, and
# nothing warns.

use strict;
use warnings;

use Errno ();
use File::Temp ();
use POSIX ();
use Test::Mockingbird ();
use Test::Most;
use Test::Warnings;

use lib 'lib';
use Test::Permissions qw(:all);

my $dir = File::Temp::tempdir(CLEANUP => 1);

sub locale_available {
	my ($locale) = @_;
	my $saved = POSIX::setlocale(POSIX::LC_ALL());
	my $result = POSIX::setlocale(POSIX::LC_ALL(), $locale);
	POSIX::setlocale(POSIX::LC_ALL(), $saved);
	return defined $result && $result eq $locale;
}

sub chmod_works {
	my %mode;
	my $set = \&Test::Permissions::_set_mode;
	my $of = \&Test::Permissions::_mode_of;
	return (
		Test::Mockingbird::mock_scoped('Test::Permissions', '_set_mode',
			sub { my $r = $set->(@_); $mode{$_[0]} = $_[1]; $r }),
		Test::Mockingbird::mock_scoped('Test::Permissions', '_mode_of',
			sub { exists $mode{$_[0]} ? $mode{$_[0]} : $of->(@_) }),
	);
}

subtest 'sanity: errno texts are available' => sub {
	local $! = Errno::ENOSPC();
	ok(length "$!", 'ENOSPC has a text');
};

my $saved = POSIX::setlocale(POSIX::LC_ALL());
for my $locale ('C', 'en_US.UTF-8', 'de_DE.UTF-8', 'fr_FR.UTF-8', 'ja_JP.UTF-8') {
	SKIP: {
		skip "locale $locale is not available", 1 unless locale_available($locale);
		subtest "LC_ALL=$locale" => sub {
			local $ENV{LC_ALL} = $locale;
			POSIX::setlocale(POSIX::LC_ALL(), $locale);

			my $text = do { local $! = Errno::ENOSPC(); "$!" };
			clear_cache();
			{
				my @g = chmod_works();
				my $calls = 0;
				my $orig = \&Test::Permissions::_try_open;
				push @g, Test::Mockingbird::mock_scoped('Test::Permissions', '_try_open',
					sub { $calls++ ? (0, Errno::ENOSPC()) : $orig->(@_) });
				is(can_revoke_read($dir), 0, 'answer 0');
				my $why = why_not('read', $dir);
				like($why, qr/failed for a reason other than permissions: \Q$text\E\z/, "reason carries the $locale errno text");
			}
			throws_ok { can_revoke('bogus', $dir) } qr/^Unknown access kind 'bogus'/, 'croak texts are unchanged';
			like(permissions_report($dir), qr/^Test::Permissions /, 'the report is produced');
			clear_cache();
		};
	}
}
POSIX::setlocale(POSIX::LC_ALL(), $saved);

done_testing();
