#!/usr/bin/env perl

# White-box tests, one subtest per function, including the private helpers
# and the seams the probes go through.

use strict;
use warnings;

use Cwd ();
use Errno ();
use File::Path ();
use File::Spec ();
use File::Temp ();
use Test::Mockingbird ();
use Test::Most;
use Test::Warnings;

use lib 'lib';
use Test::Permissions ();

my $dir = File::Temp::tempdir(CLEANUP => 1);

sub mode_of { return (stat $_[0])[2] & 07777 }

subtest '_printable' => sub {
	my $p = \&Test::Permissions::_printable;
	is($p->('plain /path'), 'plain /path', 'plain text unchanged');
	is($p->("a\tb\nc\rd\e"), 'a\x{9}b\x{A}c\x{D}d\x{1B}', 'C0 controls escaped');
	is($p->("x\x7F"), 'x\x{7F}', 'DEL escaped');
	is($p->("a\x{202E}b\x{2066}c\x{200F}d\x{061C}"), 'a\x{202E}b\x{2066}c\x{200F}d\x{61C}', 'bidi controls escaped');
	is($p->("\x{9B}"), '\x{9B}', 'C1 control (character string) escaped');
	my $utf8 = "caf\xC3\xA9 \xE2\x82\xAC";	# UTF-8 bytes of "cafe-acute euro"
	is($p->($utf8), $utf8, 'valid UTF-8 byte string kept, including continuation bytes 0x80-0x9F');
	is($p->("\xE2\x80\xAE"), '\x{202E}', 'bidi control inside a UTF-8 byte string escaped');
	is($p->("latin1 \xE9 \x9B"), "latin1 \xE9 \\x{9B}", 'invalid UTF-8: C1 bytes escaped, others kept');
	is($p->(42), '42', 'numbers stringified');
	is($p->(undef), '', 'undef is empty, without a warning');
};

subtest '_exception_text' => sub {
	my $e = \&Test::Permissions::_exception_text;
	is($e->("boom\n\n"), 'boom', 'trailing newlines removed');
	is($e->('boom at lib/X.pm line 12.'), 'boom', 'trailing location removed');
	is($e->("bad\e"), 'bad\x{1B}', 'printable');
	is($e->(undef), '', 'undef');
	my $long = ("\n" x 10_000) . 'x';
	is($e->($long), Test::Permissions::_printable($long), 'inner newlines kept (escaped)');
};

subtest '_errno_text' => sub {
	local $! = Errno::EACCES();
	my $expected = "$!";
	$! = 0;
	is(Test::Permissions::_errno_text(Errno::EACCES()), $expected, 'text of the errno in this locale');
	is(0 + $!, 0, '$! restored');
};

subtest '_msg' => sub {
	my $m = \&Test::Permissions::_msg;
	is($m->('error_not_a_directory', '/x'), q{'/x' is not a directory}, 'default text');
	is($m->('reason_chmod_ignored', 0, '/d', 0444), q{chmod did not set mode 0000 in '/d' (got 0444)}, '%04o');
	Test::Permissions::set_messages(error_not_a_directory => 'NOT %s');
	is($m->('error_not_a_directory', '/x'), 'NOT /x', 'override');
	Test::Permissions::set_messages(error_not_a_directory => q{'%s' is not a directory});
};

subtest '_canonical' => sub {
	my $c = \&Test::Permissions::_canonical;
	my $abs = Cwd::abs_path($dir);
	is($c->($dir), $abs, 'absolute path');
	my $sub = File::Spec->catdir($dir, 'sub');
	mkdir $sub or die $!;
	is($c->(File::Spec->catdir($sub, File::Spec->updir)), $abs, 'updir resolved');
	{
		my $g = Test::Mockingbird::mock_scoped('Cwd', 'abs_path', sub { die "no\n" });
		is($c->($dir), File::Spec->rel2abs($dir), 'falls back to rel2abs when abs_path dies');
	}
	{
		my $g = Test::Mockingbird::mock_scoped('Cwd', 'abs_path', sub { undef });
		is($c->($dir), File::Spec->rel2abs($dir), '... or returns undef');
	}
	rmdir $sub;
};

