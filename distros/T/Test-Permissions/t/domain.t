#!/usr/bin/env perl

# Equivalence partitions and boundary values for every input and output.
#
#	kind    valid: read | write | create | search | exec | delete | sticky
#	        (acl_denies: read | write | exec; with_revoked: all but sticky)
#	        invalid: other strings (case, spaces, prefixes), '', undef
#	        (treated as missing), references
#	path    valid: an existing file or directory (with_revoked: the right
#	        one for the kind); invalid: missing, '', a reference
#	code    valid: a code reference; invalid: anything else
#	scope   valid: directory | device; invalid: anything else
#	dir     valid: an existing directory (absolute, relative, with a
#	        trailing separator, a stringifying object); undef/absent ->
#	        tmpdir
#	        invalid: '', a missing path, a file, a reference
#	count   valid: whole numbers >= 1 (boundary 1; large)
#	        invalid: 0, negatives, fractions, non-numbers, absent
#	message keys: the 19 documented keys; anything else is refused
#	message texts: non-empty strings; '', undef and references refused
#	answer  exactly 1 or 0
#	reason  undef (answer 1) or a non-empty single-line string

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

subtest 'kind' => sub {
	for my $kind (qw(read write create search exec delete sticky)) {
		lives_ok { can_revoke($kind, $dir) } "valid: $kind";
	}
	for my $kind ('Read', 'SEARCH', ' read', 'read ', 're', 'reads', 'execute', 'chown', 'acl', '0', "read\n") {
		(my $shown = $kind) =~ s/\n/\\n/g;
		throws_ok { can_revoke($kind, $dir) } qr/^Unknown access kind/, "invalid: '$shown'";
	}
	throws_ok { can_revoke('', $dir) } qr/^Unknown access kind ''/, "invalid: ''";
	throws_ok { can_revoke(undef, $dir) } qr/Required parameter 'kind'/, 'undef is missing';
	throws_ok { can_revoke({ dir => $dir }) } qr/Required parameter 'kind'/, 'absent';
	throws_ok { can_revoke(\'read', $dir) } qr/must be a string/, 'scalar reference';
};

subtest 'dir' => sub {
	lives_ok { can_revoke_read($dir) } 'absolute';
	lives_ok { can_revoke_read(File::Spec->catdir($dir, '')) } 'trailing separator';
	lives_ok { can_revoke_read(File::Spec->curdir) } 'relative (.)';
	lives_ok { can_revoke_read() } 'absent: tmpdir';
	lives_ok { can_revoke_read(undef) } 'undef: tmpdir';
	throws_ok { can_revoke_read('') } qr/too short/, "'': refused by the validator";
	throws_ok { can_revoke_read(File::Spec->catdir($dir, 'missing')) } qr/is not a directory/, 'missing';
	my $file = File::Spec->catfile($dir, 'f');
	open(my $fh, '>', $file) or die $!;
	close $fh;
	throws_ok { can_revoke_read($file) } qr/is not a directory/, 'a file';
	unlink $file;
	throws_ok { can_revoke_read([ $dir ]) } qr/must be a string/, 'array reference';
	throws_ok { can_revoke_read({ dir => [ $dir ] }) } qr/must be a string/, 'array reference, named';
	throws_ok { can_revoke_read(dir => '0') } qr/is not a directory/, "'0' is a (missing) path, not false";
};

subtest 'count' => sub {
	my @g = chmod_works();
	for my $seam (qw(_try_open _try_stat)) {
		# The exec probe's real baseline runs a /bin/sh script, which is
		# impossible on Windows; these scenarios are about later steps, so
		# its baseline is simulated as a successful run everywhere.
		my $orig = $seam eq '_try_exec' ? sub { (1, 0) } : \&{"Test::Permissions::$seam"};
		my $n = 0;
		push @g, Test::Mockingbird::mock_scoped('Test::Permissions', $seam, sub { $n++ ? (0, Errno::EACCES()) : $orig->(@_) });
	}
	clear_cache();
	for my $count (1, 2, 1_000_000, '3') {
		SKIP: {
			lives_ok { skip_unless_can_revoke('read', $count, $dir) } "valid: $count";
		}
	}
	for my $count (0, -1, -1000, 1.5, '1e0x', 'x', '') {
		throws_ok { skip_unless_can_revoke('read', $count, $dir) } qr/'count'/, "invalid: '$count'";
	}
	throws_ok { skip_unless_can_revoke('read') } qr/'count' is missing/, 'absent';
	throws_ok { skip_unless_can_revoke('read', undef, $dir) } qr/'count' is missing/, 'undef';
	clear_cache();
};

