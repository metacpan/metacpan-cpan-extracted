#!perl -I.

use Test::MultiFork;
use Test::Simple;

FORK_a5:

import Test::Simple tests => 3;

ok(1, "one");
ok(2, "one");
ok(3, "one");


