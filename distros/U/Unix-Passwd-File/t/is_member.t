#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';

use Test::More 0.96;
use Unix::Passwd::File qw(is_member);

ok(!is_member(etc_dir=>"$Bin/data/simple",
              user=>"x"), "missing arg 1");
ok(!is_member(etc_dir=>"$Bin/data/simple",
              group=>"x"), "missing arg 2");
ok(!is_member(etc_dir=>"$Bin/data/simple",
              user=>"x", group=>"u1"), "user unknown");
ok(!is_member(etc_dir=>"$Bin/data/simple",
              user=>"u1", group=>"x"), "group unknown");
ok( is_member(etc_dir=>"$Bin/data/simple",
              user=>"u1", group=>"u1"), "found 1");
ok( is_member(etc_dir=>"$Bin/data/simple",
              user=>"u1", group=>"u2"), "found 2");

DONE_TESTING:
done_testing();
