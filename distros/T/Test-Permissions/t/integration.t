#!/usr/bin/env perl

# End to end: a separate perl runs a test file that uses Test::Permissions
# the way a downstream distribution does, and its TAP output is checked.
# No mocking: this is also the real-filesystem consistency check.  When an
# answer is 1, the restricted state is set up by hand and the operation
# must really fail; when it is 0, why_not must explain.

use strict;
use warnings;

use Config ();
use Cwd ();
use File::Spec ();
use File::Temp ();
use Test::Most;
use Test::Warnings;

use lib 'lib';
use Test::Permissions qw(:all);

my $lib = Cwd::abs_path('lib');
my $work = File::Temp::tempdir(CLEANUP => 1);

# write_program($name, $code): write a helper program to a file.  (A long
# -e is flattened on Windows.)
sub write_program {
	my ($name, $code) = @_;
	my $path = File::Spec->catfile($work, $name);
	open(my $fh, '>', $path) or die "$path: $!";
	print {$fh} $code;
	close $fh or die "$path: $!";
	return $path;
}

# run(@args): run perl with -I lib, returning (output with CRLF normalised,
# exit status).
sub run {
	my @args = @_;
	open(my $out, '-|', $^X, "-I$lib", @args) or die "Cannot run $^X: $!";
	my $text = do { local $/; <$out> };
	close $out;
	my $status = $? >> 8;
	$text = '' unless defined $text;
	$text =~ s/\r\n/\n/g;
	return ($text, $status);
}

my $downstream = write_program('downstream.t', <<'PROGRAM');
use strict;
use warnings;
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;
use Test::Permissions qw(:revoke :guard :report);

my $dir = tempdir(CLEANUP => 1);
note(permissions_report($dir));
my %attempt = (
	read   => sub { my ($d) = @_; my $f = "$d/f"; open(my $w, '>', $f) or die; close $w;
			chmod 0, $f; my $ok = open(my $r, '<', $f); chmod 0600, $f; !$ok },
	write  => sub { my ($d) = @_; my $f = "$d/f"; open(my $w, '>', $f) or die; close $w;
			chmod 0400, $f; my $ok = open(my $a, '>>', $f); chmod 0600, $f; !$ok },
	create => sub { my ($d) = @_; mkdir "$d/sub" or die; chmod 0500, "$d/sub";
			my $ok = open(my $w, '>', "$d/sub/new"); chmod 0700, "$d/sub"; !$ok },
	search => sub { my ($d) = @_; mkdir "$d/sub" or die; open(my $w, '>', "$d/sub/f") or die; close $w;
			chmod 0, "$d/sub"; my $ok = stat "$d/sub/f"; chmod 0700, "$d/sub"; !$ok },
	exec   => sub { my ($d) = @_; my $f = "$d/s"; open(my $w, '>', $f) or die; print $w "#!/bin/sh\nexit 0\n"; close $w;
			chmod 0600, $f; no warnings 'exec'; my $rc = system { $f } $f; $rc == -1 },
	delete => sub { my ($d) = @_; mkdir "$d/sub" or die; open(my $w, '>', "$d/sub/f") or die; close $w;
			chmod 0500, "$d/sub"; my $ok = unlink "$d/sub/f"; chmod 0700, "$d/sub"; !$ok },
	# As root only: uid 65533 must not delete uid 65534's file from a
	# sticky directory.  chdir first, so uid 65533 needs no access above.
	sticky => sub { my ($d) = @_; mkdir "$d/sub" or die; chmod 01777, "$d/sub";
			open(my $w, '>', "$d/sub/f") or die; close $w; chown 65534, -1, "$d/sub/f" or die;
			require Cwd; my $cwd = Cwd::getcwd(); chdir "$d/sub" or die;
			my $ok; { local $> = 65533; $ok = unlink 'f' } chdir $cwd or die; !$ok },
);

# with_revoked, the way a downstream test would use it.
SKIP: {
	skip 'with_revoked: chmod cannot revoke read access here', 1 unless can_revoke_read($dir);
	my $f = "$dir/guarded";
	open(my $w, '>', $f) or die;
	close $w;
	with_revoked(read => $f, sub { ok(!open(my $r, '<', $f), 'with_revoked: unreadable inside the block') });
	unlink $f;
}

for my $kind (qw(read write create search exec delete sticky)) {
	my $answer = can_revoke($kind, $dir);
	print "# ANSWER $kind $answer\n";
	if(!$answer) {
		my $why = why_not($kind, $dir);
		ok(defined $why && length $why, "$kind: why_not explains a 0");
		print "# WHY $kind $why\n";
	}
	SKIP: {
		skip_unless_can_revoke($kind, 2, $dir);
		ok(!defined why_not($kind, $dir), "$kind: why_not is undef for a 1");
		my $scratch = tempdir(DIR => $dir, CLEANUP => 1);
		ok($attempt{$kind}->($scratch), "$kind: the restricted operation really fails");
	}
}
opendir(my $dh, $dir) or die;
my @left = grep { !/^\.\.?$/ && !/^[A-Za-z0-9_]{10}$/ } readdir $dh;
is_deeply(\@left, [], 'no probe directories left');
done_testing();
PROGRAM

subtest 'a downstream test file' => sub {
	my ($output, $status) = run($downstream);
	is($status, 0, 'exits 0') or diag($output);
	my %answer = $output =~ /^# ANSWER (\w+) ([01])$/mg;
	is(scalar keys %answer, 7, 'an answer for every kind');
	for my $kind (sort keys %answer) {
		if($answer{$kind}) {
			like($output, qr/^ok \d+ - $kind: the restricted operation really fails$/m, "$kind: consistent with a real chmod");
		} else {
			# Not every reason names the kind (reason_chmod_ignored does
			# not), so match the text why_not gave for this kind.
			my ($why) = $output =~ /^# WHY $kind (.+)$/m;
			my @skips = $output =~ /^ok \d+ # skip (.+)$/mg;
			ok(defined $why && (grep { $_ eq $why } @skips) == 2, "$kind: exactly 2 tests skipped, with the reason")
				or diag($output);
		}
	}
	unlike($output, qr/^not ok/m, 'no failures');
	like($output, qr/^1\.\.\d+$/m, 'a plan');
};

