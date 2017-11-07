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
use Unix::Passwd::File qw(add_user_to_group get_group);

my $tmpdir = tempdir(CLEANUP=>1);
$CWD = $tmpdir;
note "tmpdir=$tmpdir";

subtest "missing required fields 1" => sub {
    remove_tree "$tmpdir/simple"; rcopy("$Bin/data/simple", "$tmpdir/simple");
    my $res = add_user_to_group(etc_dir=>"$tmpdir/simple");
    is($res->[0], 400, "status");
};
subtest "missing required fields 2" => sub {
    remove_tree "$tmpdir/simple"; rcopy("$Bin/data/simple", "$tmpdir/simple");
    my $res = add_user_to_group(etc_dir=>"$tmpdir/simple",
                                user=>"x",
                            );
    is($res->[0], 400, "status");
};
subtest "missing required fields 3" => sub {
    remove_tree "$tmpdir/simple"; rcopy("$Bin/data/simple", "$tmpdir/simple");
    my $res = add_user_to_group(etc_dir=>"$tmpdir/simple",
                                group=>"x",
                            );
    is($res->[0], 400, "status");
};

subtest "unknown group" => sub {
    remove_tree "$tmpdir/simple"; rcopy("$Bin/data/simple", "$tmpdir/simple");
    my $res = add_user_to_group(etc_dir=>"$tmpdir/simple",
                                user=>"u1", group=>"foo",
                            );
    is($res->[0], 404, "status");
};

subtest "success" => sub {
    remove_tree "$tmpdir/simple"; rcopy("$Bin/data/simple", "$tmpdir/simple");
    my $res = add_user_to_group(etc_dir=>"$tmpdir/simple",
                                user=>"bin", group=>"u1",
                            );
    is($res->[0], 200, "status");
    $res = get_group(etc_dir=>"$tmpdir/simple", group=>"u1");
    is($res->[0], 200, "status");
    is($res->[2]{members}, "u1,bin", "res");
};

subtest "readd = noop" => sub {
    remove_tree "$tmpdir/simple"; rcopy("$Bin/data/simple", "$tmpdir/simple");
    my $res = add_user_to_group(etc_dir=>"$tmpdir/simple",
                                user=>"bin", group=>"u1",
                            );
    is($res->[0], 200, "status");
    $res = get_group(etc_dir=>"$tmpdir/simple", group=>"u1");
    is($res->[0], 200, "status");
    is($res->[2]{members}, "u1,bin", "res");
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
