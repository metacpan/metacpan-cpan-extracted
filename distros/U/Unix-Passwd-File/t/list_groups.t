#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';

use File::chdir;
use File::Copy::Recursive qw(rcopy);
use File::Temp qw(tempdir);
use Test::More 0.96;
use Unix::Passwd::File qw(list_groups);

my $tmpdir = tempdir(CLEANUP=>1);
$CWD = $tmpdir;
note "tmpdir=$tmpdir";

rcopy("$Bin/data/simple", "$tmpdir/simple");
unlink "$tmpdir/simple/gshadow";

subtest "gshadow unreadable -> ok" => sub {
    my $res = list_groups(etc_dir=>"$tmpdir/simple");
    is_deeply($res->[2], [qw/root bin daemon nobody u1 u2/]);
};

subtest "default" => sub {
    my $res = list_groups(etc_dir=>"$Bin/data/simple");
    is_deeply($res->[2], [qw/root bin daemon nobody u1 u2/]);
};

subtest "detail=1" => sub {
    my $res = list_groups(etc_dir=>"$Bin/data/simple", detail=>1);
    is_deeply($res->[2][0], {
        admins => "",
        gid => 0,
        group => "root",
        members => "",
        pass => "x",

        encpass => "",
    }) or diag explain $res;
};

subtest "detail=1, with_field_names=>0" => sub {
    my $res = list_groups(etc_dir=>"$Bin/data/simple",
                         detail=>1, with_field_names=>0);
    is_deeply($res->[2][0], ["root", "x", 0, ""]);
};

DONE_TESTING:
done_testing();
if (Test::More->builder->is_passing) {
    note "all tests successful, deleting tmp dir";
    $CWD = "/";
} else {
    diag "there are failing tests, not deleting tmp dir $tmpdir";
}
