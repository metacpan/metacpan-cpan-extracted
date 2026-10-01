#!/usr/bin/env perl

# Every croak, and every reason for a 0 answer.  The reasons are produced
# by mocking the probe's seams, so each environment in the specification
# (root, Windows, a broken filesystem, ...) is simulated on any machine.

use strict;
use warnings;

use Errno ();
use File::Temp ();
use Test::Mockingbird ();
use Test::Most;
use Test::Warnings;

use lib 'lib';
use Test::Permissions qw(:all);

# The kinds one user can probe.  sticky needs root, and has its own
# subtest below.
my @KINDS = qw(read write create search exec delete);
my %RESTRICTED = (read => 0, write => 0400, create => 0500, search => 0, exec => 0600, delete => 0500);
my @OP_SEAMS = qw(_try_open _try_stat _try_exec _try_unlink);

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

# simulate(%how)
#
# Mocks the seams so that a probe sees the given outcomes.  Returns the
# guards; the mocks are removed when they go out of scope.
#   baseline, attempt => 'real' (default) | 'die' | [ ok, errno ]
#   mode              => what _mode_of returns
#   make_probe_dir    => true to make it die
#   restore           => 'die' or 'false' to make the restoring _set_mode fail
#                        (needs kind, to recognise the restricting chmod)
sub simulate {
	my (%how) = @_;
	my @guards;
	push @guards, chmod_works() unless exists $how{mode};

	for my $seam (@OP_SEAMS) {
		# The exec probe's real baseline runs a /bin/sh script, which is
		# impossible on Windows; these scenarios are about later steps, so
		# its baseline is simulated as a successful run everywhere.
		my $orig = $seam eq '_try_exec' ? sub { (1, 0) } : \&{"Test::Permissions::$seam"};
		my $calls = 0;
		push @guards, Test::Mockingbird::mock_scoped('Test::Permissions', $seam, sub {
			my $step = $calls++ ? 'attempt' : 'baseline';
			my $want = $how{$step};
			return $orig->(@_) if !defined $want || $want eq 'real';
			die "simulated $step exception\n" if $want eq 'die';
			return @{$want};
		});
	}
	if(exists $how{mode}) {
		push @guards, Test::Mockingbird::mock_scoped('Test::Permissions', '_mode_of', sub { $how{mode} });
	}
	if($how{make_probe_dir}) {
		push @guards, Test::Mockingbird::mock_scoped('Test::Permissions', '_make_probe_dir',
			sub { die "simulated mkdir failure\n" });
	}
	if($how{restore}) {
		my $orig = \&Test::Permissions::_set_mode;
		my $armed = 0;
		push @guards, Test::Mockingbird::mock_scoped('Test::Permissions', '_set_mode', sub {
			my ($path, $mode) = @_;
			if($armed) {
				$orig->(@_);	# really restore, so the directory can be removed
				die "simulated restore failure\n" if $how{restore} eq 'die';
				return 0;
			}
			$armed = 1 if $mode == $RESTRICTED{ $how{kind} };
			return $orig->(@_);
		});
	}
	return @guards;
}

sub errno_text { local $! = shift; return "$!" }

sub listing {
	my ($dir) = @_;
	opendir(my $dh, $dir) or die "$dir: $!";
	my @names = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
	closedir $dh;
	return \@names;
}

my $dir = File::Temp::tempdir(CLEANUP => 1);

