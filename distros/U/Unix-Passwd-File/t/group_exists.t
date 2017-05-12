#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';

use Test::More 0.96;
use Unix::Passwd::File qw(group_exists);

ok( group_exists(etc_dir=>"$Bin/data/simple", group=>"bin"));
ok(!group_exists(etc_dir=>"$Bin/data/simple", group=>"foo"));

DONE_TESTING:
done_testing();
