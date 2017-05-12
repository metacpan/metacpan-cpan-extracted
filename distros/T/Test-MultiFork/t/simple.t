#!perl -I.

use Test::MultiFork;
use Test::Simple;
use Time::HiRes qw(sleep);

FORK_a5:

import Test::Simple tests => 3;

sleep(0.1);
ok(1, "one$$");
ok(2, "two$$");
sleep(0.1);
ok(3, "three$$");
#sleep(0.1);


