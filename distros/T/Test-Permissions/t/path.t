#!/usr/bin/env perl

# One case per control-flow path through the module.  %ledger lists every
# path; the last test checks each was taken.  A new branch needs a ledger
# entry.

use strict;
use warnings;

use Carp ();
use Cwd ();
use Errno ();
use File::Spec ();
use File::Temp ();
use Test::Mockingbird ();
use Test::Most;
use Test::Warnings;

use lib 'lib';
use Test::Permissions ();

my %ledger = map { $_ => 0 } qw(
	args.hashref args.named args.positional args.none args.too_many args.get_params_croak
	args.unknown_kind args.validator_error args.not_a_directory args.default_dir args.object
	cache.miss cache.hit
	probe.make_probe_dir_throws probe.setup_throws probe.baseline_fails probe.tidy_throws
	probe.mode_of_undef probe.mode_mismatch probe.attempt_succeeds probe.attempt_eacces
	probe.attempt_eperm probe.attempt_other probe.attempt_throws
	cleanup.ok_answer1 cleanup.fail_answer1 cleanup.fail_answer0 cleanup.restore_false
	cleanup.remove_tree_throws cleanup.remove_tree_errors cleanup.no_probe_dir
	skip.answer1 skip.answer0
	msg.default msg.override msg.sprintf_dies
	printable.chars printable.utf8_bytes printable.other_bytes
	messages.empty messages.unknown_key messages.invalid_value messages.get_params_croak messages.ok
	args.path_missing args.path_ok
	probe.precondition_fails probe.sticky_bits
	exec.runs exec.cannot_run exec.bad_exit
	unlink.plain unlink.chdir_fails unlink.cannot_switch
	skip.test2
	acl.root acl.owner acl.group acl.other acl.mode_denies acl.access_denies acl.allowed
	guard.file_on_dir guard.dir_on_file guard.chmod_fails guard.restore_fails guard.code_dies
	guard.list guard.scalar guard.void
	scope.directory scope.device scope.device_stat_fails
	report.yes report.no
);

sub path { $ledger{$_[0]}++; return }

my $dir = File::Temp::tempdir(CLEANUP => 1);
my $canon = Cwd::abs_path($dir);

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

# attempt_is(@result): the attempt (second op call) returns @result, or
# dies if @result is ('die').
sub attempt_is {
	my @result = @_;
	my @guards = chmod_works();
	for my $seam (qw(_try_open _try_stat _try_exec _try_unlink)) {
		# The exec probe's real baseline runs a /bin/sh script, which is
		# impossible on Windows; these scenarios are about later steps, so
		# its baseline is simulated as a successful run everywhere.
		my $orig = $seam eq '_try_exec' ? sub { (1, 0) } : \&{"Test::Permissions::$seam"};
		my $calls = 0;
		push @guards, Test::Mockingbird::mock_scoped('Test::Permissions', $seam, sub {
			return $orig->(@_) unless $calls++;
			die "attempt died\n" if $result[0] eq 'die';
			return @result;
		});
	}
	return @guards;
}

sub probe { return [ Test::Permissions::_probe($_[0], $canon) ] }

# ---- argument handling ----------------------------------------------------

is(Test::Permissions::can_revoke_read({ dir => $dir }), Test::Permissions::can_revoke_read($dir), 'hashref');
path('args.hashref');
path('args.positional');
lives_ok { Test::Permissions::can_revoke_read(dir => $dir) } 'named';
path('args.named');
my ($p) = Test::Permissions::_check_args('dir', []);
is($p->{dir}, File::Spec->tmpdir, 'no arguments: default dir');
path('args.none');
path('args.default_dir');
throws_ok { Test::Permissions::can_revoke_read(1, 2) } qr/Too many/, 'too many';
path('args.too_many');
throws_ok { Test::Permissions::can_revoke({ kind => 'read' }, 'x', 'y') } qr/Too many/, 'hashref plus extras: positional too many';
{
	my $g = Test::Mockingbird::mock_scoped('Params::Get', 'get_params', sub { Carp::croak('Usage: bad') });
	throws_ok { Test::Permissions::can_revoke_read($dir) } qr/^Usage: bad at /, 'Params::Get croak passed on';
}
path('args.get_params_croak');
throws_ok { Test::Permissions::can_revoke('nope') } qr/Unknown access kind/, 'unknown kind';
path('args.unknown_kind');
throws_ok { Test::Permissions::can_revoke_read('') } qr/too short/, 'validator error';
path('args.validator_error');
throws_ok { Test::Permissions::can_revoke_read("$dir/x") } qr/is not a directory/, 'not a directory';
path('args.not_a_directory');
{
	package Str;
	use overload q{""} => sub { ${ $_[0] } }, fallback => 1;
}
lives_ok { Test::Permissions::can_revoke_read(bless \(my $s = $dir), 'Str') } 'object stringified';
path('args.object');

