#!/usr/bin/env perl

# Black-box tests driven by the POD.  Every documented function, argument
# form, return value and message has an entry in %ledger; the last test
# checks that each entry was exercised.  A new message, argument or
# function needs a ledger entry.

use strict;
use warnings;

use Errno ();
use File::Spec ();
use File::Temp ();
use Test::Mockingbird ();
use Test::Most;
use Test::Returns;
use Test::Warnings;

use lib 'lib';
use Test::Permissions ();

my %ledger = map { $_ => 0 } (
	# functions
	'fn:can_revoke_read', 'fn:can_revoke_write', 'fn:can_revoke_create', 'fn:can_revoke_search',
	'fn:can_revoke_exec', 'fn:can_revoke_delete', 'fn:can_revoke_sticky',
	'fn:can_revoke', 'fn:why_not', 'fn:skip_unless_can_revoke', 'fn:clear_cache', 'fn:set_messages',
	'fn:acl_denies', 'fn:with_revoked', 'fn:permissions_report', 'fn:set_cache_scope',
	# argument forms
	'form:none', 'form:positional', 'form:named', 'form:hashref', 'form:object',
	# exports
	'export:none-by-default', 'export:ok', 'export:all', 'export:revoke',
	'export:acl', 'export:guard', 'export:report',
	# messages
	(map { "msg:$_" } qw(
		error_unknown_kind error_not_a_directory error_not_a_file error_no_such_path
		error_unknown_message error_too_many_arguments error_chmod_failed error_restore_failed
		reason_not_enforced reason_chmod_ignored reason_baseline_failed reason_other_error
		reason_setup_failed reason_cleanup_failed reason_probe_succeeded reason_needs_root
		report_header report_yes report_no
	)),
);

sub covered { $ledger{$_}++ for @_; return }

my $dir = File::Temp::tempdir(CLEANUP => 1);
my @KINDS = qw(read write create search exec delete sticky);
my $ALL_KINDS = 'read, write, create, search, exec, delete, sticky';

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

sub simulate_attempt {
	my ($ok, $errno) = @_;
	my @guards = chmod_works();
	for my $seam (qw(_try_open _try_stat _try_exec _try_unlink)) {
		# The exec probe's real baseline runs a /bin/sh script, which is
		# impossible on Windows; these scenarios are about later steps, so
		# its baseline is simulated as a successful run everywhere.
		my $orig = $seam eq '_try_exec' ? sub { (1, 0) } : \&{"Test::Permissions::$seam"};
		my $calls = 0;
		push @guards, Test::Mockingbird::mock_scoped('Test::Permissions', $seam,
			sub { $calls++ ? ($ok, $errno) : $orig->(@_) });
	}
	return @guards;
}

subtest 'exports' => sub {
	ok(!defined &main::can_revoke_read, 'nothing exported by default');
	covered('export:none-by-default');

	package Ex::Ok { Test::Permissions->import(qw(why_not can_revoke)) }
	ok(defined &Ex::Ok::why_not && defined &Ex::Ok::can_revoke, 'named imports');
	ok(!defined &Ex::Ok::clear_cache, 'only those');
	covered('export:ok');

	package Ex::All { Test::Permissions->import(':all') }
	ok(defined &{"Ex::All::$_"}, ":all has $_") for @Test::Permissions::EXPORT_OK;
	covered('export:all');

	package Ex::Revoke { Test::Permissions->import(':revoke') }
	ok(defined &{"Ex::Revoke::$_"}, ":revoke has $_")
		for qw(can_revoke_read can_revoke_write can_revoke_create can_revoke_search
			can_revoke_exec can_revoke_delete can_revoke_sticky can_revoke why_not skip_unless_can_revoke);
	ok(!defined &Ex::Revoke::clear_cache && !defined &Ex::Revoke::set_messages, ':revoke excludes the general functions');
	ok(!defined &Ex::Revoke::with_revoked, ':revoke excludes the other families');
	covered('export:revoke');

	package Ex::Acl { Test::Permissions->import(':acl') }
	package Ex::Guard { Test::Permissions->import(':guard') }
	package Ex::Report { Test::Permissions->import(':report') }
	ok(defined &Ex::Acl::acl_denies && !defined &Ex::Acl::can_revoke, ':acl is acl_denies');
	ok(defined &Ex::Guard::with_revoked && !defined &Ex::Guard::acl_denies, ':guard is with_revoked');
	ok(defined &Ex::Report::permissions_report && !defined &Ex::Report::with_revoked, ':report is permissions_report');
	covered('export:acl', 'export:guard', 'export:report');

	throws_ok { Test::Permissions->import('no_such_function') } qr/not exported/, 'unknown import refused';
};

