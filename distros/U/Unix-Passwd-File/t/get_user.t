#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';

use File::chdir;
use File::Copy::Recursive qw(rcopy);
use File::Temp qw(tempdir);
use Test::More 0.96;
use Unix::Passwd::File qw(get_user);

my $tmpdir = tempdir(CLEANUP=>1);
$CWD = $tmpdir;
note "tmpdir=$tmpdir";

rcopy("$Bin/data/simple", "$tmpdir/simple");
unlink "$tmpdir/simple/shadow";

subtest "shadow unreadable -> ok" => sub {
    my $res = get_user(etc_dir=>"$tmpdir/simple", user=>"root");
    is_deeply($res->[0], 200, "status");
};

subtest "etc_dir unknown -> error" => sub {
    my $res = get_user(etc_dir=>"$Bin/data/foo", user=>"bin");
    is($res->[0], 500, "status");
};

subtest "by uid, found" => sub {
    my $res = get_user(etc_dir=>"$Bin/data/simple", uid=>2);
    is($res->[0], 200, "status");
    is($res->[2]{user}, "daemon", "res");
};

subtest "by uid, not found" => sub {
    my $res = get_user(etc_dir=>"$Bin/data/simple", uid=>99);
    is($res->[0], 404, "status");
};

subtest "by user, found" => sub {
    my $res = get_user(etc_dir=>"$Bin/data/simple", user=>"bin");
    is($res->[0], 200, "status");
    is($res->[2]{uid}, 1, "res");
};

subtest "by user, not found" => sub {
    my $res = get_user(etc_dir=>"$Bin/data/simple", user=>"foo");
    is($res->[0], 404, "status");
};

subtest "mention user AND uid -> error" => sub {
    my $res = get_user(etc_dir=>"$Bin/data/simple", user=>"bin", uid=>1);
    is($res->[0], 400, "status");
};

DONE_TESTING:
done_testing();
if (Test::More->builder->is_passing) {
    note "all tests successful, deleting tmp dir";
    $CWD = "/";
} else {
    diag "there are failing tests, not deleting tmp dir $tmpdir";
}