# ---- cache ----------------------------------------------------------------

Test::Permissions::clear_cache();
{
	my $spy = Test::Mockingbird::spy('Test::Permissions', '_probe');
	Test::Permissions::can_revoke_read($dir);
	is(scalar(my @c = $spy->()), 1, 'miss: probed');
	path('cache.miss');
	Test::Permissions::can_revoke_read($dir);
	is(scalar(@c = $spy->()), 1, 'hit: not probed again');
	path('cache.hit');
	Test::Mockingbird::restore_all();
}

# ---- _probe ---------------------------------------------------------------

{
	my $g = Test::Mockingbird::mock_scoped('Test::Permissions', '_make_probe_dir', sub { die "mk\n" });
	like(probe('read')->[1], qr/^Could not set up the read probe .*: mk$/, '_make_probe_dir throws');
	path('probe.make_probe_dir_throws');
}
{
	my $g = Test::Mockingbird::mock_scoped('Test::Permissions', '_setup_file', sub { die "setup\n" });
	like(probe('read')->[1], qr/: setup$/, 'setup throws after P exists');
	path('probe.setup_throws');
}
{
	my $g = Test::Mockingbird::mock_scoped('Test::Permissions', '_try_stat', sub { (0, Errno::EIO()) });
	like(probe('search')->[1], qr/even when it is allowed/, 'baseline fails');
	path('probe.baseline_fails');
}
{
	# The create probe's tidy step unlinks the file the baseline created;
	# a baseline that reports success without creating it makes tidy throw.
	my $g = Test::Mockingbird::mock_scoped('Test::Permissions', '_try_open', sub { (1, 0) });
	like(probe('create')->[1], qr/^Could not set up the create probe/, 'tidy throws');
	path('probe.tidy_throws');
}
{
	my $g = Test::Mockingbird::mock_scoped('Test::Permissions', '_mode_of', sub { undef });
	like(probe('write')->[1], qr/^Could not set up the write probe/, '_mode_of undef');
	path('probe.mode_of_undef');
}
{
	my $g = Test::Mockingbird::mock_scoped('Test::Permissions', '_mode_of', sub { 0600 });
	like(probe('write')->[1], qr/^chmod did not set mode 0400 .* \(got 0600\)$/, 'mode mismatch');
	path('probe.mode_mismatch');
}
{
	my @g = attempt_is(1, 0);
	like(probe('read')->[1], qr/^chmod cannot revoke read access/, 'attempt succeeds');
	path('probe.attempt_succeeds');
}
{
	my @g = attempt_is(0, Errno::EACCES());
	is_deeply(probe('read'), [ 1, undef ], 'attempt EACCES');
	path('probe.attempt_eacces');
	path('cleanup.ok_answer1');
}
{
	my @g = attempt_is(0, Errno::EPERM());
	is_deeply(probe('write'), [ 1, undef ], 'attempt EPERM');
	path('probe.attempt_eperm');
}
{
	my @g = attempt_is(0, Errno::EROFS());
	like(probe('create')->[1], qr/other than permissions/, 'attempt other errno');
	path('probe.attempt_other');
}
{
	my @g = attempt_is('die');
	like(probe('search')->[1], qr/: attempt died$/, 'attempt throws');
	path('probe.attempt_throws');
}

# ---- _cleanup -------------------------------------------------------------