subtest '_hash_rule' => sub {
	my $rule = { type => 'string', memberof => [ 'a' ], position => 0 };
	my $copy = Test::Permissions::_hash_rule($rule);
	is_deeply($copy, { type => 'string', memberof => [ 'a' ] }, 'position removed');
	isnt($copy->{memberof}, $rule->{memberof}, 'memberof copied');
	ok(exists $rule->{position}, 'original untouched');
};

subtest '_normalise_args' => sub {
	my $n = sub { Test::Permissions::_normalise_args([ qw(kind dir) ], [ @_ ]) };
	is_deeply($n->(), {}, 'no arguments');
	is_deeply($n->('read'), { kind => 'read' }, 'one positional');
	is_deeply($n->('read', '/d'), { kind => 'read', dir => '/d' }, 'two positional');
	is_deeply($n->(kind => 'read', dir => '/d'), { kind => 'read', dir => '/d' }, 'named');
	is_deeply($n->(dir => '/d'), { dir => '/d' }, 'named, one pair');
	is_deeply($n->({ kind => 'read' }), { kind => 'read' }, 'hashref');
	is_deeply($n->('read', undef), { kind => 'read' }, 'undef removed');
	like($n->('a', 'b', 'c'), qr/^Too many arguments: expected at most 2, got 3/, 'too many: an error string');
	my $h = { kind => 'read', dir => undef };
	$n->($h);
	ok(exists $h->{dir}, "caller's hash not modified");
};

subtest '_check_args' => sub {
	my $c = \&Test::Permissions::_check_args;
	my ($p, $e) = $c->('dir', []);
	is($e, undef, 'no error');
	is($p->{dir}, File::Spec->tmpdir, 'dir defaults to tmpdir');
	($p, $e) = $c->('kind_dir', [ 'nope' ]);
	like($e, qr/^Unknown access kind/, 'unknown kind');
	($p, $e) = $c->('kind_count_dir', [ 'read', 1, $dir ]);
	is_deeply($p, { kind => 'read', count => 1, dir => $dir }, 'all three');
	$@ = 'kept';
	$! = Errno::EIO();
	$c->('dir', [ '/no/such/dir' ]);
	is($@, 'kept', '$@ restored');
	is(0 + $!, Errno::EIO(), '$! restored');
};

subtest '_check_messages' => sub {
	my ($t, $e) = Test::Permissions::_check_messages([]);
	is_deeply($t, {}, 'nothing to do');
	($t, $e) = Test::Permissions::_check_messages([ reason_other_error => 'x' ]);
	is_deeply($t, { reason_other_error => 'x' }, 'valid pair');
	($t, $e) = Test::Permissions::_check_messages([ nope => 'x' ]);
	like($e, qr/^Unknown message key 'nope'/, 'unknown key');
};

subtest '_set_return' => sub {
	is(Test::Permissions::_set_return(1, 'answer'), 1, 'boolean');
	is(Test::Permissions::_set_return(undef, 'reason'), undef, 'optional string');
	dies_ok { Test::Permissions::_set_return('maybe', 'answer') } 'a non-boolean answer is a bug and dies';
};

subtest 'seams' => sub {
	my $file = File::Spec->catfile($dir, 'seam');
	is_deeply([ Test::Permissions::_try_open($file, '<') ], [ 0, Errno::ENOENT() ], '_try_open: missing file');
	is_deeply([ Test::Permissions::_try_open($file, '>') ], [ 1, 0 ], '_try_open: create');
	is_deeply([ Test::Permissions::_try_stat($file) ], [ 1, 0 ], '_try_stat: exists');
	is_deeply([ Test::Permissions::_try_stat("$file.no") ], [ 0, Errno::ENOENT() ], '_try_stat: missing');
	is(Test::Permissions::_set_mode($file, 0640), 1, '_set_mode returns 1');
	is(Test::Permissions::_mode_of($file), mode_of($file), '_mode_of matches stat');
	is(Test::Permissions::_mode_of("$file.no"), undef, '_mode_of: undef for a missing path');
	dies_ok { Test::Permissions::_set_mode("$file.no", 0600) } '_set_mode throws on failure (autodie)';
	unlink $file;

	my $p = Test::Permissions::_make_probe_dir($dir);
	ok(-d $p, '_make_probe_dir creates a directory');
	is(File::Spec->catdir((File::Spec->splitpath($p))[1]), File::Spec->catdir($dir), '... inside dir')
		if $^O ne 'MSWin32';
	like($p, qr/test-permissions-\w{8}\z/, '... named from the template');
	is(mode_of($p), 0700, '... mode 0700') unless $^O eq 'MSWin32';
	dies_ok { Test::Permissions::_make_probe_dir("$dir/no/such") } '_make_probe_dir throws on failure';
	rmdir $p;
};

