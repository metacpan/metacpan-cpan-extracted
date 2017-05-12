use strict;
use warnings;

use t::Util qw(expect_fail expect_pass);
use Test::More;
BEGIN {
    use_ok('Test::EasyMock',
           qw{
               create_mock
               expect
               replay
               reset
               verify
           });
}

# ----
# Tests.
subtest 'default mock' => sub {
    my $mock = create_mock();

    expect_fail {
        replay($mock);
        $mock->foo();
    } 'nothing is expected.';

    reset($mock);

    expect_fail {
        expect($mock->foo());
        replay($mock);
        $mock->bar();
    } 'expect `foo` method, but `bar` method.';

    reset($mock);
    expect_fail {
        expect($mock->foo());
        replay($mock);
        $mock->foo(1);
    } 'expect empty argument, but an argument exists.';

    reset($mock);
    subtest 'more than the expected times.' => sub {
        expect($mock->foo());
        replay($mock);
        expect_pass { $mock->foo() };
        expect_fail { $mock->foo() };
    };

    reset($mock);
    expect_fail {
        expect($mock->foo());
        replay($mock);
        verify($mock);          # fail
    } 'less than the expected times.';
};

# ----
done_testing;
