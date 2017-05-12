#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';

use File::chdir;
use File::Copy::Recursive qw(rcopy);
use File::Path qw(remove_tree);
use File::Temp qw(tempdir);
use Unix::Passwd::File qw(add_delete_user_groups get_user_groups);
use Test::More 0.96;

my $tmpdir = tempdir(CLEANUP=>1);
$CWD = $tmpdir;
note "tmpdir=$tmpdir";

subtest "success" => sub {
    remove_tree "$tmpdir/simple"; rcopy("$Bin/data/simple", "$tmpdir/simple");
    my $res = add_delete_user_groups(
        etc_dir=>"$tmpdir/simple",
        user=>"u1", add_to=>[qw/bin daemon/], delete_from=>[qw/u2/],
    );
    is($res->[0], 200, "status");
    $res = get_user_groups(etc_dir=>"$tmpdir/simple", user=>"u1");
    is($res->[0], 200, "status");
    is_deeply($res->[2], ["bin", "daemon", "u1"], "groups")
        or diag explain $res;
};

subtest "unknown group currently ok" => sub {
    remove_tree "$tmpdir/simple"; rcopy("$Bin/data/simple", "$tmpdir/simple");
    my $res = add_delete_user_groups(
        etc_dir=>"$tmpdir/simple",
        user=>"u1", add_to=>[qw/foo bar/], delete_from=>[qw/baz qux/],
    );
    is($res->[0], 200, "status");
    $res = get_user_groups(etc_dir=>"$tmpdir/simple", user=>"u1");
    is($res->[0], 200, "status");
    is_deeply($res->[2], ["u1", "u2"], "groups")
        or diag explain $res;
};

# XXX test unknown user

DONE_TESTING:
done_testing();
if (Test::More->builder->is_passing) {
    note "all tests successful, deleting tmp dir";
    $CWD = "/";
} else {
    diag "there are failing tests, not deleting tmp dir $tmpdir";
}
