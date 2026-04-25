use strict;
use warnings;

use Test::Builder::Tester tests => 2;
use Test::IsAny qw(is_any);

test_out('ok 1 - ');
is_any( 42, [ 1, 2, 42 ] );
test_test('is_any success');

test_out('not ok 1 - ');
my $expected_error = q{#   Failed test ''
#   at t/00-test.t line 19.
# Received: 42
# Expected:
#          1
#          2};
test_err($expected_error);
is_any( 42, [ 1, 2 ] );
test_test('is_any failure');

