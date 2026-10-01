#!/usr/bin/env perl

# Hostile and pathological inputs and caller state: odd directory names,
# odd values of $/, $_, $@, $! and umask, die hooks, directories the probe
# cannot write to, and many calls.

use strict;
use warnings;

use Errno ();
use File::Spec ();
use File::Temp ();
use Test::Mockingbird ();
use Test::Most;
use Test::Warnings;

use lib 'lib';
use Test::Permissions qw(:all);

my @KINDS = qw(read write create search exec delete);
my $root = File::Temp::tempdir(CLEANUP => 1);

sub listing {
	my ($dir) = @_;
	opendir(my $dh, $dir) or die "$dir: $!";
	my @names = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
	closedir $dh;
	return \@names;
}

subtest 'hostile directory names' => sub {
	my @names = (
		'with space', q{it's "quoted"}, '-leading-dash', 'semi;colon & amp',
		'$(echo pwned)', '*glob?', "caf\xC3\xA9",
	);
	push @names, "new\nline", "esc\e[31m", "bidi\xE2\x80\xAEtxt" unless $^O eq 'MSWin32';
	for my $name (@names) {
		my $dir = File::Spec->catdir($root, $name);
		mkdir $dir or do { pass("cannot create '$name' here"); next };
		for my $kind (@KINDS) {
			clear_cache();
			my $answer;
			lives_ok { $answer = can_revoke($kind, $dir) } "$kind in hostile dir lives";
			like($answer, qr/\A[01]\z/, "... answer is 1 or 0");
			is_deeply(listing($dir), [], '... nothing left');
		}
		my $g = Test::Mockingbird::mock_scoped('Test::Permissions', '_make_probe_dir', sub { die "no\n" });
		clear_cache();
		my $why = why_not('read', $dir);
		unlike($why, qr/[\x00-\x1F\x7F]|\xE2\x80\xAE/, 'no raw control or bidi characters in the reason');
		like($why, qr/\\x\{A\}|\\x\{1B\}|\\x\{202E\}/, 'escaped instead') if $name =~ /[\n\e]|\xE2\x80\xAE/;
	}
	clear_cache();
};

subtest 'relative directory and spellings of the same directory' => sub {
	my $spy = Test::Mockingbird::spy('Test::Permissions', '_make_probe_dir');
	clear_cache();
	can_revoke_read($root);
	can_revoke_read("$root/");
	can_revoke_read(File::Spec->catdir($root, File::Spec->curdir));
	is(scalar(my @c = $spy->()), 1, 'one probe for several spellings');
	Test::Mockingbird::restore_all();

	my $cwd = Cwd::getcwd();
	chdir $root or die $!;
	mkdir 'rel' or die $!;
	lives_ok { can_revoke_write('rel') } 'relative dir';
	chdir $cwd or die $!;
	is_deeply(listing(File::Spec->catdir($root, 'rel')), [], 'nothing left in relative dir');
	clear_cache();
};

subtest 'caller state is preserved and does not matter' => sub {
	my $dir = File::Temp::tempdir(DIR => $root);
	clear_cache();
	my $old_umask = umask 0027;
	# Read it back: Windows keeps only the owner-write bit, so 0027 is 0.
	my $caller_umask = umask;
	local $/ = \1;	# record reads
	local $_ = 'caller topic';
	$@ = 'caller error';
	$! = Errno::EINTR();
	my @answers = map { can_revoke($_, $dir) } @KINDS;
	my @why = map { why_not($_, $dir) } @KINDS;
	is($@, 'caller error', '$@ unchanged');
	is(0 + $!, Errno::EINTR(), '$! unchanged');
	is($_, 'caller topic', '$_ unchanged');
	is(umask, $caller_umask, 'umask unchanged');
	umask $old_umask;

	local $/;
	clear_cache();
	is_deeply([ map { can_revoke($_, $dir) } @KINDS ], \@answers, 'same answers with a normal $/ and umask');

	$@ = 'caller error';
	eval { can_revoke('nope') };
	like($@, qr/Unknown access kind/, 'a croak replaces $@ as usual');
	clear_cache();
};

subtest 'umask 0777 does not change the answer' => sub {
	my $dir = File::Temp::tempdir(DIR => $root);
	clear_cache();
	my @normal = map { can_revoke($_, $dir) } @KINDS;
	clear_cache();
	my $old = umask 0777;
	my @masked = map { can_revoke($_, $dir) } @KINDS;
	umask $old;
	is_deeply(\@masked, \@normal, 'same answers');
	is_deeply(listing($dir), [], 'nothing left');
	clear_cache();
};

subtest "caller's die and warn hooks" => sub {
	my $dir = File::Temp::tempdir(DIR => $root);
	clear_cache();
	my @died;
	local $SIG{__DIE__} = sub { push @died, @_ };
	my $g = Test::Mockingbird::mock_scoped('Test::Permissions', '_try_open', sub { die "inside\n" });
	is(can_revoke_read($dir), 0, 'answer 0');
	is_deeply(\@died, [], 'die hook did not see internal exceptions');
	clear_cache();
};

SKIP: {
	skip 'an unwritable directory needs chmod to work', 1
		unless can_revoke_create($root);
	subtest 'a directory the probe cannot write to' => sub {
		my $dir = File::Temp::tempdir(DIR => $root);
		chmod 0500, $dir or die $!;
		clear_cache();
		for my $kind (@KINDS) {
			is(can_revoke($kind, $dir), 0, "$kind: 0");
			like(why_not($kind, $dir), qr/\ACould not set up the $kind probe in '.*': /, "$kind: reason_setup_failed");
		}
		chmod 0700, $dir;
		clear_cache();
	};
}

subtest 'dir that is not a directory' => sub {
	my $file = File::Spec->catfile($root, 'file');
	open(my $fh, '>', $file) or die $!;
	close $fh;
	throws_ok { can_revoke_read($file) } qr/is not a directory/, 'a plain file';
	throws_ok { can_revoke_read("$root/missing") } qr/is not a directory/, 'missing';
	throws_ok { can_revoke_read("$file/sub") } qr/is not a directory/, 'below a file';
	unlink $file;
	SKIP: {
		skip 'no symlinks', 2 unless eval { symlink($root, "$root/link") };
		lives_ok { can_revoke_read("$root/link") } 'a symlink to a directory is followed';
		symlink("$root/nowhere", "$root/dangling");
		throws_ok { can_revoke_read("$root/dangling") } qr/is not a directory/, 'a dangling symlink';
		unlink "$root/link", "$root/dangling";
	}
};

subtest 'odd values for kind' => sub {
	for my $kind ('READ', ' read', 'read ', 'rea', 'readx', '0', "read\0") {
		(my $shown = $kind) =~ s/\0/\\0/g;
		throws_ok { can_revoke($kind, $root) } qr/Unknown access kind|Required/, "'$shown' refused";
	}
	throws_ok { can_revoke(undef, $root) } qr/Required parameter 'kind'/, 'undef refused';
	throws_ok { can_revoke([ 'read' ], $root) } qr/must be a string/, 'reference refused';
};

subtest 'odd calling forms' => sub {
	throws_ok { can_revoke_read(dir => $root, extra => 1) } qr/Unknown parameter 'extra'/, 'unknown named key';
	throws_ok { can_revoke_read({ dir => $root, extra => 1 }) } qr/Unknown parameter 'extra'/, 'unknown key in hashref';
	throws_ok { can_revoke_read({}, 1) } qr/Too many arguments/, 'hashref plus more';
	lives_ok { can_revoke_read({}) } 'empty hashref: default dir';
	lives_ok { can_revoke_read(undef) } 'undef dir: default dir';
	lives_ok { can_revoke_read(dir => undef) } 'named undef dir: default dir';
	throws_ok { can_revoke_read(sub { 1 }) } qr/must be a string/, 'code reference';
	throws_ok { can_revoke_read(\*STDIN) } qr/must be a string/, 'glob reference';
	throws_ok { can_revoke('read', $root, undef) } qr/Too many arguments/, 'an extra positional argument is refused, even undef';
};

subtest 'many calls stay cheap' => sub {
	clear_cache();
	can_revoke_read($root);
	my $spy = Test::Mockingbird::spy('Test::Permissions', '_probe');
	can_revoke_read($root) for 1 .. 1000;
	is(scalar(my @c = $spy->()), 0, '1000 cached calls, no probe');
	Test::Mockingbird::restore_all();
	clear_cache();
};

subtest 'a very long directory name' => sub {
	my $name = 'd' x 200;
	my $dir = File::Spec->catdir($root, $name);
	SKIP: {
		skip 'long names not supported here', 1 unless mkdir $dir;
		clear_cache();
		lives_ok { can_revoke_search($dir) } 'probes';
		is_deeply(listing($dir), [], 'nothing left');
	}
};

clear_cache();
done_testing();
