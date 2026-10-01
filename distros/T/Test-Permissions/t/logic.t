#!/usr/bin/env perl

# The decision logic, as a truth table.  From the FORMAL SPECIFICATION:
#
#	answer = 1  <=>  setup = ok  AND  baseline = ok  AND  modeSet
#	                 AND  attempt in { EACCES, EPERM }  AND  cleanup = ok
#	answer = 1  <=>  reason = undef
#
# Premises checked for every combination:
#	P1  the answer is 1 exactly when every conjunct holds;
#	P2  the reason is undef exactly when the answer is 1;
#	P3  the reason names the first step that failed (a cleanup failure
#	    is appended to it);
#	P4  whatever the combination, nothing is left in dir;
#	P5  sticky: without the precondition (root), the answer is 0 whatever
#	    else happens, and nothing is created;
#	P6  acl_denies = modeAllows AND NOT access.

use strict;
use warnings;

use Errno ();
use File::Temp ();
use Test::Mockingbird ();
use Test::Most;
use Test::Warnings;

use lib 'lib';
use Test::Permissions qw(:all);

my $dir = File::Temp::tempdir(CLEANUP => 1);

sub listing {
	opendir(my $dh, $_[0]) or die;
	return [ sort grep { !/^\.\.?$/ } readdir $dh ];
}

my %ATTEMPT = (
	ok     => [ 1, 0 ],
	EACCES => [ 0, Errno::EACCES() ],
	EPERM  => [ 0, Errno::EPERM() ],
	ENOSPC => [ 0, Errno::ENOSPC() ],
	throws => 'die',
);

my $combinations = 0;
for my $kind (qw(read write create search exec delete)) {
	for my $setup (0, 1) {
		for my $baseline (0, 1) {
			for my $mode_set (0, 1) {
				for my $attempt (sort keys %ATTEMPT) {
					for my $cleanup (0, 1) {
						check($kind, $setup, $baseline, $mode_set, $attempt, $cleanup);
						$combinations++;
					}
				}
			}
		}
	}
}
is($combinations, 6 * 2 * 2 * 2 * 5 * 2, 'every combination checked');

# chmod_works(): make chmod behave as on Unix whatever the platform, so a
# scenario reaches the step it is about.  (On Windows chmod 0 leaves mode
# 0444, and the probe would stop at the mode check.)  _mode_of reports the
# mode last given to _set_mode.  Returns the guards.
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

sub check {
	my ($kind, $setup, $baseline, $mode_set, $attempt, $cleanup) = @_;
	my $name = "$kind setup=$setup baseline=$baseline modeSet=$mode_set attempt=$attempt cleanup=$cleanup";

	my @guards;
	push @guards, Test::Mockingbird::mock_scoped('Test::Permissions', '_make_probe_dir', sub { die "no setup\n" })
		unless $setup;
	for my $seam (qw(_try_open _try_stat _try_exec _try_unlink)) {
		# The exec probe's real baseline runs a /bin/sh script, which is
		# impossible on Windows; these scenarios are about later steps, so
		# its baseline is simulated as a successful run everywhere.
		my $orig = $seam eq '_try_exec' ? sub { (1, 0) } : \&{"Test::Permissions::$seam"};
		my $calls = 0;
		push @guards, Test::Mockingbird::mock_scoped('Test::Permissions', $seam, sub {
			if($calls++ == 0) {
				return $baseline ? $orig->(@_) : (0, Errno::EIO());
			}
			my $how = $ATTEMPT{$attempt};
			die "attempt threw\n" unless ref $how;
			return @{$how};
		});
	}
	if($mode_set) {
		push @guards, chmod_works();
	} else {
		push @guards, Test::Mockingbird::mock_scoped('Test::Permissions', '_mode_of', sub { 0777 });
	}
	unless($cleanup) {
		my $orig = \&Test::Permissions::_cleanup;
		push @guards, Test::Mockingbird::mock_scoped('Test::Permissions', '_cleanup', sub { $orig->(@_); 'cleanup broke' });
	}

	clear_cache();
	my $answer = can_revoke($kind, $dir);
	my $why = why_not($kind, $dir);
	@guards = ();

	my $expected = ($setup && $baseline && $mode_set && ($attempt eq 'EACCES' || $attempt eq 'EPERM') && $cleanup) ? 1 : 0;
	is($answer, $expected, "P1 answer: $name");
	is(defined $why ? 0 : 1, $answer, "P2 reason iff 0: $name");

	if(!$answer) {
		my $first = !$setup ? qr/^Could not set up/
			: !$baseline ? qr/^\w+ access fails .* even when it is allowed/
			: !$mode_set ? qr/^chmod did not set mode/
			: $attempt eq 'ok' ? qr/^chmod cannot revoke/
			: $attempt eq 'ENOSPC' ? qr/failed for a reason other than permissions/
			: $attempt eq 'throws' ? qr/^Could not set up .*attempt threw/
			: qr/^chmod revoked/;
		like($why, $first, "P3 first failure named: $name");
		like($why, qr/; also could not clean up '.*': cleanup broke\z/, "P3 cleanup appended: $name") unless $cleanup;
	}
	is_deeply(listing($dir), [], "P4 nothing left: $name");
}

subtest 'P5 sticky precondition' => sub {
	for my $root (0, 1) {
		for my $attempt (qw(ok EPERM)) {
			clear_cache();
			my $calls = 0;
			my @g = (
				Test::Mockingbird::mock_scoped('Test::Permissions', '_can_switch_uid', sub { $root }),
				Test::Mockingbird::mock_scoped('Test::Permissions', '_give_away', sub { 1 }),
				Test::Mockingbird::mock_scoped('Test::Permissions', '_mode_of', sub { 01777 }),
				Test::Mockingbird::mock_scoped('Test::Permissions', '_try_unlink', sub {
					return $calls++ ? @{ $ATTEMPT{$attempt} } : do { unlink $_[0]; (1, 0) };
				}),
			);
			my $expected = $root && $attempt eq 'EPERM' ? 1 : 0;
			is(can_revoke('sticky', $dir), $expected, "root=$root attempt=$attempt");
			is($calls, 0, "root=$root: no operation without the precondition") unless $root;
			is_deeply(listing($dir), [], "root=$root attempt=$attempt: nothing left");
		}
	}
	clear_cache();
};

subtest 'P6 acl_denies truth table' => sub {
	my $file = "$dir/acl";
	open(my $fh, '>', $file) or die $!;
	close $fh;
	for my $allows (0, 1) {
		for my $access (0, 1) {
			my @g = (
				Test::Mockingbird::mock_scoped('Test::Permissions', '_mode_allows', sub { $allows }),
				Test::Mockingbird::mock_scoped('Test::Permissions', '_access', sub { $access }),
			);
			is(acl_denies(read => $file), ($allows && !$access) ? 1 : 0, "modeAllows=$allows access=$access");
		}
	}
	unlink $file;
};

clear_cache();
done_testing();
