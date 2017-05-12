#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';

use File::chdir;
use File::Copy::Recursive qw(rcopy);
use File::Temp qw(tempdir);
use Test::More 0.96;
use Unix::Passwd::File qw(get_group);

my $tmpdir = tempdir(CLEANUP=>1);
$CWD = $tmpdir;
note "tmpdir=$tmpdir";

rcopy("$Bin/data/simple", "$tmpdir/simple");
unlink "$tmpdir/simple/gshadow";

subtest "gshadow unreadable -> ok" => sub {
    my $res = get_group(etc_dir=>"$tmpdir/simple", group=>"root");
    is_deeply($res->[0], 200, "status");
};

subtest "etc_dir unknown -> error" => sub {
    my $res = get_group(etc_dir=>"$Bin/data/foo", group=>"bin");
    is($res->[0], 500, "status");
};

subtest "by uid, found" => sub {
    my $res = get_group(etc_dir=>"$Bin/data/simple", gid=>2);
    is($res->[0], 200, "status");
    is($res->[2]{group}, "daemon", "res");
};

subtest "by uid, not found" => sub {
    my $res = get_group(etc_dir=>"$Bin/data/simple", gid=>99);
    is($res->[0], 404, "status");
};

subtest "by group, found" => sub {
    my $res = get_group(etc_dir=>"$Bin/data/simple", group=>"bin");
    is($res->[0], 200, "status");
    is($res->[2]{gid}, 1, "res");
};

subtest "by group, not found" => sub {
    my $res = get_group(etc_dir=>"$Bin/data/simple", group=>"foo");
    is($res->[0], 404, "status");
};

subtest "mention group AND gid -> error" => sub {
    my $res = get_group(etc_dir=>"$Bin/data/simple", group=>"bin", gid=>1);
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