subtest 'caller errors croak with the documented messages' => sub {
	throws_ok { can_revoke('chown', $dir) }
		qr/\AUnknown access kind 'chown'; expected one of: read, write, create, search, exec, delete, sticky at \Q$0\E line/,
		'error_unknown_kind, reported from the caller';
	throws_ok { can_revoke_read("$dir/missing") } qr/is not a directory/, 'error_not_a_directory: missing';
	my $file = "$dir/plain";
	open(my $fh, '>', $file) or die $!;
	close $fh;
	throws_ok { can_revoke_read($file) } qr/\A'\Q$file\E' is not a directory/, 'error_not_a_directory: a file';
	unlink $file;
	throws_ok { set_messages(no_such_key => 'x') } qr/\AUnknown message key 'no_such_key'/, 'error_unknown_message';
	throws_ok { can_revoke_read($dir, 'extra') }
		qr/\AToo many arguments: expected at most 1, got 2/, 'error_too_many_arguments';
	throws_ok { can_revoke() } qr/Required parameter 'kind' is missing/, 'missing kind (validator)';
	throws_ok { can_revoke_read([]) } qr/'dir' must be a string/, 'dir as a reference (validator)';
	throws_ok { can_revoke_read('') } qr/'dir' too short/, 'empty dir (validator)';
	throws_ok { skip_unless_can_revoke('read') } qr/'count' is missing/, 'missing count (validator)';
	throws_ok { skip_unless_can_revoke('read', 0) } qr/'count'/, 'count 0 (validator)';
	throws_ok { skip_unless_can_revoke('read', -1) } qr/'count'/, 'negative count (validator)';
	throws_ok { skip_unless_can_revoke('read', 1.5) } qr/'count'/, 'fractional count (validator)';
	throws_ok { set_messages(reason_other_error => '') } qr/too short/, 'empty message text';
	throws_ok { set_messages(reason_other_error => undef) } qr/reason_other_error/, 'undef message text';
	throws_ok { set_messages(reason_other_error => []) } qr/must be a string/, 'reference as message text';
	throws_ok { set_messages('odd') } qr/Usage/, 'odd argument list';
	unlike($@, qr/Permissions\.pm line/, 'no internal location in the message');
};

subtest 'control and bidi characters are escaped in croak texts' => sub {
	throws_ok { can_revoke("r\e[2J\x{202E}") } qr/'r\\x\{1B\}\[2J\\x\{202E\}'/, 'kind';
	throws_ok { can_revoke_read("$dir/no\nsuch") } qr/no\\x\{A\}such/, 'dir';
	throws_ok { set_messages("k\x{7}" => 'x') } qr/'k\\x\{7\}'/, 'message key';
};

# The scenario table from the specification.
my @scenarios = (
	{ name => 'normal user (EACCES)', how => { attempt => [0, Errno::EACCES()] }, answer => 1 },
	{ name => 'EPERM instead of EACCES', how => { attempt => [0, Errno::EPERM()] }, answer => 1 },
	{ name => 'root / CAP_DAC_OVERRIDE', how => { attempt => [1, 0] }, answer => 0,
		reason => qr/\Achmod cannot revoke \w+ access in '.*' \(running as root, or the filesystem ignores permissions\)\z/ },
	{ name => 'broken filesystem', how => { baseline => [0, Errno::EIO()] }, answer => 0,
		reason => qr/\A\w+ access fails in '.*' even when it is allowed: \Q${\ errno_text(Errno::EIO()) }\E\z/ },
	{ name => 'odd errno', how => { attempt => [0, Errno::ENOSPC()] }, answer => 0,
		reason => qr/\A\w+ access in '.*' failed for a reason other than permissions: \Q${\ errno_text(Errno::ENOSPC()) }\E\z/ },
	{ name => 'cannot create probe directory', how => { make_probe_dir => 1 }, answer => 0,
		reason => qr/\ACould not set up the \w+ probe in '.*': simulated mkdir failure\z/ },
	{ name => 'restore dies', how => { attempt => [0, Errno::EACCES()], restore => 'die' }, answer => 0,
		reason => qr/\Achmod revoked \w+ access in '.*'; also could not clean up '.*': simulated restore failure\z/ },
	{ name => 'restore returns false', how => { attempt => [1, 0], restore => 'false' }, answer => 0,
		reason => qr/\Achmod cannot revoke .*; also could not clean up '.*': /s },
	{ name => 'exception mid-probe', how => { attempt => 'die' }, answer => 0,
		reason => qr/\ACould not set up the \w+ probe in '.*': simulated attempt exception\z/ },
	{ name => 'exception in the baseline', how => { baseline => 'die' }, answer => 0,
		reason => qr/simulated baseline exception/ },
);

for my $scenario (@scenarios) {
	for my $kind (@KINDS) {
		subtest "$scenario->{name}: $kind" => sub {
			clear_cache();
			my $before = listing($dir);
			my ($answer, $why);
			{
				my @guards = simulate(kind => $kind, %{ $scenario->{how} });
				$answer = can_revoke($kind, $dir);
				$why = why_not($kind, $dir);
			}
			is($answer, $scenario->{answer}, 'answer');
			if($scenario->{answer}) {
				ok(!defined $why, 'why_not is undef');
			} else {
				like($why, $scenario->{reason}, 'reason');
				like($why, qr/\Q$kind\E/, 'reason names the kind') unless $scenario->{how}{mode};
			}
			is_deeply(listing($dir), $before, 'nothing left in dir');
		};
	}
}

