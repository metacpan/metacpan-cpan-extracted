use Test2::Tools::xUnit;
use Test2::V0;

use Attribute::Handlers;

sub SomeAttr : ATTR(CODE) {
    $::called = 1;
    return;
}

sub UNIVERSAL::AnotherAttr : ATTR(CODE) {
    $::universal_called = 1;
    return;
}

sub example : SomeAttr AnotherAttr {
    return;
}

sub test : Test {
    ok $::called;
    ok $::universal_called;
}

done_testing;
