#!/usr/bin/perl

use strict; use warnings;

use Test::More tests => 1;
use Test::Exception;
use Test::FileReferenced;

# Check if Test::FileReferenced::is_referenced_ok check for it's (mandatory) test name.

$ENV{'FILE_REFERENCED_NO_PROMPT'} = 1;

throws_ok {
    is_referenced_ok(
        {
            a => 'A',
            b => 'B',
        },
        "De-serializer crash test"
    );
} qr{De-serializer error}s, "De-serialization errors are intercepted";

# vim: fdm=marker
