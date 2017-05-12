#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';

use Test::More 0.96;
use Unix::Passwd::File qw(get_user_groups);

subtest "user not found" => sub {
    my $res = get_user_groups(etc_dir=>"$Bin/data/simple", user=>"foo");
    is($res->[0], 404, "status");
};

subtest "found" => sub {
    my $res = get_user_groups(etc_dir=>"$Bin/data/simple", user=>"u1");
    is($res->[0], 200, "status");
    is_deeply($res->[2], ["u1","u2"], "res");
};

# XXX: test detail=>1

DONE_TESTING:
done_testing();