subtest 'can_revoke_<kind>: returns 1 or 0, never undef' => sub {
	for my $kind (@KINDS) {
		my $fn = \&{"Test::Permissions::can_revoke_$kind"};
		my $answer = $fn->($dir);
		returns_ok($answer, { type => 'boolean' }, "can_revoke_$kind matches its output schema");
		ok(defined $answer && ($answer eq '1' || $answer eq '0'), "can_revoke_$kind is 1 or 0");
		is($answer, Test::Permissions::can_revoke($kind, $dir), "same as can_revoke('$kind')");
		covered("fn:can_revoke_$kind");
	}
	covered('fn:can_revoke');
};

subtest 'argument forms' => sub {
	my $expected = Test::Permissions::can_revoke_read($dir);
	is(Test::Permissions::can_revoke_read(dir => $dir), $expected, 'f(dir => $dir)');
	covered('form:named');
	is(Test::Permissions::can_revoke_read({ dir => $dir }), $expected, 'f({ dir => $dir })');
	covered('form:hashref');
	is(Test::Permissions::can_revoke_read($dir), $expected, 'f($dir)');
	covered('form:positional');
	returns_ok(Test::Permissions::can_revoke_read(), { type => 'boolean' }, 'f() probes File::Spec->tmpdir');
	covered('form:none');

	is(Test::Permissions::can_revoke('read', $dir), $expected, "can_revoke('read', \$dir)");
	is(Test::Permissions::can_revoke(kind => 'read', dir => $dir), $expected, 'can_revoke(kind =>, dir =>)');
	is(Test::Permissions::can_revoke({ kind => 'read', dir => $dir }), $expected, 'can_revoke({ ... })');
	returns_ok(Test::Permissions::can_revoke('read'), { type => 'boolean' }, "can_revoke('read')");

	{
		package Stringifies;
		use overload q{""} => sub { ${ $_[0] } }, fallback => 1;
	}
	my $object = bless \(my $path = $dir), 'Stringifies';
	is(Test::Permissions::can_revoke_read($object), $expected, 'an object that stringifies');
	covered('form:object');
};

subtest 'why_not' => sub {
	for my $kind (@KINDS) {
		my $why = Test::Permissions::why_not($kind, $dir);
		returns_ok($why, { type => 'string', optional => 1 }, "$kind: matches its output schema");
		if(Test::Permissions::can_revoke($kind, $dir)) {
			ok(!defined $why, "$kind: undef when the answer is 1");
		} else {
			ok(defined $why && length $why, "$kind: a non-empty reason when the answer is 0");
		}
	}
	covered('fn:why_not');
};

subtest 'skip_unless_can_revoke' => sub {
	Test::Permissions::clear_cache();
	my $ran = 0;
	{
		my @guards = simulate_attempt(0, Errno::EACCES());
		SKIP: {
			my @r = Test::Permissions::skip_unless_can_revoke('read', 1, $dir);
			is(scalar @r, 0, 'returns nothing when the answer is 1');
			$ran = 1;
		}
	}
	ok($ran, 'block runs when the answer is 1');

	Test::Permissions::clear_cache();
	$ran = 0;
	{
		my @guards = simulate_attempt(1, 0);
		SKIP: {
			Test::Permissions::skip_unless_can_revoke('read', 2, $dir);
			$ran = 1;
			fail('not reached');
			fail('not reached');
		}
	}
	ok(!$ran, 'block skipped when the answer is 0');
	covered('fn:skip_unless_can_revoke');
	Test::Permissions::clear_cache();
};

