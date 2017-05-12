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
# Tests.
subtest 'Omit module name.' => sub {
    my $mock = create_mock();
    ok(!$mock->isa('Foo::Bar::Baz'));
};

subtest 'Specify module name.' => sub {
    my $mock = create_mock('Foo::Bar::Baz');
    ok($mock->isa('Foo::Bar::Baz'));
    ok(!$mock->isa('Unknown'));

    reset($mock);

    ok($mock->isa('Foo::Bar::Baz'));
};

# ----
done_testing;