{
	my @g = attempt_is(0, Errno::EACCES());
	my $orig = \&Test::Permissions::_cleanup;
	push @g, Test::Mockingbird::mock_scoped('Test::Permissions', '_cleanup', sub { $orig->(@_); 'x' });
	like(probe('read')->[1], qr/^chmod revoked read access in .*; also could not clean up .*: x$/, 'cleanup fails, answer was 1');
	path('cleanup.fail_answer1');
}
{
	my @g = attempt_is(1, 0);
	my $orig = \&Test::Permissions::_cleanup;
	push @g, Test::Mockingbird::mock_scoped('Test::Permissions', '_cleanup', sub { $orig->(@_); 'x' });
	like(probe('read')->[1], qr/^chmod cannot revoke read access .*; also could not clean up .*: x$/, 'cleanup fails, answer was 0');
	path('cleanup.fail_answer0');
}
{
	my $target = File::Spec->catfile($dir, 'target');
	like(Test::Permissions::_cleanup(undef, $target, 0600), qr/\Q$target\E/, 'restore throws');
	my $g = Test::Mockingbird::mock_scoped('Test::Permissions', '_set_mode', sub { 0 });
	like(Test::Permissions::_cleanup(undef, $target, 0600), qr/^\Q$target\E: /, 'restore returns false');
	path('cleanup.restore_false');
}
{
	my $g = Test::Mockingbird::mock_scoped('File::Path', 'remove_tree', sub { die "rt\n" });
	is(Test::Permissions::_cleanup('/p', undef, 0700), 'rt', 'remove_tree throws');
	path('cleanup.remove_tree_throws');
}
{
	my $g = Test::Mockingbird::mock_scoped('File::Path', 'remove_tree', sub { ${ $_[1]{error} } = [ { '/p/f' => 'busy' } ] });
	is(Test::Permissions::_cleanup('/p', undef, 0700), '/p/f: busy', 'remove_tree reports errors');
	path('cleanup.remove_tree_errors');
}
is(Test::Permissions::_cleanup(undef, undef, 0700), undef, 'no probe directory: nothing to do');
path('cleanup.no_probe_dir');

# ---- skip_unless_can_revoke --------------------------------------------------

Test::Permissions::clear_cache();
{
	my @g = attempt_is(0, Errno::EACCES());
	SKIP: {
		Test::Permissions::skip_unless_can_revoke('read', 1, $dir);
		pass('answer 1: block runs');
		path('skip.answer1');
	}
}
Test::Permissions::clear_cache();
{
	my @g = attempt_is(1, 0);
	path('skip.answer0');
	SKIP: {
		Test::Permissions::skip_unless_can_revoke('read', 1, $dir);
		fail('answer 0: not reached');
	}
}
Test::Permissions::clear_cache();

# ---- _msg and _printable -------------------------------------------------------

is(Test::Permissions::_msg('error_unknown_message', 'k'), q{Unknown message key 'k'}, 'default text');
path('msg.default');
Test::Permissions::set_messages(error_unknown_message => 'K=%s');
is(Test::Permissions::_msg('error_unknown_message', 'k'), 'K=k', 'override');
path('msg.override');
Test::Permissions::set_messages(error_unknown_message => '%99999999999999999999d');
is(Test::Permissions::_msg('error_unknown_message', 'k'), 'error_unknown_message: k', 'sprintf dies: key and arguments');
path('msg.sprintf_dies');
Test::Permissions::set_messages(error_unknown_message => q{Unknown message key '%s'});

is(Test::Permissions::_printable("\x{263A}\e"), "\x{263A}\\x{1B}", 'character string');
path('printable.chars');
is(Test::Permissions::_printable("\xE2\x98\xBA\e"), "\xE2\x98\xBA\\x{1B}", 'UTF-8 bytes');
path('printable.utf8_bytes');
is(Test::Permissions::_printable("\xFF\e"), "\xFF\\x{1B}", 'other bytes');
path('printable.other_bytes');

# ---- set_messages ----------------------------------------------------------

lives_ok { Test::Permissions::set_messages() } 'no arguments';
path('messages.empty');
throws_ok { Test::Permissions::set_messages(x => 'y') } qr/Unknown message key/, 'unknown key';
path('messages.unknown_key');
throws_ok { Test::Permissions::set_messages(reason_other_error => '') } qr/too short/, 'invalid value';
path('messages.invalid_value');
throws_ok { Test::Permissions::set_messages(1, 2, 3) } qr/Usage/, 'odd list';
path('messages.get_params_croak');
lives_ok { Test::Permissions::set_messages(reason_other_error => q{%s access in '%s' failed for a reason other than permissions: %s}) } 'valid';
path('messages.ok');

# ---- new argument paths -----------------------------------------------------

{
	my ($p, $e) = Test::Permissions::_check_args('acl', [ 'read', "$dir/none" ]);
	like($e, qr/does not exist/, 'path missing');
	path('args.path_missing');
	($p, $e) = Test::Permissions::_check_args('acl', [ 'read', $dir ]);
	is($e, undef, 'path exists');
	path('args.path_ok');
}

# ---- sticky ---------------------------------------------------------------

