#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';

use Crypt::Password::Util qw(looks_like_crypt);
use File::chdir;
use File::Copy::Recursive qw(rcopy);
use File::Path qw(remove_tree);
use File::Temp qw(tempdir);
use Unix::Passwd::File qw(set_user_password get_user);
use Test::More 0.96;

my $tmpdir = tempdir(CLEANUP=>1);
$CWD = $tmpdir;
note "tmpdir=$tmpdir";

subtest "missing required fields" => sub {
    remove_tree "$tmpdir/simple"; rcopy("$Bin/data/simple", "$tmpdir/simple");
    my $res = set_user_password(etc_dir=>"$tmpdir/simple", user=>"u1");
    is($res->[0], 400, "status");
};

subtest "unknown user" => sub {
    remove_tree "$tmpdir/simple"; rcopy("$Bin/data/simple", "$tmpdir/simple");
    my $res = set_user_password(etc_dir=>"$tmpdir/simple",
                                user=>"foo", pass=>"x");
    is($res->[0], 404, "status") or diag explain $res;
};

subtest "success" => sub {
    remove_tree "$tmpdir/simple"; rcopy("$Bin/data/simple", "$tmpdir/simple");
    my $res = set_user_password(etc_dir=>"$tmpdir/simple",
                                user=>"u1", pass=>"foo",
                       );
    is($res->[0], 200, "status");

    $res = get_user(etc_dir=>"$tmpdir/simple", user=>"u1");
    is($res->[0], 200, "status");
    ok(looks_like_crypt($res->[2]{encpass}), "encpass")
        or diag "encpass=$res->[2]{encpass}";
};

DONE_TESTING:
done_testing();
if (Test::More->builder->is_passing) {
    note "all tests successful, deleting tmp dir";
    $CWD = "/";
} else {
    diag "there are failing tests, not deleting tmp dir $tmpdir";
}
