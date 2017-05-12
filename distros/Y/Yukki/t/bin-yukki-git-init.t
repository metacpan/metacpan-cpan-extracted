#!/usr/bin/env perl
use 5.12.1;

use File::Temp qw( tempdir );
use Git::Repository;
use Test::More tests => 12;
use Test::Script;

script_compiles('bin/yukki-setup', 'yukki-setup compiles');
script_compiles('bin/yukki-git-init', 'yukki-git-init compiles');

my $tempdir = tempdir;
diag("TEMPDIR = $tempdir") if $ENV{YUKKI_TEST_KEEP_FILES};

script_runs([ 'bin/yukki-setup', "$tempdir/yukki-test" ], 
    'yukki-setup runs');

ok(-d "$tempdir/yukki-test", 'created the test directory');
ok(!-f "$tempdir/yukki-test/var/db/users/foo", 
    'the user we are about to create does not exist yet');

$ENV{YUKKI_CONFIG} = "$tempdir/yukki-test/etc/yukki.conf";
script_runs([ 'bin/yukki-git-init', 'main' ], 'yukki-git-init main ran');

ok(-d "$tempdir/yukki-test/repositories", 'created the repositories directory');
ok(-d "$tempdir/yukki-test/repositories/main.git", 'created the main.git repository');

my $git = Git::Repository->new( git_dir => "$tempdir/yukki-test/repositories/main.git" );
my $list = $git->run('ls-tree', 'refs/heads/master');

like($list, qr/\bhome\.yukki\b/, 'created home.yukki');

my $first_comment = $git->run('show', 'refs/heads/master');
like($first_comment, qr/Initializing/, 'expected comment');
like($first_comment, qr{diff --git a/home.yukki b/home.yukki}, 'contains the expected file');
like($first_comment, qr{\+\# Main}, 'the file has expected heading');
