#!/usr/bin/env perl

# The cache as a state machine (see STATE DIAGRAM in the POD).  For one
# (kind, dir) key the states are:
#
#	EMPTY       - never probed, or cleared
#	CACHED_YES  - probed, answer 1
#	CACHED_NO   - probed, answer 0, with a reason
#
# Each allowed edge is tested, and so is each forbidden one: a cached
# answer never changes without clear_cache, whatever happens to the
# environment.

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

# The environment the next probe will see: 'yes' (attempt denied) or 'no'
# (attempt succeeds, as for root).
my $environment = 'yes';
my $probes = 0;
my $orig_open = \&Test::Permissions::_try_open;
my $orig_probe = \&Test::Permissions::_probe;
my $attempt = 0;
my @chmod_guards = chmod_works();
Test::Mockingbird::mock('Test::Permissions', '_probe', sub { $probes++; $attempt = 0; $orig_probe->(@_) });
Test::Mockingbird::mock('Test::Permissions', '_try_open', sub {
	return $orig_open->(@_) unless $attempt++;
	return $environment eq 'yes' ? (0, Errno::EACCES()) : (1, 0);
});

# state_of($kind): the observable state, found without probing: a probe
# during the check means EMPTY.
sub state_of {
	my ($kind) = @_;
	my $before = $probes;
	my $answer = can_revoke($kind, $dir);
	my $state = $answer ? 'CACHED_YES' : 'CACHED_NO';
	return $probes > $before ? 'EMPTY' : $state;
}

# probes_during($code): how many probes $code ran.
sub probes_during {
	my ($code) = @_;
	my $before = $probes;
	$code->();
	return $probes - $before;
}

subtest 'EMPTY --can_revoke--> CACHED_YES' => sub {
	clear_cache();
	$environment = 'yes';
	is(probes_during(sub { is(can_revoke('read', $dir), 1, 'answer 1') }), 1, 'one probe');
	is(state_of('read'), 'CACHED_YES', 'state');
};

subtest 'EMPTY --can_revoke--> CACHED_NO' => sub {
	clear_cache();
	$environment = 'no';
	is(probes_during(sub { is(can_revoke('read', $dir), 0, 'answer 0') }), 1, 'one probe');
	is(state_of('read'), 'CACHED_NO', 'state');
};

for my $entry (
	[ 'can_revoke_read', sub { can_revoke_read($dir) } ],
	[ 'why_not', sub { why_not('read', $dir) } ],
	[ 'skip_unless_can_revoke', sub { SKIP: { skip_unless_can_revoke('read', 1, $dir); pass('block ran') } } ],
) {
	my ($name, $call) = @{$entry};
	subtest "EMPTY --$name--> CACHED_YES" => sub {
		clear_cache();
		$environment = 'yes';
		is(probes_during($call), 1, 'one probe');
		is(state_of('read'), 'CACHED_YES', 'state');
	};
}

subtest 'CACHED_YES --any query--> CACHED_YES (no probe)' => sub {
	clear_cache();
	$environment = 'yes';
	can_revoke('read', $dir);
	$environment = 'no';	# the environment changes: the cache must not notice
	is(probes_during(sub {
		can_revoke('read', $dir);
		can_revoke_read($dir);
		why_not('read', $dir);
		SKIP: { skip_unless_can_revoke('read', 1, $dir); pass('block ran') }
	}), 0, 'no probe');
	is(state_of('read'), 'CACHED_YES', 'forbidden edge CACHED_YES -> CACHED_NO not taken');
};

subtest 'CACHED_NO --any query--> CACHED_NO (no probe)' => sub {
	clear_cache();
	$environment = 'no';
	can_revoke('read', $dir);
	my $why = why_not('read', $dir);
	$environment = 'yes';
	is(probes_during(sub {
		can_revoke('read', $dir);
		is(why_not('read', $dir), $why, 'same reason');
		SKIP: { skip_unless_can_revoke('read', 1, $dir); fail('not reached') }
	}), 0, 'no probe');
	is(state_of('read'), 'CACHED_NO', 'forbidden edge CACHED_NO -> CACHED_YES not taken');
};

