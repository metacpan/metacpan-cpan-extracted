#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';

use File::chdir;
use File::Copy::Recursive qw(rcopy);
use File::Path qw(remove_tree);
use File::Temp qw(tempdir);
use Unix::Passwd::File qw(modify_group get_group);
use Test::More 0.96;

my $tmpdir = tempdir(CLEANUP=>1);
$CWD = $tmpdir;
note "tmpdir=$tmpdir";

subtest "missing required fields" => sub {
    remove_tree "$tmpdir/simple"; rcopy("$Bin/data/simple", "$tmpdir/simple");
    my $res = modify_group(etc_dir=>"$tmpdir/simple");
    is($res->[0], 400, "status");
};

subtest "unknown group" => sub {
    remove_tree "$tmpdir/simple"; rcopy("$Bin/data/simple", "$tmpdir/simple");
    my $res = modify_group(etc_dir=>"$tmpdir/simple", group=>"foo");
    is($res->[0], 404, "status");
};
for my $f (qw/gid encpass members admins/) {
    subtest "invalid field: $f" => sub {
        remove_tree "$tmpdir/simple";
        rcopy("$Bin/data/simple", "$tmpdir/simple");
        my $res = modify_group(etc_dir=>"$tmpdir/simple",
                               group=>"u2", $f=>":");
        is($res->[0], 400, "status");
    };
}

subtest "success (modify no fields)" => sub {
    remove_tree "$tmpdir/simple"; rcopy("$Bin/data/simple", "$tmpdir/simple");
    my $res = modify_group(etc_dir=>"$tmpdir/simple",
                           group=>"u2",
                       );
    is($res->[0], 200, "status");

    $res = get_group(etc_dir=>"$tmpdir/simple", group=>"u2");
    is($res->[0], 200, "status");
    is_deeply($res->[2], {
        'admins' => '',
        'encpass' => '!',
        'gid' => '1001',
        'group' => 'u2',
        'members' => 'u2,u1',
        'pass' => 'x'
    }, "res") or diag explain $res;
};

subtest "success (modify all fields)" => sub {
    remove_tree "$tmpdir/simple"; rcopy("$Bin/data/simple", "$tmpdir/simple");
    my $res = modify_group(etc_dir=>"$tmpdir/simple",
                           group=>"u2",
                           members=>"u2", admins=>'u2', gid=>2001,
                           encpass=>'foo',
                       );
    is($res->[0], 200, "status");

    $res = get_group(etc_dir=>"$tmpdir/simple", group=>"u2");
    is($res->[0], 200, "status");
    is_deeply($res->[2], {
        'admins' => 'u2',
        'encpass' => 'foo',
        'gid' => '2001',
        'group' => 'u2',
        'members' => 'u2',
        'pass' => 'x'
    }, "res") or diag explain $res;
};

# XXX: test change pass

DONE_TESTING:
done_testing();
if (Test::More->builder->is_passing) {
    note "all tests successful, deleting tmp dir";
    $CWD = "/";
} else {
    diag "there are failing tests, not deleting tmp dir $tmpdir";
}