subtest 'setup helpers' => sub {
	my $p = Test::Permissions::_make_probe_dir($dir);
	my $paths = Test::Permissions::_setup_file($p, 'x', 0600);
	is($paths->{target}, $paths->{object}, '_setup_file: target is the object');
	is(-s $paths->{object}, 1, '... one byte');
	is(mode_of($paths->{object}), 0600, '... mode 0600') unless $^O eq 'MSWin32';
	unlink $paths->{object};

	$paths = Test::Permissions::_setup_subdir($p, 1);
	ok(-d $paths->{target}, '_setup_subdir: directory');
	ok(-f $paths->{object}, '... holding a file');
	is(mode_of($paths->{target}), 0700, '... mode 0700') unless $^O eq 'MSWin32';
	File::Path::remove_tree($paths->{target});

	$paths = Test::Permissions::_setup_subdir($p, 0);
	ok(!-e $paths->{object}, '_setup_subdir without file: object does not exist yet');
	like($paths->{object}, qr/new\z/, '... and is called new');
	File::Path::remove_tree($p);

	{
		my $old = umask 0777;
		my $q = Test::Permissions::_make_probe_dir($dir);
		my $f = Test::Permissions::_setup_file($q, 'x', 0600);
		umask $old;
		is(mode_of($f->{object}), 0600, 'explicit modes: umask 0777 does not matter') unless $^O eq 'MSWin32';
		File::Path::remove_tree($q);
	}
};

subtest '_make_file' => sub {
	my $f = File::Spec->catfile($dir, 'made');
	Test::Permissions::_make_file($f, 'abc');
	is(-s $f, 3, 'content written');
	Test::Permissions::_make_file($f, '');
	is(-s $f, 0, 'empty content truncates');
	unlink $f;
	dies_ok { Test::Permissions::_make_file("$dir/no/such/file", 'x') } 'throws on failure';
};

subtest '_cleanup' => sub {
	is(Test::Permissions::_cleanup(undef, undef, 0700), undef, 'nothing to do');
	my $p = Test::Permissions::_make_probe_dir($dir);
	my $paths = Test::Permissions::_setup_subdir($p, 1);
	chmod 0, $paths->{target};
	is(Test::Permissions::_cleanup($p, $paths->{target}, 0700), undef, 'restores and removes');
	ok(!-e $p, 'probe directory gone');
	like(Test::Permissions::_cleanup(undef, "$dir/gone", 0700), qr/gone/, 'failed restore reported');
	{
		my $g = Test::Mockingbird::mock_scoped('File::Path', 'remove_tree', sub { ${ $_[1]{error} } = [ { '/x' => 'busy' }, { '' => 'general' } ]; 0 });
		is(Test::Permissions::_cleanup('/whatever', undef, 0700), '/x: busy; general', 'remove_tree errors reported');
	}
	{
		my $g = Test::Mockingbird::mock_scoped('File::Path', 'remove_tree', sub { die "exploded\n" });
		is(Test::Permissions::_cleanup('/whatever', undef, 0700), 'exploded', 'remove_tree exception reported');
	}
};

subtest '_probe' => sub {
	for my $kind (qw(read write create search exec delete sticky)) {
		my @r = Test::Permissions::_probe($kind, Cwd::abs_path($dir));
		is(scalar @r, 2, "$kind: (answer, reason)");
		ok($r[0] ? !defined $r[1] : length $r[1], "$kind: reason iff answer is 0");
	}
	local $SIG{__DIE__} = sub { fail("caller's die hook saw: @_") };
	my $g = Test::Mockingbird::mock_scoped('Test::Permissions', '_make_probe_dir', sub { die "hidden\n" });
	is((Test::Permissions::_probe('read', $dir))[0], 0, "internal exceptions do not reach the caller's __DIE__ hook");
};

