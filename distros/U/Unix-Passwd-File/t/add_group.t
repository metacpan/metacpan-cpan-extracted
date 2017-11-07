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
use File::Temp qw(tempdir);
use Unix::Passwd::File qw(add_group get_group);

my $tmpdir = tempdir(CLEANUP=>1);
$CWD = $tmpdir;
note "tmpdir=$tmpdir";

# can't do this, lock by the same process
#
#subtest "failure to lock" => sub {
#    remove_tree "$tmpdir/simple"; rcopy("$Bin/data/simple", "$tmpdir/simple");
#    lock("$tmpdir/simple/passwd.lock");
#    my $res = add_group(etc_dir=>"$tmpdir/simple",
#                       group=>"foo", members=>"a,b",
#                   );
#    is($res->[0], 412, "status");
#    unlock("$tmpdir/simple/passwd.lock");
#};

subtest "missing required fields" => sub {
    remove_tree "$tmpdir/simple"; rcopy("$Bin/data/simple", "$tmpdir/simple");
    my $res = add_group(etc_dir=>"$tmpdir/simple");
    is($res->[0], 400, "status");
};

subtest "invalid field: group" => sub {
    remove_tree "$tmpdir/simple"; rcopy("$Bin/data/simple", "$tmpdir/simple");
    my $res = add_group(etc_dir=>"$tmpdir/simple",
                        group=>"foo ");
    is($res->[0], 400, "status");
};
subtest "invalid field: members" => sub {
    remove_tree "$tmpdir/simple"; rcopy("$Bin/data/simple", "$tmpdir/simple");
    my $res = add_group(etc_dir=>"$tmpdir/simple",
                        group=>"foo", members=>":");
    is($res->[0], 400, "status");
};

subtest "group already exists -> fail" => sub {
    remove_tree "$tmpdir/simple"; rcopy("$Bin/data/simple", "$tmpdir/simple");
    my $res = add_group(etc_dir=>"$tmpdir/simple",
                       group=>"bin");
    is($res->[0], 412, "status");
};

subtest "success" => sub {
    remove_tree "$tmpdir/simple"; rcopy("$Bin/data/simple", "$tmpdir/simple");
    my $res = add_group(etc_dir=>"$tmpdir/simple",
                       group=>"foo", members=>"a,b",
                   );
    is($res->[0], 200, "status");
    is_deeply($res->[2], {gid=>1002}, "res");

    $res = get_group(etc_dir=>"$tmpdir/simple", group=>"foo");
    is($res->[0], 200, "status");
    is_deeply($res->[2], {
        'admins' => '',
        'encpass' => '*',
        'gid' => '1002',
        'group' => 'foo',
        'members' => 'a,b',
        'pass' => 'x'
    }, "res") or diag explain $res;
};

subtest "pick gid" => sub {
    remove_tree "$tmpdir/simple"; rcopy("$Bin/data/simple", "$tmpdir/simple");
    my $res = add_group(etc_dir=>"$tmpdir/simple",
                       group=>"foo", gid=>1003,
                   );
    is($res->[0], 200, "status");
    is_deeply($res->[2], {gid=>1003}, "res");
};
subtest "pick gid (unavailable) -> success" => sub {
    remove_tree "$tmpdir/simple"; rcopy("$Bin/data/simple", "$tmpdir/simple");
    my $res = add_group(etc_dir=>"$tmpdir/simple",
                       group=>"foo", gid=>1001,
                   );
    is($res->[0], 200, "status");
};
subtest "pick min_gid..max_gid" => sub {
    remove_tree "$tmpdir/simple"; rcopy("$Bin/data/simple", "$tmpdir/simple");
    my $res = add_group(etc_dir=>"$tmpdir/simple",
                       group=>"foo", min_gid=>1001, max_gid=>1003,
                   );
    is($res->[0], 200, "status");
    is_deeply($res->[2], {gid=>1002}, "res") or diag explain $res;
};
subtest "pick min_gid..max_gid (unavailable)" => sub {
    remove_tree "$tmpdir/simple"; rcopy("$Bin/data/simple", "$tmpdir/simple");
    my $res = add_group(etc_dir=>"$tmpdir/simple",
                       group=>"foo", min_gid=>1000, max_gid=>1001,
                   );
    is($res->[0], 412, "status");
};

DONE_TESTING:
done_testing();
if (Test::More->builder->is_passing) {
    note "all tests successful, deleting tmp dir";
    $CWD = "/";
} else {
    diag "there are failing tests, not deleting tmp dir $tmpdir";
}