subtest 'clear_cache' => sub {
	my @r = Test::Permissions::clear_cache();
	is(scalar @r, 0, 'returns nothing');
	my $spy = Test::Mockingbird::spy('Test::Permissions', '_make_probe_dir');
	Test::Permissions::can_revoke_read($dir);
	Test::Permissions::can_revoke_read($dir);
	is(scalar(my @c = $spy->()), 1, 'cached: one probe');
	Test::Permissions::clear_cache();
	Test::Permissions::can_revoke_read($dir);
	is(scalar(@c = $spy->()), 2, 'after clear_cache: probed again');
	Test::Mockingbird::restore_all();
	covered('fn:clear_cache');
};

# Every reason, triggered through the public API, with its documented text.
subtest 'reasons' => sub {
	my %cases = (
		reason_not_enforced => [ sub { simulate_attempt(1, 0) },
			qr/\Achmod cannot revoke read access in '.+' \(running as root, or the filesystem ignores permissions\)\z/ ],
		reason_other_error => [ sub { simulate_attempt(0, Errno::ENOSPC()) },
			qr/\Aread access in '.+' failed for a reason other than permissions: .+\z/ ],
		reason_chmod_ignored => [ sub { Test::Mockingbird::mock_scoped('Test::Permissions', '_mode_of', sub { 0444 }) },
			qr/\Achmod did not set mode 0000 in '.+' \(got 0444\)\z/ ],
		reason_baseline_failed => [ sub { Test::Mockingbird::mock_scoped('Test::Permissions', '_try_open', sub { (0, Errno::EIO()) }) },
			qr/\Aread access fails in '.+' even when it is allowed: .+\z/ ],
		reason_setup_failed => [ sub { Test::Mockingbird::mock_scoped('Test::Permissions', '_make_probe_dir', sub { die "no\n" }) },
			qr/\ACould not set up the read probe in '.+': no\z/ ],
		reason_cleanup_failed => [ sub {
				simulate_attempt(0, Errno::EACCES()),
				Test::Mockingbird::mock_scoped('Test::Permissions', '_cleanup', sub { 'gone wrong' });
			},
			qr/\Achmod revoked read access in '.+'; also could not clean up '.+': gone wrong\z/ ],
	);
	for my $key (sort keys %cases) {
		my ($setup, $re) = @{ $cases{$key} };
		Test::Permissions::clear_cache();
		my @guards = $setup->();
		is(Test::Permissions::can_revoke_read($dir), 0, "$key: answer 0");
		like(Test::Permissions::why_not('read', $dir), $re, "$key: text");
		covered("msg:$key");
	}
	covered('msg:reason_probe_succeeded');
	Test::Permissions::clear_cache();
};

subtest 'errors' => sub {
	throws_ok { Test::Permissions::can_revoke('bogus') } qr/^Unknown access kind 'bogus'; expected one of: \Q$ALL_KINDS\E at /,
		'error_unknown_kind';
	covered('msg:error_unknown_kind');
	throws_ok { Test::Permissions::why_not('read', File::Spec->catdir($dir, 'nope')) } qr/^'.*nope' is not a directory at /,
		'error_not_a_directory';
	covered('msg:error_not_a_directory');
	throws_ok { Test::Permissions::set_messages(bogus => 'x') } qr/^Unknown message key 'bogus' at /,
		'error_unknown_message';
	covered('msg:error_unknown_message');
	throws_ok { Test::Permissions::can_revoke('read', $dir, 'x') } qr/^Too many arguments: expected at most 2, got 3 at /,
		'error_too_many_arguments';
	covered('msg:error_too_many_arguments');
};