subtest '_answer' => sub {
	Test::Permissions::clear_cache();
	my $a1 = Test::Permissions::_answer('read', $dir);
	my $a2 = Test::Permissions::_answer('read', "$dir/.");
	is($a1, $a2, 'same entry for another spelling of the directory');
	Test::Permissions::clear_cache();
};

subtest '_setup_file with a script' => sub {
	my $p = Test::Permissions::_make_probe_dir($dir);
	my $paths = Test::Permissions::_setup_file($p, "#!/bin/sh\nexit 0\n", 0700);
	is(mode_of($paths->{object}), 0700, 'mode as given') unless $^O eq 'MSWin32';
	is(-s $paths->{object}, 17, 'content as given');
	File::Path::remove_tree($p);
};

subtest '_setup_sticky' => sub {
	my $p = Test::Permissions::_make_probe_dir($dir);
	my @given;
	my $g = Test::Mockingbird::mock_scoped('Test::Permissions', '_give_away', sub { push @given, [ @_ ]; 1 });
	my $paths = Test::Permissions::_setup_sticky($p);
	is(mode_of($paths->{target}), 0777, 'directory 0777') unless $^O eq 'MSWin32';
	ok(-f $paths->{object}, 'file inside');
	is_deeply(\@given, [ [ $paths->{object}, 65534 ] ], 'file given to the owner uid');
	is($paths->{as}, 65533, 'deleted as the other uid');
	File::Path::remove_tree($p);
};

subtest '_try_exec' => sub {
	SKIP: {
		skip 'needs /bin/sh', 3 if $^O eq 'MSWin32' || !-x '/bin/sh';
		my $p = Test::Permissions::_make_probe_dir($dir);
		my $ok = File::Spec->catfile($p, 'ok');
		my $bad = File::Spec->catfile($p, 'bad');
		Test::Permissions::_make_file($ok, "#!/bin/sh\nexit 0\n");
		Test::Permissions::_make_file($bad, "#!/bin/sh\nexit 3\n");
		chmod 0700, $ok, $bad;
		my ($r, $e) = Test::Permissions::_try_exec($ok);
		if(!$r && $e == Errno::EACCES()) {
			skip "cannot run scripts in $dir (noexec?)", 3;
		}
		is_deeply([ $r, $e ], [ 1, 0 ], 'runs and exits 0');
		is_deeply([ Test::Permissions::_try_exec($bad) ], [ 0, Errno::ENOEXEC() ], 'non-zero exit: ENOEXEC');
		is_deeply([ Test::Permissions::_try_exec("$ok.missing") ], [ 0, Errno::ENOENT() ], 'missing: ENOENT');
		File::Path::remove_tree($p);
	}
	local $ENV{PATH} = 'kept';
	Test::Permissions::_try_exec('/no/such/thing');
	is($ENV{PATH}, 'kept', "caller's PATH restored");
};

subtest '_try_unlink' => sub {
	my $f = File::Spec->catfile($dir, 'unlink-me');
	Test::Permissions::_make_file($f, '');
	is_deeply([ Test::Permissions::_try_unlink($f) ], [ 1, 0 ], 'unlinked');
	is_deeply([ Test::Permissions::_try_unlink($f) ], [ 0, Errno::ENOENT() ], 'already gone: ENOENT');
	SKIP: {
		skip 'only meaningful when not root', 2 if $> == 0;
		Test::Permissions::_make_file($f, '');
		my $cwd = Cwd::getcwd();
		throws_ok { Test::Permissions::_try_unlink($f, 65533) } qr/^cannot act as uid 65533$/, 'cannot switch uid: throws';
		is(Cwd::getcwd(), $cwd, 'working directory restored');
		unlink $f;
	}
	throws_ok { Test::Permissions::_try_unlink("$dir/no/such/f", 1) } qr/^chdir /, 'missing directory: throws';
	{
		# Cannot change back to the working directory: throws, after the
		# uid has been restored.  (Restore the cwd by hand afterwards.)
		my ($cwd, $euid) = (Cwd::getcwd(), $>);
		Test::Permissions::_make_file($f, '');
		my $g = Test::Mockingbird::mock_scoped('Cwd', 'getcwd', sub { "$dir/gone" });
		throws_ok { Test::Permissions::_try_unlink($f, $>) } qr/^chdir \Q$dir\E\/gone: /, 'cannot change back: throws';
		is($>, $euid, 'effective uid restored');
		chdir $cwd or die "$cwd: $!";
		unlink $f;
	}
};