{
	my $g = Test::Mockingbird::mock_scoped('Test::Permissions', '_can_switch_uid', sub { 0 });
	like(probe('sticky')->[1], qr/needs root/, 'precondition fails: no probe');
	path('probe.precondition_fails');
}
{
	my @g = (
		Test::Mockingbird::mock_scoped('Test::Permissions', '_can_switch_uid', sub { 1 }),
		Test::Mockingbird::mock_scoped('Test::Permissions', '_give_away', sub { 1 }),
		Test::Mockingbird::mock_scoped('Test::Permissions', '_try_unlink', sub { unlink $_[0]; (1, 0) }),
	);
	# 01777 has the sticky bit, which is not an owner bit: comparing only
	# owner bits would pass 0777 too.
	my $g2 = Test::Mockingbird::mock_scoped('Test::Permissions', '_mode_of', sub { 0777 });
	like(probe('sticky')->[1], qr/did not set mode 1777 .* \(got 0777\)/, 'sticky compares all mode bits');
	path('probe.sticky_bits');
}

# ---- _try_exec --------------------------------------------------------------

# Where scripts cannot run, these paths cannot be taken: they are recorded
# as accounted for (skipped, with the reason), not as missing.
my @EXEC_PATHS = qw(exec.runs exec.cannot_run exec.bad_exit);
SKIP: {
	if($^O eq 'MSWin32' || !-x '/bin/sh') {
		path($_) for @EXEC_PATHS;
		skip 'needs /bin/sh', 3;
	}
	my $ok = "$dir/run-ok";
	my $bad = "$dir/run-bad";
	Test::Permissions::_make_file($ok, "#!/bin/sh\nexit 0\n");
	Test::Permissions::_make_file($bad, "#!/bin/sh\nexit 1\n");
	chmod 0700, $ok, $bad;
	my @r = Test::Permissions::_try_exec($ok);
	if(!$r[0] && $r[1] == Errno::EACCES()) {
		path($_) for @EXEC_PATHS;
		skip "cannot run scripts in $dir (noexec?)", 3;
	}
	is_deeply(\@r, [ 1, 0 ], 'runs');
	path('exec.runs');
	is_deeply([ Test::Permissions::_try_exec("$dir/none") ], [ 0, Errno::ENOENT() ], 'cannot run');
	path('exec.cannot_run');
	is_deeply([ Test::Permissions::_try_exec($bad) ], [ 0, Errno::ENOEXEC() ], 'bad exit');
	path('exec.bad_exit');
	unlink $ok, $bad;
}

# ---- _try_unlink ------------------------------------------------------------

{
	my $f = "$dir/unl";
	Test::Permissions::_make_file($f, '');
	is_deeply([ Test::Permissions::_try_unlink($f) ], [ 1, 0 ], 'plain unlink');
	path('unlink.plain');
	throws_ok { Test::Permissions::_try_unlink("$dir/no/f", 1) } qr/^chdir/, 'chdir fails';
	path('unlink.chdir_fails');
	SKIP: {
		skip 'root can switch', 1 if $> == 0 && $< == 0;
		Test::Permissions::_make_file($f, '');
		throws_ok { Test::Permissions::_try_unlink($f, 65533) } qr/cannot act as uid/, 'cannot switch uid';
		unlink $f;
	}
	path('unlink.cannot_switch');
}

# ---- skip through Test2::API ------------------------------------------------

Test::Permissions::clear_cache();
{
	my @g = attempt_is(1, 0);
	# Pretend this is a Test2::V0 suite: Test2::API loaded, Test::Builder not.
	local $INC{'Test/Builder.pm'};
	delete $INC{'Test/Builder.pm'};
	SKIP: {
		Test::Permissions::skip_unless_can_revoke('read', 1, $dir);
		fail('Test2 path: not reached');
	}
	path('skip.test2');
}
Test::Permissions::clear_cache();

# ---- acl_denies -------------------------------------------------------------