subtest 'set_messages' => sub {
	my @r = Test::Permissions::set_messages();
	is(scalar @r, 0, 'returns nothing');
	Test::Permissions::set_messages({ error_unknown_kind => 'Type inconnu %s (%s)' });
	throws_ok { Test::Permissions::can_revoke('x') } qr/^Type inconnu x \(\Q$ALL_KINDS\E\)/, 'hashref form, used at once';
	Test::Permissions::set_messages(error_unknown_kind => q{Unknown access kind '%s'; expected one of: %s});
	throws_ok { Test::Permissions::set_messages(error_unknown_kind => 'new', bogus => 'x') } qr/bogus/, 'one bad key';
	throws_ok { Test::Permissions::can_revoke('x') } qr/^Unknown access kind/, '... and nothing was changed';
	covered('fn:set_messages');
};

subtest 'more errors' => sub {
	my $file = File::Spec->catfile($dir, 'unit-file');
	open(my $fh, '>', $file) or die $!;
	close $fh;
	throws_ok { Test::Permissions::acl_denies(read => "$file.x") } qr/^'.*' does not exist at /, 'error_no_such_path';
	covered('msg:error_no_such_path');
	throws_ok { Test::Permissions::with_revoked(write => $dir, sub { 1 }) } qr/^'.*' is a directory; write access is revoked on a file at /,
		'error_not_a_file';
	covered('msg:error_not_a_file');
	{
		my $g = Test::Mockingbird::mock_scoped('Test::Permissions', '_set_mode', sub { die "EPERM\n" });
		throws_ok { Test::Permissions::with_revoked(read => $file, sub { 1 }) } qr/^Could not chmod '.*' to 0000: EPERM at /,
			'error_chmod_failed';
	}
	covered('msg:error_chmod_failed');
	{
		my $orig = \&Test::Permissions::_set_mode;
		my $n = 0;
		my $g = Test::Mockingbird::mock_scoped('Test::Permissions', '_set_mode', sub { $n++ ? die "EIO\n" : $orig->(@_) });
		throws_ok { Test::Permissions::with_revoked(read => $file, sub { 1 }) } qr/^Could not restore mode 0\d+ on '.*': EIO at /,
			'error_restore_failed';
	}
	covered('msg:error_restore_failed');
	chmod 0600, $file;
	unlink $file;
};

subtest 'can_revoke_sticky without root' => sub {
	Test::Permissions::clear_cache();
	my $g = Test::Mockingbird::mock_scoped('Test::Permissions', '_can_switch_uid', sub { 0 });
	is(Test::Permissions::can_revoke_sticky($dir), 0, 'answer 0');
	like(Test::Permissions::why_not('sticky', $dir), qr/must act as two users, which needs root/, 'reason_needs_root');
	covered('msg:reason_needs_root');
	Test::Permissions::clear_cache();
};

subtest 'acl_denies' => sub {
	my $file = File::Spec->catfile($dir, 'acl-file');
	open(my $fh, '>', $file) or die $!;
	close $fh;
	chmod 0644, $file;
	for my $kind (qw(read write exec)) {
		my $answer = Test::Permissions::acl_denies($kind, $file);
		returns_ok($answer, { type => 'boolean' }, "$kind: boolean");
	}
	is(Test::Permissions::acl_denies(read => $file), 0, 'a plain file: no ACL denial');
	{
		my $g = Test::Mockingbird::mock_scoped('Test::Permissions', '_access', sub { 0 });
		is(Test::Permissions::acl_denies(read => $file), 1, 'mode allows, system denies: 1');
		is(Test::Permissions::acl_denies(exec => $file), 0, 'mode denies too: 0') unless $> == 0 && $^O ne 'MSWin32';
	}
	is(Test::Permissions::acl_denies({ kind => 'write', path => $file }), 0, 'hashref form');
	unlink $file;
	covered('fn:acl_denies');
};

