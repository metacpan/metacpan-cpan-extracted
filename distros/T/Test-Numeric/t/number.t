use strict;
use warnings;

use Test::Builder::Tester tests => 32;
use Test::More;

# Test using the module.
use_ok 'Test::Numeric';

ok( Test::Numeric::_test_number($_), "'$_' is a number" ) for qw(
  0
  1
  .1
  -1
  +34
  1.23
  1.2e3
  1.2e+3
  1.2e-3
  1.3e123
  1.2E3
  1.2E+3
  1.2E-3
  1.3E123
  -.2
);

ok( !Test::Numeric::_test_number($_), "'$_' is not a number" ) for qw(
  1.-2
  test
  --12
  1e2e3
  -23-
  +-2
  1.2.3
  .
  .e2
  .E2
  12eE3
  ), '';

test_out('ok 1 - foo');
is_number( 1.2e3, 'foo' );
test_test("is_number");

test_out('not ok 1 - foo');
test_fail(+1);
is_number( 'test', 'foo' );
test_test("is_number");

test_out('ok 1 - foo');
isnt_number( 'test', 'foo' );
test_test("isnt_number");

test_out('not ok 1 - foo');
test_fail(+1);
isnt_number( 2, 'foo' );
test_test("isnt_number");