subtest 'Windows: chmod does not change the mode' => sub {
	for my $kind (qw(read search)) {
		clear_cache();
		my @guards = simulate(mode => 0444);
		is(can_revoke($kind, $dir), 0, "$kind: answer 0");
		like(why_not($kind, $dir), qr/\Achmod did not set mode 0000 in '.*' \(got 0444\)\z/, "$kind: reason_chmod_ignored");
	}
	clear_cache();
	{
		my @guards = simulate(mode => 0444, attempt => [0, Errno::EACCES()]);
		is(can_revoke('write', $dir), 1, 'write: 0444 has the owner bits of 0400, so the probe goes on');
	}
	clear_cache();
	{
		my @guards = simulate(mode => 0755);
		is(can_revoke('create', $dir), 0, 'create: 0755 is not 0500');
		like(why_not('create', $dir), qr/mode 0500 .* \(got 0755\)/, 'reason shows both modes');
	}
	clear_cache();
	{
		my @guards = simulate(mode => undef);
		is(can_revoke('read', $dir), 0, 'stat failing after chmod gives 0');
		like(why_not('read', $dir), qr/\ACould not set up the read probe/, 'as reason_setup_failed');
	}
};

subtest 'exception mid-probe: modes restored and probe directory removed' => sub {
	clear_cache();
	my @set;
	my $orig = \&Test::Permissions::_set_mode;
	my $probe_dir;
	my $mk = \&Test::Permissions::_make_probe_dir;
	{
		my $g1 = Test::Mockingbird::mock_scoped('Test::Permissions', '_set_mode', sub { push @set, [ @_ ]; $orig->(@_) });
		my $g2 = Test::Mockingbird::mock_scoped('Test::Permissions', '_make_probe_dir', sub { $probe_dir = $mk->(@_) });
		my @guards = simulate(attempt => 'die');
		is(can_revoke('search', $dir), 0, 'answer 0');
	}
	is($set[-1][1], 0700, 'last chmod restores the permissive mode');
	is($set[-1][0], $set[-2][0], 'on the path that was restricted');
	ok(defined $probe_dir && !-e $probe_dir, 'probe directory removed');
};

subtest 'probes never croak, die or warn' => sub {
	clear_cache();
	my @guards = simulate(make_probe_dir => 1);
	lives_ok { can_revoke_read($dir) } 'can_revoke_read';
	lives_ok { why_not('write', $dir) } 'why_not';
	SKIP: {
		lives_ok { skip_unless_can_revoke('create', 1, $dir) } 'skip_unless_can_revoke';
		fail('not reached: the probe failed so the block was skipped');
	}
};

subtest 'a translated message with the wrong number of arguments does not warn' => sub {
	clear_cache();
	set_messages(reason_setup_failed => 'setup %s');
	my @guards = simulate(make_probe_dir => 1);
	is(why_not('read', $dir), 'setup read', 'extra arguments ignored');
	clear_cache();
	set_messages(reason_setup_failed => 'setup %s %s %s %s %s');
	like(why_not('read', $dir), qr/\Asetup read /, 'missing arguments become empty');
	set_messages(reason_setup_failed => q{Could not set up the %s probe in '%s': %s});
};

