package Foo;

sub MODIFY_CODE_ATTRIBUTES {
    $::called = 1;
    return;
}

package Bar;

use Test2::Tools::xUnit;
use Test2::V0;

use parent -norequire, 'Foo';

sub test : Test {
    ok $::called;
}

done_testing;
