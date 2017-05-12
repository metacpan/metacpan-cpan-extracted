use strict;
use warnings;

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
# Helper.
{
    package Foo;
    sub new { bless {}, shift }
    sub foo { 'original-foo' }
}

# ----
# Tests.
subtest 'Specify object.' => sub {
    my $mock = create_mock(Foo->new());

    subtest 'mock no methods.' => sub {
        replay($mock);

        ok($mock->isa('Foo'));
        is($mock->foo, 'original-foo');
        verify($mock);
    };

    reset($mock);

    subtest 'mock methods.' => sub {
        expect($mock->foo)->and_scalar_return('mocked-foo');
        expect($mock->bar)->and_scalar_return('mocked-bar');
        replay($mock);

        ok($mock->isa('Foo'));
        is($mock->foo, 'mocked-foo');
        is($mock->bar, 'mocked-bar');
        verify($mock);
    };
};

# ----
done_testing;
