#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';
use Test::More 0.98;

BEGIN { plan skip_all => "OS unsupported" if $^O eq 'MSWin32' }

use Unix::Passwd::File qw(user_exists);

ok( user_exists(etc_dir=>"$Bin/data/simple", user=>"bin"));
ok(!user_exists(etc_dir=>"$Bin/data/simple", user=>"foo"));

DONE_TESTING:
done_testing();
