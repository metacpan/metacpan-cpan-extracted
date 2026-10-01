#!/usr/bin/env perl

# Data flow: where each value is defined and where it is used.
#
#	caller's kind and dir  -> validated copies; the caller's data is
#	                          never modified
#	dir                    -> canonical path -> cache key and reason text
#	errno of the attempt   -> reason text (in the current locale)
#	message text           -> reason, when the probe runs (not later)
#	cache entry            -> answer and reason; callers get copies
#	file handles           -> opened and closed inside each seam
#	caller's $@, $!, $_    -> saved and restored

use strict;
use warnings;

use Cwd ();
use Errno ();
use File::Spec ();
use File::Temp ();
use Test::Mockingbird ();
use Test::Most;
use Test::Warnings;

use lib 'lib';
use Test::Permissions qw(:all);

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

sub attempt_is {
	my @result = @_;
	my @guards = chmod_works();
	for my $seam (qw(_try_open _try_stat)) {
		# The exec probe's real baseline runs a /bin/sh script, which is
		# impossible on Windows; these scenarios are about later steps, so
		# its baseline is simulated as a successful run everywhere.
		my $orig = $seam eq '_try_exec' ? sub { (1, 0) } : \&{"Test::Permissions::$seam"};
		my $calls = 0;
		push @guards, Test::Mockingbird::mock_scoped('Test::Permissions', $seam,
			sub { $calls++ ? @result : $orig->(@_) });
	}
	return @guards;
}

subtest "the caller's data is never modified" => sub {
	my $args = { kind => 'read', dir => $dir };
	my $copy = { %{$args} };
	can_revoke($args);
	why_not($args);
	is_deeply($args, $copy, 'hashref argument unchanged');

	my @list = ('read', $dir);
	can_revoke(@list);
	is_deeply(\@list, [ 'read', $dir ], 'list arguments unchanged');

	my $texts = { reason_other_error => q{%s access in '%s' failed for a reason other than permissions: %s} };
	my $texts_copy = { %{$texts} };
	set_messages($texts);
	is_deeply($texts, $texts_copy, 'set_messages hashref unchanged');

	my $u = { dir => undef };
	can_revoke_read($u);
	ok(exists $u->{dir}, 'undef value in the caller hash not deleted');
};

subtest 'dir -> canonical path -> cache key and reason' => sub {
	clear_cache();
	my @g = attempt_is(1, 0);
	my $spelled = File::Spec->catdir($dir, File::Spec->curdir);
	my $why = why_not('read', $spelled);
	like($why, qr/in '\Q$canon\E'/, 'reason shows the canonical path, not the spelling');
	my $spy = Test::Mockingbird::spy('Test::Permissions', '_probe');
	why_not('read', $dir);
	is(scalar(my @c = $spy->()), 0, 'the other spelling uses the same cache entry');
	Test::Mockingbird::unmock('Test::Permissions', '_probe');
	clear_cache();
};

subtest 'errno of the attempt -> reason text' => sub {
	for my $errno (Errno::ENOSPC(), Errno::EIO(), Errno::EROFS()) {
		clear_cache();
		my @g = attempt_is(0, $errno);
		local $! = $errno;
		my $text = "$!";
		like(why_not('write', $dir), qr/: \Q$text\E\z/, "errno $errno reaches the reason");
	}
	clear_cache();
};

subtest 'message text -> reason, fixed when the probe runs' => sub {
	clear_cache();
	my @g = attempt_is(1, 0);
	set_messages(reason_not_enforced => 'A %s %s');
	my $first = why_not('create', $dir);
	is($first, "A create $canon", 'text in force at probe time');
	set_messages(reason_not_enforced => 'B %s %s');
	is(why_not('create', $dir), $first, 'later changes do not reach the cached reason');
	set_messages(reason_not_enforced => q{chmod cannot revoke %s access in '%s' (running as root, or the filesystem ignores permissions)});
	clear_cache();
};

subtest 'callers get copies of cached values' => sub {
	clear_cache();
	my @g = attempt_is(1, 0);
	my $why = why_not('read', $dir);
	my $saved = $why;
	$why .= ' changed';
	is(why_not('read', $dir), $saved, 'changing a returned reason does not change the cache');
	my $answer = can_revoke('read', $dir);
	$answer = 1;
	is(can_revoke('read', $dir), 0, 'nor does changing a returned answer');
	clear_cache();
};

SKIP: {
	skip 'needs /proc/self/fd', 1 unless -d '/proc/self/fd';
	subtest 'file handles are closed' => sub {
		my $count = sub { opendir(my $dh, '/proc/self/fd') or die; my @fd = grep { /^\d+$/ } readdir $dh; scalar @fd };
		clear_cache();
		my $before = $count->();
		for (1 .. 5) {
			clear_cache();
			can_revoke($_, $dir) for qw(read write create search exec delete sticky);
		}
		is($count->(), $before, 'no descriptor leaked');
		clear_cache();
	};
}

subtest "caller's \$@, \$! and \$_ are saved and restored" => sub {
	clear_cache();
	for my $call (
		[ can_revoke => sub { can_revoke('read', $dir) } ],
		[ can_revoke_search => sub { can_revoke_search($dir) } ],
		[ why_not => sub { why_not('write', $dir) } ],
		[ skip_unless_can_revoke => sub { SKIP: { skip_unless_can_revoke('create', 1, $dir); pass('in block') } } ],
		[ clear_cache => sub { clear_cache() } ],
		[ set_messages => sub { set_messages() } ],
		[ set_cache_scope => sub { set_cache_scope('directory') } ],
		[ acl_denies => sub { acl_denies(read => $dir) } ],
		[ with_revoked => sub { with_revoked(search => $dir, sub { 1 }) } ],
		[ permissions_report => sub { permissions_report($dir) } ],
	) {
		my ($name, $code) = @{$call};
		local $_ = 'topic';
		$@ = 'before';
		$! = Errno::EAGAIN();
		$code->();
		is($@, 'before', "$name: \$@");
		is(0 + $!, Errno::EAGAIN(), "$name: \$!");
		is($_, 'topic', "$name: \$_");
	}
	clear_cache();
};

subtest 'mode -> with_revoked -> the same mode' => sub {
	my $file = File::Spec->catfile($dir, 'flow');
	open(my $fh, '>', $file) or die $!;
	close $fh;
	for my $mode (0600, 0640, 0755, 0444) {
		chmod $mode, $file;
		my $before = (stat $file)[2] & 07777;
		with_revoked(write => $file, sub { 1 });
		is((stat $file)[2] & 07777, $before, sprintf('mode %04o restored exactly', $mode));
	}
	chmod 0600, $file;
	unlink $file;
};

subtest 'effective uid and groups -> cache key' => sub {
	my ($euid, $egids) = ($>, $));
	like(Test::Permissions::_cache_key('read', $canon), qr/\Aread\x00\Q$euid\E\x00\Q$egids\E\x00/, 'both are part of the key');
};

done_testing();