{
	my $m = \&Test::Permissions::_mode_allows;
	if($> == 0 && $^O ne 'MSWin32') {
		is($m->('read', [ (0) x 2, 0, 0, 1, 1 ], 0), 1, 'root');
	} else {
		pass('root branch runs only as root (CI root job)');
	}
	path('acl.root');
	SKIP: {
		skip 'non-root branches', 3 if $> == 0 && $^O ne 'MSWin32';
		my $gid = (split ' ', $))[0];
		is($m->('read', [ 0, 0, 0400, 0, $>, -1 ], 0), 1, 'owner');
		is($m->('read', [ 0, 0, 0040, 0, -1, $gid ], 0), 1, 'group');
		is($m->('read', [ 0, 0, 0004, 0, -1, -1 ], 0), 1, 'other');
	}
	path($_) for qw(acl.owner acl.group acl.other);

	my $f = "$dir/aclf";
	Test::Permissions::_make_file($f, '');
	{
		my $g = Test::Mockingbird::mock_scoped('Test::Permissions', '_mode_allows', sub { 0 });
		is(Test::Permissions::acl_denies(read => $f), 0, 'mode denies');
		path('acl.mode_denies');
	}
	{
		my $g = Test::Mockingbird::mock_scoped('Test::Permissions', '_access', sub { 0 });
		my $g2 = Test::Mockingbird::mock_scoped('Test::Permissions', '_mode_allows', sub { 1 });
		is(Test::Permissions::acl_denies(read => $f), 1, 'access denies');
		path('acl.access_denies');
	}
	is(Test::Permissions::acl_denies(read => $f), 0, 'allowed');
	path('acl.allowed');
	unlink $f;
}

# ---- with_revoked -----------------------------------------------------------

{
	my $f = "$dir/wrf";
	Test::Permissions::_make_file($f, '');
	throws_ok { Test::Permissions::with_revoked(read => $dir, sub { 1 }) } qr/is a directory/, 'file kind on a directory';
	path('guard.file_on_dir');
	throws_ok { Test::Permissions::with_revoked(search => $f, sub { 1 }) } qr/is not a directory/, 'directory kind on a file';
	path('guard.dir_on_file');
	{
		my $g = Test::Mockingbird::mock_scoped('Test::Permissions', '_set_mode', sub { 0 });
		throws_ok { Test::Permissions::with_revoked(read => $f, sub { 1 }) } qr/Could not chmod/, 'chmod fails (returns false)';
		path('guard.chmod_fails');
	}
	{
		my $orig = \&Test::Permissions::_set_mode;
		my $n = 0;
		my $g = Test::Mockingbird::mock_scoped('Test::Permissions', '_set_mode', sub { $n++ ? die "no\n" : $orig->(@_) });
		throws_ok { Test::Permissions::with_revoked(read => $f, sub { 1 }) } qr/Could not restore/, 'restore fails';
		path('guard.restore_fails');
		chmod 0600, $f;
	}
	throws_ok { Test::Permissions::with_revoked(read => $f, sub { die "inner\n" }) } qr/^inner$/, 'code dies';
	path('guard.code_dies');
	my @l = Test::Permissions::with_revoked(read => $f, sub { wantarray ? (1, 2) : 'scalar' });
	is_deeply(\@l, [ 1, 2 ], 'list context');
	path('guard.list');
	my $sc = Test::Permissions::with_revoked(read => $f, sub { wantarray ? (1, 2) : 'scalar' });
	is($sc, 'scalar', 'scalar context');
	path('guard.scalar');
	my $ctx;
	Test::Permissions::with_revoked(read => $f, sub { $ctx = defined wantarray ? 'not void' : 'void' });
	is($ctx, 'void', 'void context');
	path('guard.void');
	unlink $f;
}

# ---- cache scope --------------------------------------------------------------

like(Test::Permissions::_cache_key('read', $canon), qr/\0dir:/, 'directory scope');
path('scope.directory');
Test::Permissions::set_cache_scope('device');
like(Test::Permissions::_cache_key('read', $canon), qr/\0dev:\d+$/, 'device scope');
path('scope.device');
like(Test::Permissions::_cache_key('read', "$canon/none"), qr/\0dir:/, 'device scope, stat fails');
path('scope.device_stat_fails');
Test::Permissions::set_cache_scope('directory');

# ---- permissions_report -------------------------------------------------------

Test::Permissions::clear_cache();
{
	my @g = attempt_is(0, Errno::EACCES());
	like(Test::Permissions::permissions_report($dir), qr/^  read: yes$/m, 'yes line');
	path('report.yes');
}
Test::Permissions::clear_cache();
{
	my @g = attempt_is(1, 0);
	like(Test::Permissions::permissions_report($dir), qr/^  read: no - chmod cannot revoke/m, 'no line');
	path('report.no');
}
Test::Permissions::clear_cache();

subtest 'ledger' => sub {
	ok($ledger{$_}, "path taken: $_") for sort keys %ledger;
};

done_testing();
