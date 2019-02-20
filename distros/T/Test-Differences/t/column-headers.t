#!perl

use strict;
use warnings;

use lib 't/lib';
use Test::Differences::TestUtils::Capture;

use Test::More;

END { done_testing(); }

my $stderr = capture_error { system (
    $^X, (map { "-I$_" } (@INC)),
    't/script/default-headers'
) };
is(
    $stderr,
"#   Failed test 'both the same'
#   at t/script/default-headers line 8.
# +----+----------------+----------------+
# | Elt|Got             |Expected        |
# +----+----------------+----------------+
# |   0|{               |{               |
# *   1|  foo => 'bar'  |  foo => 'baz'  *
# |   2|}               |}               |
# +----+----------------+----------------+
# Looks like you failed 1 test of 1.
",
    "got expected error output"
);

$stderr = capture_error { system (
    $^X, (map { "-I$_" } (@INC)),
    't/script/custom-headers'
) };
is(
    $stderr,
"#   Failed test 'both the same'
#   at t/script/custom-headers line 8.
# +----+----------------+----------------+
# | Elt|Lard            |Chips           |
# +----+----------------+----------------+
# |   0|{               |{               |
# *   1|  foo => 'bar'  |  foo => 'baz'  *
# |   2|}               |}               |
# +----+----------------+----------------+
# Looks like you failed 1 test of 1.
",
    "got expected error output"
);
