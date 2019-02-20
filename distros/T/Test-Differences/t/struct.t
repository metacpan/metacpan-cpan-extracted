#!perl

use strict;
use warnings;

use lib 't/lib';
use Test::Differences::TestUtils::Capture;

use Test::More;
use Test::Differences;

## This mind-bender submitted by Yves Orton <demerphq@hotmail.com>
my ( $ar, $x, $y );
$ar->[0] = \$ar->[1];
$ar->[1] = \$ar->[0];
$x       = \$y;
$y       = \$x;

my @tests = (
    sub { eq_or_diff [ \"a", \"b" ], [ \"a", \"b" ] },
    sub { eq_or_diff $ar, [ $x, $y ] },
);

plan tests => 1 + scalar @tests;

$_->() for @tests;

# submitted by bessarabov, https://github.com/Ovid/Test-Differences/issues/2
my $stderr = capture_error { system (
    $^X, (map { "-I$_" } (@INC)),
    qw(-Mstrict -Mwarnings -MTest::More -MTest::Differences),
    '-e', '
        END { done_testing(); }
        eq_or_diff([[1]], [1])
    '
) };

is(
    $stderr,
'#   Failed test at -e line 3.
# +----+-------+----+----------+
# | Elt|Got    | Elt|Expected  |
# +----+-------+----+----------+
# |   0|[      |   0|[         |
# *   1|  [    *   1|  1       *
# *   2|    1  *    |          |
# *   3|  ]    *    |          |
# |   4|]      |   2|]         |
# +----+-------+----+----------+
# Looks like you failed 1 test of 1.
',
    "got expected error output"
);
