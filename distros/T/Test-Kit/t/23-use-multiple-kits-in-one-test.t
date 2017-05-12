use strict;
use warnings;
use lib 't/lib';

use MyTest::OK;
use MyTest::Like;
use MyTest::Done;

ok(1, "ok() exists");

like('abc', qr/^[abc]+$/, "like() exists");

done();
