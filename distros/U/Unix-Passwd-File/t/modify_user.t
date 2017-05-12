#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';

use File::chdir;
use File::Copy::Recursive qw(rcopy);
use File::Path qw(remove_tree);
use File::Temp qw(tempdir);
use Unix::Passwd::File qw(modify_user get_user);
use Test::More 0.96;

my $tmpdir = tempdir(CLEANUP=>1);
$CWD = $tmpdir;
note "tmpdir=$tmpdir";

subtest "missing required fields" => sub {
    remove_tree "$tmpdir/simple"; rcopy("$Bin/data/simple", "$tmpdir/simple");
    my $res = modify_user(etc_dir=>"$tmpdir/simple");
    is($res->[0], 400, "status");
};

subtest "unknown user" => sub {
    remove_tree "$tmpdir/simple"; rcopy("$Bin/data/simple", "$tmpdir/simple");
    my $res = modify_user(etc_dir=>"$tmpdir/simple", user=>"foo");
    is($res->[0], 404, "status");
};
for my $f (qw/encpass uid gid gecos home shell
             encpass last_pwchange min_pass_age max_pass_age
             pass_warn_period pass_inactive_period expire_date/) {
    subtest "invalid field: $f" => sub {
        remove_tree "$tmpdir/simple";
        rcopy("$Bin/data/simple", "$tmpdir/simple");
        my $res = modify_user(etc_dir=>"$tmpdir/simple",
                               user=>"u2", $f=>":");
        is($res->[0], 400, "status");
    };
}

subtest "success (modify no fields)" => sub {
    remove_tree "$tmpdir/simple"; rcopy("$Bin/data/simple", "$tmpdir/simple");
    my $res = modify_user(etc_dir=>"$tmpdir/simple",
                           user=>"u1",
                       );
    is($res->[0], 200, "status");

    $res = get_user(etc_dir=>"$tmpdir/simple", user=>"u1");
    is($res->[0], 200, "status");
    is_deeply($res->[2], {
        'encpass'              => '*',
        'expire_date'          => '',
        'gecos'                => '',
        'gid'                  => '1000',
        'home'                 => '/home/u1',
        'last_pwchange'        => '14607',
        'max_pass_age'         => '99999',
        'min_pass_age'         => '0',
        'pass'                 => 'x',
        'pass_inactive_period' => '',
        'pass_warn_period'     => '7',
        'reserved'             => '',
        'shell'                => '/bin/bash',
        'uid'                  => '1000',
        'user'                 => 'u1'
    }, "res") or diag explain $res;
};

subtest "success (modify all fields)" => sub {
    remove_tree "$tmpdir/simple"; rcopy("$Bin/data/simple", "$tmpdir/simple");
    my $res = modify_user(
        etc_dir=>"$tmpdir/simple",
        'encpass'              => 'foo',
        'expire_date'          => 1,
        'gecos'                => 'gecos',
        'gid'                  => '2001',
        'home'                 => '/newhome/u1',
        'last_pwchange'        => 16000,
        'max_pass_age'         => 20000,
        'min_pass_age'         => 2,
        'pass_inactive_period' => 3,
        'pass_warn_period'     => 4,
        'shell'                => '/bin/zsh',
        'uid'                  => '2000',
        'user'                 => 'u1'
    );
    is($res->[0], 200, "status");

    $res = get_user(etc_dir=>"$tmpdir/simple", user=>"u1");
    is($res->[0], 200, "status");
    is_deeply($res->[2], {
        'encpass'              => 'foo',
        'expire_date'          => 1,
        'gecos'                => 'gecos',
        'gid'                  => '2001',
        'home'                 => '/newhome/u1',
        'last_pwchange'        => 16000,
        'max_pass_age'         => 20000,
        'min_pass_age'         => 2,
        'pass'                 => 'x',
        'pass_inactive_period' => 3,
        'pass_warn_period'     => 4,
        'reserved'             => '',
        'shell'                => '/bin/zsh',
        'uid'                  => '2000',
        'user'                 => 'u1'
    }, "res") or diag explain $res;

};

# XXX: test set pass

DONE_TESTING:
done_testing();
if (Test::More->builder->is_passing) {
    note "all tests successful, deleting tmp dir";
    $CWD = "/";
} else {
    diag "there are failing tests, not deleting tmp dir $tmpdir";
}
