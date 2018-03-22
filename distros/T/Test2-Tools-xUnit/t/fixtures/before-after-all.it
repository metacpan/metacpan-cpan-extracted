package Foo;

use Test2::Tools::xUnit;
use Test2::V0;

sub before_all : BeforeAll {
    my $class = shift;
    is $class, 'Foo', "BeforeAll should be called as class method";
}

sub dummy_test_one : Test {
    ok(1);
}

sub dummy_test_two : Test {
    ok(1);
}

sub after_all : AfterAll {
    my $class = shift;
    is $class, 'Foo', "AfterAll should be called as class method";
}

done_testing;