subtest 'CACHED_* --clear_cache--> EMPTY' => sub {
	for my $env (qw(yes no)) {
		clear_cache();
		$environment = $env;
		can_revoke('read', $dir);
		clear_cache();
		is(state_of('read'), 'EMPTY', "from CACHED_\U$env\E");
	}
	clear_cache();
	is(state_of('read'), 'EMPTY', 'EMPTY --clear_cache--> EMPTY');
};

subtest 'a croak does not change the state' => sub {
	clear_cache();
	$environment = 'yes';
	eval { can_revoke('bogus', $dir) };
	eval { can_revoke('read', "$dir/missing") };
	eval { skip_unless_can_revoke('read', 0, $dir) };
	is(probes_during(sub { 1 }), 0, 'no probe');
	is(state_of('read'), 'EMPTY', 'still EMPTY');
};

subtest 'set_messages does not change the state or cached reasons' => sub {
	clear_cache();
	$environment = 'no';
	my $why = why_not('read', $dir);
	set_messages(reason_not_enforced => 'NEW %s %s');
	is(why_not('read', $dir), $why, 'cached reason keeps the old wording');
	clear_cache();
	like(why_not('read', $dir), qr/^NEW read /, 'new wording after clear_cache');
	set_messages(reason_not_enforced => q{chmod cannot revoke %s access in '%s' (running as root, or the filesystem ignores permissions)});
};

subtest 'keys are independent' => sub {
	clear_cache();
	$environment = 'yes';
	can_revoke('read', $dir);
	$environment = 'no';
	is(state_of('write'), 'EMPTY', 'another kind is EMPTY');
	my $other = File::Temp::tempdir(CLEANUP => 1);
	is(probes_during(sub { can_revoke('read', $other) }), 1, 'another dir is EMPTY');
	is(can_revoke('read', $other), 0, '... and got its own answer');
	is(can_revoke('read', $dir), 1, 'the first key kept its answer');
};

subtest 'set_cache_scope changes which key is used, not any state' => sub {
	clear_cache();
	$environment = 'yes';
	my $sibling = File::Temp::tempdir(DIR => $dir, CLEANUP => 1);
	can_revoke('read', $dir);
	is(probes_during(sub { can_revoke('read', $sibling) }), 1, 'directory scope: a sibling directory is EMPTY');
	clear_cache();
	set_cache_scope('device');
	can_revoke('read', $dir);
	$environment = 'no';
	is(probes_during(sub { is(can_revoke('read', $sibling), 1, 'answer shared') }), 0,
		'device scope: a directory on the same device is CACHED_YES');
	set_cache_scope('directory');
	is(probes_during(sub { can_revoke('read', $sibling) }), 1, 'back to directory scope: EMPTY again');
	clear_cache();
};

SKIP: {
	skip 'changing the effective uid needs real root', 1 unless $< == 0 && $> == 0 && $^O ne 'MSWin32';
	subtest 'a new effective uid uses a new key' => sub {
		clear_cache();
		$environment = 'yes';
		# The other uid must be able to reach the directory: root's TMPDIR
		# may be private (pam_tmpdir makes /tmp/user/0 mode 0700).
		my $shared = (-d '/tmp' && -w _) ? File::Temp::tempdir(DIR => '/tmp', CLEANUP => 1) : $dir;
		chmod 0755, $shared;
		can_revoke('read', $shared);
		{
			local $> = 65534;
			if($> != 65534) {
				pass('could not change the effective uid here (a one-uid user namespace)');
			} elsif(!-d $shared) {
				pass("uid 65534 cannot reach $shared");
			} else {
				is(probes_during(sub { can_revoke('read', $shared) }), 1, 'probed again as the other user');
			}
		}
		is(probes_during(sub { can_revoke('read', $shared) }), 0, "root's entry is still CACHED");
		clear_cache();
	};
}

@chmod_guards = ();
Test::Mockingbird::restore_all();
clear_cache();
done_testing();
