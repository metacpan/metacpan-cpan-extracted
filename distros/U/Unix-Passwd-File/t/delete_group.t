#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';

use File::chdir;
use File::Copy::Recursive qw(rcopy);
use File::Path qw(remove_tree);
use File::Temp qw(tempdir);
use Unix::Passwd::File qw(delete_group get_group);
use Test::More 0.96;

my $tmpdir = tempdir(CLEANUP=>1);
$CWD = $tmpdir;
note "tmpdir=$tmpdir";

subtest "delete" => sub {
    remove_tree "$tmpdir/simple";
    rcopy("$Bin/data/simple-after-add_user-foo", "$tmpdir/simple");
    my $res = delete_group(etc_dir=>"$tmpdir/simple", group=>"foo");
    is($res->[0], 200, "status");

    $res = Unix::Passwd::File::list_groups(etc_dir=>"$tmpdir/simple");
    $res = get_group(etc_dir=>"$tmpdir/simple", group=>"foo");
    is($res->[0], 404, "status");
};

subtest "already delete, noop" => sub {
    remove_tree "$tmpdir/simple";
    rcopy("$Bin/data/simple-after-add_user-foo", "$tmpdir/simple");
    my $res = delete_group(etc_dir=>"$tmpdir/simple", group=>"foo");
    is($res->[0], 200, "status");
};

DONE_TESTING:
done_testing();
if (Test::More->builder->is_passing) {
    note "all tests successful, deleting tmp dir";
    $CWD = "/";
} else {
    diag "there are failing tests, not deleting tmp dir $tmpdir";
}