subtest 'outputs' => sub {
	Test::Permissions::clear_cache();
	for my $kind (qw(read write create search exec delete sticky)) {
		my $answer = can_revoke($kind, $dir);
		ok($answer eq '1' || $answer eq '0', "$kind: answer is exactly 1 or 0");
		returns_ok($answer, { type => 'boolean' }, "$kind: boolean");
		my $why = why_not($kind, $dir);
		returns_ok($why, { type => 'string', optional => 1 }, "$kind: reason schema");
		ok(!defined $why || ($why ne '' && $why !~ /\n/), "$kind: reason undef or one non-empty line");
	}
	my $g = Test::Mockingbird::mock_scoped('Test::Permissions', '_make_probe_dir', sub { die "a\nb\n" });
	clear_cache();
	unlike(why_not('read', $dir), qr/\n/, 'multi-line exception texts are escaped onto one line');
	clear_cache();
};

subtest 'acl_denies: kind and path' => sub {
	my $file = File::Spec->catfile($dir, 'acl');
	open(my $fh, '>', $file) or die $!;
	close $fh;
	for my $kind (qw(read write exec)) {
		lives_ok { acl_denies($kind, $file) } "valid kind: $kind";
	}
	lives_ok { acl_denies(exec => $dir) } 'a directory (exec = search)';
	for my $kind (qw(create search delete sticky)) {
		throws_ok { acl_denies($kind, $file) } qr/^Unknown access kind/, "invalid kind: $kind";
	}
	throws_ok { acl_denies(read => '') } qr/too short/, "path ''";
	throws_ok { acl_denies(read => "$file.none") } qr/does not exist/, 'missing path';
	throws_ok { acl_denies(read => [ $file ]) } qr/must be a string/, 'reference';
	unlink $file;
};

subtest 'with_revoked: kind, path and code' => sub {
	my $file = File::Spec->catfile($dir, 'guard');
	open(my $fh, '>', $file) or die $!;
	close $fh;
	for my $kind (qw(read write exec)) {
		lives_ok { with_revoked($kind, $file, sub { 1 }) } "file kind: $kind";
		throws_ok { with_revoked($kind, $dir, sub { 1 }) } qr/is a directory/, "file kind on a directory: $kind";
	}
	for my $kind (qw(create search delete)) {
		lives_ok { with_revoked($kind, $dir, sub { 1 }) } "directory kind: $kind";
		throws_ok { with_revoked($kind, $file, sub { 1 }) } qr/is not a directory/, "directory kind on a file: $kind";
	}
	throws_ok { with_revoked(sticky => $dir, sub { 1 }) } qr/^Unknown access kind/, 'sticky';
	for my $code ('sub', 1, [], {}) {
		throws_ok { with_revoked(read => $file, $code) } qr/'code'/, 'code: ' . (ref $code || "'$code'");
	}
	throws_ok { with_revoked(read => $file) } qr/'code' is missing/, 'code absent';
	unlink $file;
};

subtest 'set_cache_scope: scope' => sub {
	for my $scope (qw(device directory)) {
		lives_ok { set_cache_scope($scope) } "valid: $scope";
	}
	for my $scope ('Directory', 'dev', 'mount', '') {
		throws_ok { set_cache_scope($scope) } qr/'scope'/, "invalid: '$scope'";
	}
};

subtest 'message keys and texts' => sub {
	my @keys = qw(
		error_unknown_kind error_not_a_directory error_unknown_message error_too_many_arguments
		reason_not_enforced reason_chmod_ignored reason_baseline_failed reason_other_error
		reason_setup_failed reason_cleanup_failed reason_probe_succeeded
	);
	# Run last: the texts are left changed.
	for my $key (@keys) {
		lives_ok { set_messages($key => 'x') } "valid key: $key";
		is(Test::Permissions::_msg($key), 'x', '... applied');
	}
	set_messages(error_unknown_message => q{Unknown message key '%s'});
	for my $key ('ERROR_UNKNOWN_KIND', 'error_unknown', 'reason', '', 'x y') {
		throws_ok { set_messages($key => 'x') } qr/^Unknown message key/, "invalid key: '$key'";
	}
	throws_ok { set_messages(reason_other_error => '') } qr/too short/, "text ''";
	throws_ok { set_messages(reason_other_error => undef) } qr/reason_other_error/, 'text undef';
	throws_ok { set_messages(reason_other_error => {}) } qr/must be a string/, 'text reference';
	lives_ok { set_messages(reason_other_error => ' ') } 'text of one space (boundary: length 1)';
};

done_testing();