subtest '_can_switch_uid and _give_away' => sub {
	my $expected = ($^O ne 'MSWin32' && $< == 0 && $> == 0) ? 1 : 0;
	is(Test::Permissions::_can_switch_uid(), $expected, '_can_switch_uid: real and effective root, not Windows');
	my $f = File::Spec->catfile($dir, 'give');
	Test::Permissions::_make_file($f, '');
	SKIP: {
		skip 'chown to another user is allowed for root', 1 if $> == 0;
		dies_ok { Test::Permissions::_give_away($f, 65534) } '_give_away throws when chown is refused';
	}
	unlink $f;
};

subtest '_mode_allows' => sub {
	my $m = \&Test::Permissions::_mode_allows;
	my ($uid, $gid) = ($>, (split ' ', $))[0]);
	SKIP: {
		skip 'root and Windows take other branches', 6 if $> == 0;
		is($m->('read', [ 0, 0, 0400, 0, $uid, -1 ], 0), 1, 'owner read bit');
		is($m->('write', [ 0, 0, 0400, 0, $uid, -1 ], 0), 0, 'owner without write bit');
		is($m->('exec', [ 0, 0, 0010, 0, -1, $gid ], 0), 1, 'group exec bit');
		is($m->('read', [ 0, 0, 0004, 0, -1, $gid ], 0), 0, 'group bits used, not other');
		is($m->('write', [ 0, 0, 0002, 0, -1, -1 ], 0), 1, 'other write bit');
		is($m->('read', [ 0, 0, 0040, 0, -1, -1 ], 0), 0, 'other bits used, not group');
	}
	SKIP: {
		skip 'root branch', 4 unless $> == 0 && $^O ne 'MSWin32';
		is($m->('read', [ 0, 0, 0, 0, 1, 1 ], 0), 1, 'root reads mode 0');
		is($m->('exec', [ 0, 0, 0600, 0, 1, 1 ], 0), 0, 'root cannot run a file with no x bit');
		is($m->('exec', [ 0, 0, 0001, 0, 1, 1 ], 0), 1, '... but can with any x bit');
		is($m->('exec', [ 0, 0, 0, 0, 1, 1 ], 1), 1, 'root searches any directory');
	}
};

subtest '_access' => sub {
	my $f = File::Spec->catfile($dir, 'access');
	Test::Permissions::_make_file($f, '');
	chmod 0600, $f;
	is(Test::Permissions::_access('read', $f), 1, 'read');
	is(Test::Permissions::_access('write', $f), 1, 'write');
	is(Test::Permissions::_access('exec', $f), 0, 'exec') unless $> == 0 || $^O eq 'MSWin32';
	unlink $f;
};

subtest '_untaint and _chmod_error' => sub {
	is(Test::Permissions::_untaint("a\nb"), "a\nb", '_untaint keeps the whole string');
	my $f = File::Spec->catfile($dir, 'chm');
	Test::Permissions::_make_file($f, '');
	is(Test::Permissions::_chmod_error($f, 0600), undef, '_chmod_error: success');
	like(Test::Permissions::_chmod_error("$f.none", 0600), qr/chmod/, '_chmod_error: failure text');
	unlink $f;
};

subtest '_cache_key' => sub {
	my $k = \&Test::Permissions::_cache_key;
	my $key = $k->('read', $dir);
	my ($euid, $egids) = ($>, $));
	is($key, join("\0", 'read', $euid, $egids, "dir:$dir"), 'kind, euid, egids, directory');
	Test::Permissions::set_cache_scope('device');
	like($k->('read', $dir), qr/\0dev:\d+$/, 'device scope');
	like($k->('read', "$dir/missing"), qr/\0dir:/, 'device scope falls back to the directory when stat fails');
	Test::Permissions::set_cache_scope('directory');
};

# Mutant killers: the root branches, reached by mocking _uids and
# _unlink_as, so that they run without root.