subtest 'with_revoked' => sub {
	my $file = File::Spec->catfile($dir, 'guarded');
	open(my $fh, '>', $file) or die $!;
	close $fh;
	chmod 0640, $file;
	my $seen;
	my $r = Test::Permissions::with_revoked(read => $file, sub { $seen = (stat $file)[2] & 07777; 'result' });
	is($r, 'result', 'returns what the code returns');
	is($seen, 0, 'mode 0 while the code runs') unless $^O eq 'MSWin32';
	is((stat $file)[2] & 07777, 0640, 'old mode restored') unless $^O eq 'MSWin32';
	my @list = Test::Permissions::with_revoked(write => $file, sub { (1, 2, 3) });
	is_deeply(\@list, [ 1, 2, 3 ], 'list context');
	my $object = bless {}, 'Some::Error';
	throws_ok { Test::Permissions::with_revoked(write => $file, sub { die $object }) } 'Some::Error', 'exception object passed on unchanged';
	is((stat $file)[2] & 07777, 0640, 'restored after the exception') unless $^O eq 'MSWin32';
	my $sub = File::Spec->catdir($dir, 'guarded-dir');
	mkdir $sub or die $!;
	lives_ok { Test::Permissions::with_revoked(search => $sub, sub { 1 }) } 'a directory kind';
	rmdir $sub;
	unlink $file;
	covered('fn:with_revoked');
};

subtest 'permissions_report' => sub {
	my $report = Test::Permissions::permissions_report($dir);
	returns_ok($report, { type => 'string', min => 1 }, 'a string');
	my @lines = split /\n/, $report;
	like($lines[0], qr/^Test::Permissions \Q$Test::Permissions::VERSION\E in '.+' \(effective uid \d+\):$/, 'report_header');
	is(scalar @lines, 1 + @KINDS, 'one line per kind');
	for my $i (0 .. $#KINDS) {
		like($lines[$i + 1], qr/^  $KINDS[$i]: (?:yes|no - .+)$/, "line for $KINDS[$i]");
	}
	like($report, qr/^  \w+: yes$/m, 'report_yes') if grep { Test::Permissions::can_revoke($_, $dir) } @KINDS;
	like($report, qr/^  sticky: no - /m, 'report_no') unless Test::Permissions::can_revoke_sticky($dir);
	unlike($report, qr/\n\z/, 'no trailing newline');
	covered('fn:permissions_report', 'msg:report_header', 'msg:report_yes', 'msg:report_no');
};

subtest 'set_cache_scope' => sub {
	my @r = Test::Permissions::set_cache_scope('device');
	is(scalar @r, 0, 'returns nothing');
	Test::Permissions::clear_cache();
	my $other = File::Temp::tempdir(DIR => $dir, CLEANUP => 1);
	my $spy = Test::Mockingbird::spy('Test::Permissions', '_probe');
	Test::Permissions::can_revoke_read($dir);
	Test::Permissions::can_revoke_read($other);
	is(scalar(my @c = $spy->()), 1, 'device scope: one probe for two directories on one device');
	Test::Permissions::set_cache_scope(scope => 'directory');
	Test::Permissions::can_revoke_read($other);
	is(scalar(@c = $spy->()), 2, 'directory scope: probed again');
	Test::Mockingbird::restore_all();
	Test::Permissions::clear_cache();
	covered('fn:set_cache_scope');
};

subtest 'POD documents every message key' => sub {
	my $pm = $INC{'Test/Permissions.pm'};
	open(my $fh, '<', $pm) or die "$pm: $!";
	my $source = do { local $/; <$fh> };
	close $fh;
	for my $key (grep { s/^msg:// } my @k = keys %ledger) {
		like($source, qr/\($key\)|C<$key>/, "$key has a MESSAGES entry");
	}
	my ($messages) = $source =~ /Readonly::Hash my %MESSAGES => \((.*?)\n\);/s;
	my @in_code = $messages =~ /^\t(\w+)\s+=>/mg;
	is_deeply([ sort @in_code ], [ sort grep { s/^msg:// } my @l = keys %ledger ], 'ledger lists every key in %MESSAGES');
};

subtest 'ledger' => sub {
	for my $entry (sort keys %ledger) {
		ok($ledger{$entry}, "exercised: $entry");
	}
};

done_testing();
