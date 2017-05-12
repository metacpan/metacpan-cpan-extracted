######################################################################
# Test suite for Trash::Park
# by Mike Schilli <cpan@perlmeister.com>
######################################################################
use warnings;
use strict;
use Test::More;
use Sysadm::Install qw(:all);
use File::Temp qw(tempdir tempfile);
use File::Basename;

use Trash::Park;

plan tests => 23;

my $trash_dir = tempdir(CLEANUP => 1);
my $work_dir  = tempdir(CLEANUP => 1);

my $trasher = Trash::Park->new(trash_dir => $trash_dir);

my $work_file = "$work_dir/quack/schmack";
mkd(dirname $work_file);
blurt "foobarbaz", $work_file;
ok(-f $work_file, "workfile written");

$trasher->trash($work_file);

ok(! -f $work_file, "workfile removed");

my $history = $trasher->history();
ok($history, "history fetched");
is(scalar @$history, 1, "1 history entry");
like($history->[0]->{file}, qr{quack/schmack}, "file in history");

my $repo = $trasher->repo() . "/$history->[0]->{file}";
ok(-f $repo, "repo file exists");
my $data = slurp $repo;
is($data, "foobarbaz", "repo file data check");

$work_file = "$work_dir/quack/schmack2";
blurt "foobarbaz2", $work_file;
ok(-f $work_file, "workfile written");
$trasher->trash($work_file);
ok(! -f $work_file, "workfile removed");

$history = $trasher->history();
ok($history, "history fetched");
is(scalar @$history, 2, "2 history entries");
like($history->[0]->{file}, qr{quack/schmack}, "file in history");
like($history->[1]->{file}, qr{quack/schmack2}, "file in history");

$repo = $trasher->repo() . "/$history->[0]->{file}";
ok(-f $repo, "repo file exists");
$data = slurp $repo;
is($data, "foobarbaz", "repo file data check");

$repo = $trasher->repo() . "/$history->[1]->{file}";
ok(-f $repo, "repo file exists");
$data = slurp $repo;
is($data, "foobarbaz2", "repo file data check");

# Directories
$work_file = "$work_dir/quack/schmack3";
blurt "foobarbaz1", $work_file;
$work_file = "$work_dir/quack/schmack4";
blurt "foobarbaz2", $work_file;
$work_file = "$work_dir/quack/schmack5";
blurt "foobarbaz3", $work_file;
$trasher->trash($work_dir);

ok(!-d $work_dir, "work dir gone");

$history = $trasher->history();
ok($history, "history fetched");

ok(grep($_->file() =~ /schmack3/, @{$trasher->history()}), 
  "file in trash");
ok(grep($_->file() =~ /schmack4/, @{$trasher->history()}), 
  "file in trash");
ok(grep($_->file() =~ /schmack5/, @{$trasher->history()}), 
  "file in trash");

######################################################################
# Expire
######################################################################
    # Expire all
$trasher->expire(-1);
$history = $trasher->history();
is(@$history, 0, "empty history after expire");

