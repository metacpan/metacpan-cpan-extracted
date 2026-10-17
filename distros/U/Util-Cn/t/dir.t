#!/usr/bin/env perl
# dir(): filtered directory listing with -X file tests, regex, recursion,
# an optional streaming callback, and a forked recursive walk (cpu => N).
require 5.010001;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use File::Temp qw(tempdir);
use File::Spec;
use Util::Cn;

# Build an isolated tree so results don't depend on the checkout's contents.
my $root = tempdir( CLEANUP => 1 );
my %made;
for my $rel (qw(a.txt b.txt c.log sub/d.txt sub/e.log)) {
	my $abs = File::Spec->catfile($root, $rel);
	my ($vol, $dirs, undef) = File::Spec->splitpath($abs);
	mkdir File::Spec->catpath($vol, $dirs, '') unless -d File::Spec->catpath($vol, $dirs, '');
	open my $fh, '>', $abs or die "$abs: $!";
	print $fh "x\n";
	close $fh;
	$made{$rel} = 1;
}
mkdir File::Spec->catdir($root, 'emptydir');

# --- non-recursive, regex filter ---
my @txt = sort { $a cmp $b } dir(dir => $root, regex => '\.txt$');
is_deeply( [map { (File::Spec->splitpath($_))[2] } @txt],
	['a.txt', 'b.txt'], 'non-recursive .txt filter (top level only)' );

# --- default tests => 'f' excludes directories ---
my @all = dir(dir => $root, regex => '.');
ok( !(grep { /emptydir$/ } @all), 'default f-test excludes subdirectories' );
ok(  (grep { /a\.txt$/ }  @all), 'default f-test includes plain files' );

# --- tests => 'd' returns only directories ---
my @dirs = dir(dir => $root, regex => '.', tests => 'd');
ok( (grep { /emptydir$/ } @dirs), 'tests => d finds the empty directory' );
ok( (grep { /sub$/ }      @dirs), 'tests => d finds the sub directory' );
ok( !(grep { /\.txt$/ }   @dirs), 'tests => d excludes files' );

# --- recursive descent ---
my @rtxt = dir(dir => $root, regex => '\.txt$', recursive => 1);
is( scalar @rtxt, 3, 'recursive .txt finds a.txt, b.txt, sub/d.txt' );
ok( (grep { /sub.d\.txt$/ } @rtxt), 'recursion descends into sub/' );

# --- empty tests string => no file-type filtering ---
my @notest = dir(dir => $root, regex => 'emptydir', tests => '');
ok( (grep { /emptydir$/ } @notest), 'empty tests string disables filtering' );

# --- on_match callback streams results and returns empty list ---
my @collected;
my @ret = dir(
	dir      => $root,
	regex    => '\.txt$',
	on_match => sub { push @collected, $_[0] },
);
is( scalar @ret, 0, 'on_match makes dir() return an empty list' );
is( scalar @collected, 2, 'on_match received both top-level .txt files' );

