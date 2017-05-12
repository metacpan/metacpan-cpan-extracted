use strict;
use warnings;
use lib 't/lib';

use Test::More;

# Sub Name Collide - test that Test::Kit dies on sub name collisions

eval "use MyTest::SubNameCollide;";
like(
    $@,
    qr/\QSubroutine ok() already supplied to MyTest::SubNameCollide by Test::More\E/,
    'sub name collision throws an exception'
);

eval "use MyTest::SubNameCollideFixed; ok(1, 'ok() from Test::More'); test_simple_ok(1, 'test_simple_ok() from Test::Simple');";
like(
    $@,
    qr//,
    'sub name collision can be fixed by use of the rename feature'
);

done_testing();
