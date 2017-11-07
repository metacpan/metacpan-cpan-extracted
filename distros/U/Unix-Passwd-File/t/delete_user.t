#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';
use Test::More 0.98;

BEGIN { plan skip_all => "OS unsupported" if $^O eq 'MSWin32' }

use File::chdir;
use File::Copy::Recursive qw(rcopy);
use File::Path qw(remove_tree);
use File::Slurper qw(read_text);
use File::Temp qw(tempdir);
use Unix::Passwd::File qw(delete_user get_user get_group);

my $tmpdir = tempdir(CLEANUP=>1);
$CWD = $tmpdir;
note "tmpdir=$tmpdir";

subtest "delete" => sub {
    remove_tree "$tmpdir/simple";
    rcopy("$Bin/data/simple-after-add_user-foo", "$tmpdir/simple");
    my $res = delete_user(etc_dir=>"$tmpdir/simple", user=>"foo");
    is($res->[0], 200, "status");

    $res = get_user(etc_dir=>"$tmpdir/simple", user=>"foo");
    is($res->[0], 404, "status");

    # check that other entries, whitespace, etc are not being mangled.
    for (qw/passwd shadow group gshadow/) {
        is(scalar(read_text "$tmpdir/simple/$_"),
           scalar(read_text "$Bin/data/simple/$_"),
           "compare file $_");
    }
};

subtest "delete also removes user in any group" => sub {
    remove_tree "$tmpdir/simple";
    rcopy("$Bin/data/simple", "$tmpdir/simple");
    my $res = delete_user(etc_dir=>"$tmpdir/simple", user=>"u1");
    is($res->[0], 200, "status");

    $res = get_user(etc_dir=>"$tmpdir/simple", user=>"u1");
    is($res->[0], 404, "status");

    # check that other entries, whitespace, etc are not being mangled.
    for (qw/passwd shadow group gshadow/) {
        is(scalar(read_text "$tmpdir/simple/$_"),
           scalar(read_text "$Bin/data/simple-after-delete_user-u1/$_"),
           "compare file $_");
    }
};

subtest "already deleted, noop" => sub {
    remove_tree "$tmpdir/simple";
    rcopy("$Bin/data/simple-after-add_user-foo", "$tmpdir/simple");
    my $res = delete_user(etc_dir=>"$tmpdir/simple", user=>"foo");
    is($res->[0], 200, "status");

    # XXX test: backup is not written if file is not modified
};

DONE_TESTING:
done_testing();
if (Test::More->builder->is_passing) {
    note "all tests successful, deleting tmp dir";
    $CWD = "/";
} else {
    diag "there are failing tests, not deleting tmp dir $tmpdir";
}