# --- "/" does not become "//" ---
ok( !(grep { m{\A//} } dir(dir => '/', tests => 'd')), 'dir => "/" yields "/x", not "//x"' );
# "///" used to be left as it was, and joined as "////x".
ok( !(grep { m{\A//} } dir(dir => '///', tests => 'd')), 'dir => "///" yields "/x", not "////x"' );

# --- cpu => N: forked recursive walk ---
# dir() walks breadth-first in the parent until a level holds cpu * 4
# directories, so the tree must be wider than that or nothing is ever forked.
# 12 top-level dirs > 2 * 4, each with a nested level so workers descend.
my $wide = tempdir( CLEANUP => 1 );
for my $i (1 .. 12) {
	mkdir "$wide/d$i";
	mkdir "$wide/d$i/inner";
	for my $f ("$wide/d$i/f$i.txt", "$wide/d$i/inner/g$i.txt", "$wide/d$i/inner/h$i.log") {
		open my $fh, '>', $f or die "$f: $!";
		close $fh;
	}
}
# symlink() dies where it is unimplemented and, on Windows, fails for a user
# without the privilege to create one, so the check that needs it is skipped
# there rather than failed.
my $have_symlink = eval { symlink "$wide/d1", "$wide/link_to_d1" };

for my $case (
	[ 'default tests'   => () ],
	[ 'tests => d'      => (tests => 'd') ],
	[ 'regex .txt'      => (regex => '\.txt$') ],
	[ 'no tests'        => (tests => '') ],
) {
	my ($name, @opt) = @$case;
	my @serial   = sort(dir(dir => $wide, recursive => 1, @opt));
	my @parallel = sort(dir(dir => $wide, recursive => 1, cpu => 2, @opt));
	is_deeply( \@parallel, \@serial, "cpu => 2 matches serial ($name)" );
}
is( scalar(dir(dir => $wide, recursive => 1, cpu => 2, regex => '\.txt$')), 24,
	'cpu => 2 finds every .txt at both depths' );
SKIP: {
	skip 'symlink() is not available here', 1 unless $have_symlink;
	ok( !(grep { m{link_to_d1/} } dir(dir => $wide, recursive => 1, cpu => 2, tests => '')),
		'cpu => 2 does not descend through a symlinked directory' );
}

# A dir that is itself a symlink to a directory is listed through the link in
# every mode.  The serial recursive walk used to find nothing, because
# File::Find took the link for a file, while the other two followed it.
{
	my $links = tempdir( CLEANUP => 1 );
	my $link  = File::Spec->catdir($links, 'wide');
	SKIP: {
		skip 'symlink() is not available here', 5 unless eval { symlink $wide, $link };
		is( scalar(dir(dir => $link, regex => '^d\d+\z', tests => 'd')), 12,
			'non-recursive dir lists through a symlinked root' );
		my @serial   = sort(dir(dir => $link, recursive => 1));
		my @parallel = sort(dir(dir => $link, recursive => 1, cpu => 2));
		is( scalar @serial, 36, 'serial recursive dir walks a symlinked root' );
		is_deeply( \@parallel, \@serial, 'cpu => 2 matches serial under a symlinked root' );
		ok( !(grep { index($_, "$link/") != 0 } @serial), 'paths are reported under the link, not its target' );
		is( scalar(dir(dir => "$link/", recursive => 1)), 36, 'a trailing slash on the link makes no difference' );
	}
}

# on_match runs in the parent, so a closure over a lexical still works.
my %seen;
my @none = dir(dir => $wide, recursive => 1, cpu => 3, on_match => sub { $seen{$_[0]}++ });
is( scalar @none, 0, 'cpu => 3 with on_match returns an empty list' );
is( scalar(keys %seen), 36, 'cpu => 3 on_match saw every file in the parent' );
ok( !(grep { $_ != 1 } values %seen), 'cpu => 3 on_match saw each file once' );

{
	# Relative root: "." is stripped from results exactly as in the serial walk.
	my $old = File::Spec->rel2abs('.');
	chdir $wide or die "chdir $wide: $!";
	my @s = sort(dir(recursive => 1));
	my @p = sort(dir(recursive => 1, cpu => 2));
	chdir $old or die "chdir $old: $!";
	is_deeply( \@p, \@s, 'cpu => 2 with dir => "." matches serial' );
	ok( !(grep { m{\A\./} } @p), 'cpu => 2 with dir => "." has no leading ./' );
}

throws_ok { dir(dir => $root, recursive => 1, cpu => 0) }
	qr/cpu must be a positive integer/, 'rejects cpu => 0';
throws_ok { dir(dir => $root, recursive => 1, cpu => 'two') }
	qr/cpu must be a positive integer/, 'rejects non-numeric cpu';

# --- error handling ---
throws_ok { dir(dir => $root, bogus => 1) }
	qr/Unrecognized arguments/, 'rejects unknown named args';
throws_ok { dir(dir => $root, tests => 'Z') }
	qr/Unrecognized characters in tests/, 'rejects invalid test chars';
throws_ok { dir(dir => $root, regex => '(') }
	qr/Invalid regex/, 'rejects an uncompilable regex';
# The alternation is historical: Util.pm, which this module was before it was
# Util::Cn, used to `use autodie`, which intercepted opendir and threw "Can't
# opendir(...)" before the module's own `or die "Cannot open directory"` could
# run. autodie is gone now (it cost ~15 ms of startup and is a compile-time
# pragma, so it could not be made lazy), so this always takes the second
# branch -- but matching either keeps the test honest about what it actually
# cares about: that dir() dies.
throws_ok { dir(dir => File::Spec->catdir($root, 'no', 'such', 'dir'), regex => '.') }
	qr/(opendir|Cannot open directory)/, 'dies on a missing directory';

done_testing;
