use strict;
use warnings;
use lib 't/lib';

# Include List - test that 'include "Mod1", "Mod2", "Mod3"' works as expected.

use MyTest::IncludeList;

ok(1, "ok() exists");

pass("pass() exists");

lives_ok(
    sub {
        warning_like(
            sub { warn("foo") },
            qr/foo/,
            "warning_like() exists"
        )
    },
    'lives_ok() exists'
);

done_testing();
