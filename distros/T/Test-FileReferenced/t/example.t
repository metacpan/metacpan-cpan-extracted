#!/usr/bin/perl

use strict; use warnings;

use FindBin qw( $Bin );
use Test::More tests => 6;
use Test::FileReferenced;

# This is a example/reference test.
# It's role is actually NOT to test the Test::FileReferenced module,
# but to show how it can be used used.

# Example 1:
#   Using default reference file, in this case: 'example.yaml'

is_referenced_ok(
    'Foo',
    'Scalars can be referenced in files',
);
is_referenced_ok(
    [
        "Foo",
        "Bar",
        "Baz",
    ],
    'Arrays can be referenced in files',
);
is_referenced_ok(
    {
        foo => 'Foo',
        bar => 'Bar',
        baz => 'Baz',
    },
    'Hashes can be referenced in files',
);
is_referenced_ok(
    undef,
    'Undef can be referenced in files',
);

# Example 2:
#   Using custom reference files.
#   Note, that You have to provide filename WITHOUT file extension.
#   Extension will be appended automatically, depending on what serializer You have chousen.
#
#   File paths are relative to the test location, unless they start with '/'.

is_referenced_in_file(
    [
        'Foo',
        'Bar',
        'Baz',
    ],
    'example-array',
    'Array in custom reference file',
);
is_referenced_in_file(
    {
        foo => 'Foo',
        bar => 'Bar',
        baz => 'Baz',
    },
    $Bin . '/example-hash', # <-- absolute paths work too :)
    'Hash in custom reference file',
);

# vim: fdm=marker
