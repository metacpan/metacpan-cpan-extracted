use strict;
use warnings;

use Test::Builder::Tester tests => 13;
use Test::More;

# Test using the module.
use_ok 'Test::Numeric';

my @is_money   = qw( .12 1.12 12345678.12 );
my @isnt_money = qw( . 12.1 12.123 );

# Test is money.
foreach my $val ( @is_money ) {
    test_out('ok 1 - foo');
    is_money( $val, 'foo' );
    test_test("is_money");
}

foreach my $val ( @isnt_money ) {
    test_out('not ok 1 - foo');
    test_fail(+1);
    is_money( $val, 'foo' );
    test_test("is_money");
}

# Test isnt money.
foreach my $val ( @isnt_money ) {
    test_out('ok 1 - foo');
    isnt_money( $val, 'foo' );
    test_test("isnt_money");
}

foreach my $val ( @is_money ) {
    test_out('not ok 1 - foo');
    test_fail(+1);
    isnt_money( $val, 'foo' );
    test_test("isnt_money");
}