subtest 'answers agree with this process' => sub {
	my ($output) = run($downstream);
	my %answer = $output =~ /^# ANSWER (\w+) ([01])$/mg;
	my $dir = File::Temp::tempdir(CLEANUP => 1);
	is(can_revoke($_, $dir), $answer{$_}, "$_: same answer on the same filesystem") for sort keys %answer;
};

subtest 'loaded without importing anything' => sub {
	my $program = write_program('plain.pl', <<'PROGRAM');
use strict;
use warnings;
use Test::Permissions ();
my @subs = sort grep { defined &{"Test::Permissions::$_"} } keys %Test::Permissions::;
print join(',', grep { !/^_/ } @subs), "\n";
print defined &main::can_revoke ? "leaked\n" : "clean\n";
PROGRAM
	my ($output, $status) = run($program);
	is($status, 0, 'runs');
	is((split /\n/, $output)[0],
		'acl_denies,can_revoke,can_revoke_create,can_revoke_delete,can_revoke_exec,can_revoke_read,can_revoke_search,can_revoke_sticky,can_revoke_write,clear_cache,permissions_report,set_cache_scope,set_messages,skip_unless_can_revoke,why_not,with_revoked',
		'the package holds only its own public subs: nothing imported')
		or diag($output);
	like($output, qr/^clean$/m, 'nothing exported by default');
};

subtest 'nothing left behind at exit' => sub {
	my $dir = File::Temp::tempdir(CLEANUP => 1);
	my $program = write_program('exit.pl', <<'PROGRAM');
use strict;
use warnings;
use Test::Permissions ();
Test::Permissions::can_revoke($_, $ARGV[0]) for qw(read write create search exec delete sticky);
PROGRAM
	my (undef, $status) = run($program, $dir);
	is($status, 0, 'runs');
	opendir(my $dh, $dir) or die;
	is_deeply([ grep { !/^\.\.?$/ } readdir $dh ], [], 'directory empty afterwards');
};

subtest 'skip helper outside a SKIP block' => sub {
	my $program = write_program('noskip.pl', <<'PROGRAM');
use strict;
use warnings;
# Before Test::More loads: Test::Builder copies STDERR then, and its
# end-of-run diagnostics must be captured too, not reach the terminal.
BEGIN { open(STDERR, '>&', \*STDOUT) or die; $| = 1 }
use Test::More;
use Test::Permissions ();
no warnings 'redefine';
*Test::Permissions::_try_open = sub { (1, 0) };	# simulate root
Test::Permissions::skip_unless_can_revoke('read', 1);
PROGRAM
	my ($output, $status) = run($program);
	isnt($status, 0, 'dies, as Test::More::skip does');
	like($output, qr/Label not found for "last SKIP"/, "with perl's message");
};

subtest 'taint mode' => sub {
	# PERL5LIB is ignored under -T, so pass its directories with -I.
	my @inc = map { "-I$_" } grep { length } split /\Q$Config::Config{path_sep}\E/, ($ENV{PERL5LIB} || '');
	my $program = write_program('taint.pl', <<'PROGRAM');
use strict;
use warnings;
use Test::Permissions ();
for my $kind (qw(read write create search exec delete sticky)) {
	my $why = Test::Permissions::why_not($kind, $ARGV[0]);
	print "$kind ", Test::Permissions::can_revoke($kind, $ARGV[0]), ' ', (defined $why ? $why : ''), "\n";
}
PROGRAM
	my $dir = File::Temp::tempdir(CLEANUP => 1);
	my ($output, $status) = run('-T', @inc, $program, $dir);
	is($status, 0, 'runs under -T') or diag($output);
	unlike($output, qr/Insecure dependency/, 'no probe fails on tainted data');
	for my $kind (qw(read write create search exec delete)) {
		my ($answer) = $output =~ /^$kind ([01])/m;
		is($answer, can_revoke($kind, $dir), "$kind: the same answer as without -T");
	}
};

SKIP: {
	skip 'Test2::V0 is not installed', 1 unless eval { require Test2::V0; 1 };
	subtest 'a Test2::V0 suite' => sub {
		my $program = write_program('test2.t', <<'PROGRAM');
use Test2::V0;
use Test::Permissions ();
no warnings 'redefine';
*Test::Permissions::_try_open = sub { (1, 0) };	# simulate root
SKIP: {
	Test::Permissions::skip_unless_can_revoke('read', 2);
	ok(0, 'not reached');
	ok(0, 'not reached');
}
print "# TEST_BUILDER ", ($INC{'Test/Builder.pm'} ? 'loaded' : 'not loaded'), "\n";
done_testing;
PROGRAM
		my ($output, $status) = run($program);
		is($status, 0, 'passes') or diag($output);
		my @skips = $output =~ /^ok \d+ # skip (.+)$/mg;
		is(scalar @skips, 2, 'two tests skipped');
		# Root is simulated, so the reason is reason_not_enforced - or, on
		# Windows, where chmod 0 is ignored, reason_chmod_ignored.
		like($skips[0] // '', qr/^chmod (?:cannot revoke read access|did not set mode)/, 'with the reason');
		like($output, qr/^# TEST_BUILDER not loaded$/m, 'without loading Test::Builder');
	};
}

done_testing();