subtest 'sticky: needs root, and every outcome by mocking' => sub {
	clear_cache();
	{
		my $g = Test::Mockingbird::mock_scoped('Test::Permissions', '_can_switch_uid', sub { 0 });
		is(can_revoke_sticky($dir), 0, 'not root: 0');
		like(why_not('sticky', $dir), qr/\AThe sticky probe in '.*' must act as two users, which needs root \(not Windows\)\z/,
			'reason_needs_root');
		is_deeply(listing($dir), [], 'nothing created when the precondition fails');
	}
	for my $case (
		[ 'EPERM from the other user', [ 0, Errno::EPERM() ], 1, undef ],
		[ 'sticky bit ignored', [ 1, 0 ], 0, qr/^chmod cannot revoke sticky access/ ],
		[ 'odd errno', [ 0, Errno::EROFS() ], 0, qr/other than permissions/ ],
	) {
		my ($name, $attempt, $answer, $reason) = @{$case};
		clear_cache();
		my $calls = 0;
		my @g = (
			chmod_works(),
			Test::Mockingbird::mock_scoped('Test::Permissions', '_can_switch_uid', sub { 1 }),
			Test::Mockingbird::mock_scoped('Test::Permissions', '_give_away', sub { 1 }),
			Test::Mockingbird::mock_scoped('Test::Permissions', '_try_unlink', sub {
				my ($path, $as) = @_;
				is($as, 65533, "$name: acts as the other user") if $calls == 0;
				return $calls++ ? @{$attempt} : do { unlink $path; (1, 0) };
			}),
		);
		is(can_revoke('sticky', $dir), $answer, "$name: answer");
		if($reason) {
			like(why_not('sticky', $dir), $reason, "$name: reason");
		}
		is_deeply(listing($dir), [], "$name: nothing left");
	}
	clear_cache();
	{
		my @g = (
			Test::Mockingbird::mock_scoped('Test::Permissions', '_can_switch_uid', sub { 1 }),
			Test::Mockingbird::mock_scoped('Test::Permissions', '_give_away', sub { die "chown refused\n" }),
		);
		like(why_not('sticky', $dir), qr/^Could not set up the sticky probe .*: chown refused$/, 'chown fails: reason_setup_failed');
	}
	clear_cache();
	{
		my @g = (
			Test::Mockingbird::mock_scoped('Test::Permissions', '_can_switch_uid', sub { 1 }),
			Test::Mockingbird::mock_scoped('Test::Permissions', '_give_away', sub { 1 }),
			Test::Mockingbird::mock_scoped('Test::Permissions', '_mode_of', sub { 0777 }),
			Test::Mockingbird::mock_scoped('Test::Permissions', '_try_unlink', sub { unlink $_[0]; (1, 0) }),
		);
		like(why_not('sticky', $dir), qr/^chmod did not set mode 1777 .* \(got 0777\)$/, 'sticky bit not kept: reason_chmod_ignored');
	}
	clear_cache();
};

subtest 'acl_denies croaks' => sub {
	throws_ok { acl_denies('create', $dir) } qr/^Unknown access kind 'create'; expected one of: read, write, exec at /, 'kind outside read/write/exec';
	throws_ok { acl_denies('read', "$dir/missing") } qr/^'.*missing' does not exist at /, 'error_no_such_path';
	throws_ok { acl_denies('read') } qr/Required parameter 'path'/, 'path missing';
	throws_ok { acl_denies('read', $dir, 'x') } qr/^Too many arguments: expected at most 2, got 3/, 'too many';
};

subtest 'with_revoked croaks' => sub {
	my $file = "$dir/wr";
	open(my $fh, '>', $file) or die $!;
	close $fh;
	throws_ok { with_revoked('sticky', $file, sub { 1 }) }
		qr/^Unknown access kind 'sticky'; expected one of: read, write, create, search, exec, delete at /, 'sticky refused';
	throws_ok { with_revoked('read', "$dir/missing", sub { 1 }) } qr/does not exist/, 'error_no_such_path';
	throws_ok { with_revoked('read', $dir, sub { 1 }) } qr/^'.*' is a directory; read access is revoked on a file at /, 'error_not_a_file';
	throws_ok { with_revoked('search', $file, sub { 1 }) } qr/^'.*wr' is not a directory at /, 'error_not_a_directory';
	throws_ok { with_revoked('read', $file, 'not code') } qr/'code'/, 'code must be a code reference';
	{
		my $g = Test::Mockingbird::mock_scoped('Test::Permissions', '_set_mode', sub { die "no chmod\n" });
		my $ran = 0;
		throws_ok { with_revoked('read', $file, sub { $ran++ }) } qr/^Could not chmod '.*wr' to 0000: no chmod at /, 'error_chmod_failed';
		is($ran, 0, '... and the code did not run');
	}
	{
		my $orig = \&Test::Permissions::_set_mode;
		my $calls = 0;
		my $g = Test::Mockingbird::mock_scoped('Test::Permissions', '_set_mode', sub { $calls++ ? die "stuck\n" : $orig->(@_) });
		throws_ok { with_revoked('read', $file, sub { die "code died\n" }) } qr/^Could not restore mode 0\d{3} on '.*wr': stuck at /,
			'error_restore_failed wins over the code exception';
		chmod 0600, $file;
	}
	unlink $file;
};

subtest 'set_cache_scope and permissions_report croak' => sub {
	throws_ok { set_cache_scope('inode') } qr/'scope'/, 'unknown scope';
	throws_ok { set_cache_scope() } qr/Required parameter 'scope'/, 'missing scope';
	throws_ok { permissions_report("$dir/missing") } qr/is not a directory/, 'report: not a directory';
};

clear_cache();
done_testing();