subtest '_can_switch_uid, with _uids mocked' => sub {
	for my $case ([ 0, 0, 1 ], [ 0, 1000, 0 ], [ 1000, 0, 0 ], [ 1000, 1000, 0 ]) {
		my ($ruid, $euid, $expected) = @{$case};
		my $g = Test::Mockingbird::mock_scoped('Test::Permissions', '_uids', sub { ($ruid, $euid) });
		is(Test::Permissions::_can_switch_uid(), $^O eq 'MSWin32' ? 0 : $expected, "real $ruid, effective $euid");
	}
	is_deeply([ Test::Permissions::_uids() ], [ $<, $> ], '_uids is ($<, $>)');
};

subtest '_mode_allows as root, with _uids mocked' => sub {
	plan skip_all => 'Windows always uses the owner bits' if $^O eq 'MSWin32';
	my $g = Test::Mockingbird::mock_scoped('Test::Permissions', '_uids', sub { (0, 0) });
	my $m = \&Test::Permissions::_mode_allows;
	is($m->('read', [ 0, 0, 0, 0, 1, 1 ], 0), 1, 'root reads a mode-0 file');
	is($m->('write', [ 0, 0, 0, 0, 1, 1 ], 0), 1, 'root writes a mode-0 file');
	is($m->('exec', [ 0, 0, 0600, 0, 1, 1 ], 0), 0, 'root cannot run a file with no x bit');
	is($m->('exec', [ 0, 0, 0010, 0, 1, 1 ], 0), 1, '... but can with any x bit');
	is($m->('exec', [ 0, 0, 0, 0, 1, 1 ], 1), 1, 'root searches a mode-0 directory');
};

subtest '_try_unlink as another user, with _unlink_as mocked' => sub {
	my $f = File::Spec->catfile($dir, 'as-other');
	Test::Permissions::_make_file($f, '');
	my $cwd = Cwd::getcwd();
	my @seen;
	for my $case ([ [ 1, 1, 0 ], [ 1, 0 ] ], [ [ 1, 0, Errno::EPERM() ], [ 0, Errno::EPERM() ] ]) {
		my ($returns, $expected) = @{$case};
		my $g = Test::Mockingbird::mock_scoped('Test::Permissions', '_unlink_as', sub { push @seen, [ Cwd::getcwd(), @_ ]; @{$returns} });
		is_deeply([ Test::Permissions::_try_unlink($f, 65533) ], $expected, "_unlink_as gives (@{$returns})");
	}
	is($seen[0][1], 'as-other', 'unlinks the bare name');
	is($seen[0][2], 65533, 'as the given uid');
	is(Cwd::abs_path($seen[0][0]), Cwd::abs_path($dir), "from inside the file's directory");
	is(Cwd::getcwd(), $cwd, 'and changes back');
	{
		my $g = Test::Mockingbird::mock_scoped('Test::Permissions', '_unlink_as', sub { (0) });
		throws_ok { Test::Permissions::_try_unlink($f, 65533) } qr/^cannot act as uid 65533$/, 'not switched: throws';
		is(Cwd::getcwd(), $cwd, '... after changing back');
	}
	unlink $f;
};

subtest '_unlink_as without root' => sub {
	plan skip_all => 'root can switch' if $> == 0 && $< == 0;
	my $euid = $>;
	is_deeply([ Test::Permissions::_unlink_as('nothing', 65533) ], [ 0 ], 'cannot switch: (0)');
	is($>, $euid, 'effective uid unchanged');
};

subtest '_give_away returns nothing' => sub {
	my $f = File::Spec->catfile($dir, 'mine');
	Test::Permissions::_make_file($f, '');
	my @r = Test::Permissions::_give_away($f, $>);
	is(scalar @r, 0, 'giving a file to its own owner works and returns nothing');
	unlink $f;
};

subtest '_probe: _mode_of failing reports the errno text' => sub {
	my $g = Test::Mockingbird::mock_scoped('Test::Permissions', '_mode_of', sub { $! = Errno::ENOENT(); undef });
	my $text = do { local $! = Errno::ENOENT(); "$!" };
	my (undef, $why) = Test::Permissions::_probe('write', Cwd::abs_path($dir));
	like($why, qr/^Could not set up the write probe in '.*': \Q$text\E$/, 'reason_setup_failed with the stat error');
};

done_testing();
